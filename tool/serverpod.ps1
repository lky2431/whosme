$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$packageConfig = Join-Path $projectRoot '.tools\serverpod_cli\.dart_tool\package_config.json'
if (-not (Test-Path -LiteralPath $packageConfig)) {
    Push-Location (Join-Path $projectRoot '.tools\serverpod_cli')
    try { & dart pub get; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } }
    finally { Pop-Location }
}
$package = (Get-Content -LiteralPath $packageConfig -Raw | ConvertFrom-Json).packages |
    Where-Object name -eq 'serverpod_cli'
$entry = Join-Path ([Uri]$package.rootUri).LocalPath 'bin\serverpod_cli.dart'
Push-Location (Join-Path $projectRoot 'yourname_server')
try { & dart "--packages=$packageConfig" $entry @args; exit $LASTEXITCODE }
finally { Pop-Location }
