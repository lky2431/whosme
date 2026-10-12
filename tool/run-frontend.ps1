param(
    [ValidateSet('web-server', 'chrome')]
    [string]$Device = 'web-server',
    [int]$Port = 18083
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter is not on PATH.'
}

Write-Host 'Keep this terminal open while debugging. Press q to stop Flutter.'
Write-Host 'If the backend is not already running, start it in another terminal with .\tool\run-preview.ps1.'
Write-Host "Open http://localhost:$Port/ in Zen. Use localhost for the configured sign-in domain."
Push-Location (Join-Path $projectRoot 'yourname_flutter')
try {
    & flutter run -d $Device --web-hostname=localhost --web-port=$Port
    if ($LASTEXITCODE -ne 0) { throw "Flutter exited with code $LASTEXITCODE." }
}
finally { Pop-Location }
