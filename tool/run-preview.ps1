param([string]$PostgresBin = 'C:\Program Files\PostgreSQL\18\bin')
$ErrorActionPreference = 'Stop'
# Check before touching the database or starting a second Serverpod process.
$previewPorts = @(18080, 18081, 18082)
$occupiedPorts = @([System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners() |
    Where-Object { $_.Port -in $previewPorts } |
    ForEach-Object { $_.Port } | Sort-Object -Unique)
if ($occupiedPorts.Count -gt 0) {
    throw "Preview ports already in use: $($occupiedPorts -join ', '). If your backend is already running, keep its terminal open and run .\tool\run-frontend.ps1 in another terminal. To restart the backend, stop its existing session first. No processes were stopped."
}
$projectRoot = Split-Path $PSScriptRoot -Parent
$localDir = Join-Path $projectRoot '.local'
$dataDir = Join-Path $localDir 'postgres'
New-Item -ItemType Directory -Path $localDir -Force | Out-Null
if (-not (Test-Path (Join-Path $PostgresBin 'pg_ctl.exe'))) {
    throw 'PostgreSQL binaries not found. Pass -PostgresBin, or use the Docker setup in README.md.'
}
if (-not (Test-Path (Join-Path $dataDir 'PG_VERSION'))) {
    & (Join-Path $PostgresBin 'initdb.exe') -D $dataDir -U postgres --auth=trust --encoding=UTF8 --locale=C
    if ($LASTEXITCODE -ne 0) { throw 'Database initialization failed.' }
}
& (Join-Path $PostgresBin 'pg_ctl.exe') -D $dataDir status *> $null
if ($LASTEXITCODE -ne 0) {
    $logPath = Join-Path $localDir 'postgres.log'
    Start-Process -FilePath (Join-Path $PostgresBin 'pg_ctl.exe') -ArgumentList @(
        '-D', ('"' + $dataDir + '"'), '-l', ('"' + $logPath + '"'),
        '-o', '"-p 18090 -h 127.0.0.1"', '-w', 'start'
    ) -WindowStyle Hidden | Out-Null
    $ready = $false
    for ($i = 0; $i -lt 40; $i++) {
        Start-Sleep -Milliseconds 250
        & (Join-Path $PostgresBin 'pg_isready.exe') -h 127.0.0.1 -p 18090 *> $null
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    }
    if (-not $ready) { throw "Database did not start. See $logPath" }
}
# Verify this port belongs to this project's cluster before creating or migrating.
$actualDataDir = (& (Join-Path $PostgresBin 'psql.exe') -h 127.0.0.1 -p 18090 -U postgres -d postgres -tAc 'SHOW data_directory').Trim()
if ([IO.Path]::GetFullPath($actualDataDir) -ne [IO.Path]::GetFullPath($dataDir)) {
    throw 'Port 18090 belongs to another database. Refusing to modify it.'
}
$exists = & (Join-Path $PostgresBin 'psql.exe') -h 127.0.0.1 -p 18090 -U postgres -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='yourname_smoke'"
if ($exists -ne '1') {
    & (Join-Path $PostgresBin 'createdb.exe') -h 127.0.0.1 -p 18090 -U postgres yourname_smoke
    if ($LASTEXITCODE -ne 0) { throw 'Database creation failed.' }
}
if (-not $env:PUB_CACHE) { $env:PUB_CACHE = Join-Path $env:LOCALAPPDATA 'Pub\Cache' }
$env:APPDATA = Join-Path $localDir 'roaming'
$env:LOCALAPPDATA = Join-Path $localDir 'local'
$env:SERVERPOD_DATABASE_HOST = '127.0.0.1'
$env:SERVERPOD_DATABASE_PORT = '18090'
$env:SERVERPOD_DATABASE_NAME = 'yourname_smoke'
$env:SERVERPOD_API_SERVER_PORT = '18080'
$env:SERVERPOD_API_SERVER_PUBLIC_PORT = '18080'
$env:SERVERPOD_INSIGHTS_SERVER_PORT = '18081'
$env:SERVERPOD_WEB_SERVER_PORT = '18082'
$env:SERVERPOD_WEB_SERVER_PUBLIC_PORT = '18082'
Push-Location (Join-Path $projectRoot 'yourname_server')
try { & dart run bin/main.dart --apply-migrations }
finally { Pop-Location }
