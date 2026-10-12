param([switch]$BuildOnly)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$flutterRoot = Join-Path $projectRoot 'yourname_flutter'
$envPath = Join-Path $flutterRoot 'lib/env.dart'
if (-not (Test-Path $envPath)) { throw 'Copy lib/env.example.dart to lib/env.dart first.' }
$originalEnv = [IO.File]::ReadAllText($envPath)
$selection = 'const environment = AppEnvironment\.(local|production);'
if (-not [regex]::IsMatch($originalEnv, $selection)) {
    throw 'Cannot identify the environment selection in lib/env.dart.'
}
$productionEnv = [regex]::Replace($originalEnv, $selection, 'const environment = AppEnvironment.production;')
Push-Location $flutterRoot
try {
    try {
        [IO.File]::WriteAllText($envPath, $productionEnv)
        & flutter build web --release --base-href / --pwa-strategy=none
        if ($LASTEXITCODE -ne 0) { throw 'Flutter web build failed.' }
    }
    finally { [IO.File]::WriteAllText($envPath, $originalEnv) }
    # Never publish a bundle whose selected API is local.
    $bundle = [IO.File]::ReadAllText((Join-Path $flutterRoot 'build/web/main.dart.js'))
    if (-not $bundle.Contains('https://whosme-api-759833941649.us-east4.run.app/')) {
        throw 'Production API URL is missing from the release bundle.'
    }
    if ($bundle.Contains('http://localhost:18080/')) {
        throw 'Local API URL found in release bundle; refusing deployment.'
    }
    if (-not $BuildOnly) {
        & firebase deploy --only hosting --project whosme-511315 --non-interactive
        if ($LASTEXITCODE -ne 0) { throw 'Firebase Hosting deployment failed.' }
    }
}
finally { Pop-Location }
