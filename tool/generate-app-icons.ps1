$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path $PSScriptRoot -Parent
$appRoot = Join-Path $projectRoot 'yourname_flutter'
$masterPath = Join-Path $appRoot 'assets/branding/yourname-icon-master.png'
$source = [System.Drawing.Image]::FromFile($masterPath)
$generated = [System.Collections.Generic.List[object]]::new()

function Export-Icon([string]$RelativePath, [int]$Size, [double]$Scale = 1.0) {
    $destination = Join-Path $appRoot $RelativePath
    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#FFF8ED'))
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $edge = [int][Math]::Round($Size * $Scale)
        $offset = [int][Math]::Floor(($Size - $edge) / 2)
        $graphics.DrawImage($source, $offset, $offset, $edge, $edge)
        $bitmap.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
        $generated.Add(@{ Path = $destination; Size = $Size })
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

try {
    Export-Icon 'web/favicon.png' 32
    foreach ($size in @(192, 512)) {
        Export-Icon "web/icons/Icon-$size.png" $size
        # Additional inset keeps the complete mark inside circular masks.
        Export-Icon "web/icons/Icon-maskable-$size.png" $size 0.82
    }

    $androidSizes = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
    foreach ($density in $androidSizes.Keys) {
        Export-Icon "android/app/src/main/res/mipmap-$density/ic_launcher.png" $androidSizes[$density]
    }

    foreach ($platform in @('ios', 'macos')) {
        $catalog = "$platform/Runner/Assets.xcassets/AppIcon.appiconset"
        $contents = Get-Content (Join-Path $appRoot "$catalog/Contents.json") -Raw | ConvertFrom-Json
        foreach ($entry in ($contents.images | Sort-Object filename -Unique)) {
            $points = [double]::Parse(($entry.size -split 'x')[0], [System.Globalization.CultureInfo]::InvariantCulture)
            $scale = [int]($entry.scale -replace 'x', '')
            Export-Icon "$catalog/$($entry.filename)" ([int]($points * $scale))
        }
    }

    # ICO directory with PNG frames supports high-DPI Windows launchers.
    $frames = foreach ($size in @(16, 32, 48, 64, 128, 256)) {
        $bitmap = [System.Drawing.Bitmap]::new($size, $size)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $stream = [System.IO.MemoryStream]::new()
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.DrawImage($source, 0, 0, $size, $size)
            $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
            @{ Size = $size; Bytes = $stream.ToArray() }
        } finally {
            $stream.Dispose()
            $graphics.Dispose()
            $bitmap.Dispose()
        }
    }
    $icoPath = Join-Path $appRoot 'windows/runner/resources/app_icon.ico'
    $file = [System.IO.File]::Create($icoPath)
    $writer = [System.IO.BinaryWriter]::new($file)
    try {
        $writer.Write([uint16]0)
        $writer.Write([uint16]1)
        $writer.Write([uint16]$frames.Count)
        $offset = 6 + 16 * $frames.Count
        foreach ($frame in $frames) {
            $dimension = if ($frame.Size -eq 256) { 0 } else { $frame.Size }
            $writer.Write([byte]$dimension)
            $writer.Write([byte]$dimension)
            $writer.Write([uint16]0)
            $writer.Write([uint16]1)
            $writer.Write([uint16]32)
            $writer.Write([uint32]$frame.Bytes.Length)
            $writer.Write([uint32]$offset)
            $offset += $frame.Bytes.Length
        }
        foreach ($frame in $frames) { $writer.Write([byte[]]$frame.Bytes) }
    } finally { $writer.Dispose() }

    foreach ($item in $generated) {
        $check = [System.Drawing.Image]::FromFile($item.Path)
        try {
            if ($check.Width -ne $item.Size -or $check.Height -ne $item.Size) {
                throw "Incorrect dimensions: $($item.Path)"
            }
        } finally { $check.Dispose() }
    }
    Write-Output "Generated and dimension-checked $($generated.Count) PNG icons and a $($frames.Count)-frame Windows ICO."
} finally { $source.Dispose() }
