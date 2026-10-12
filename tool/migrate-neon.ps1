param(
    [string]$Branch = 'production',
    [string]$ProjectId = 'snowy-meadow-62290628'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
# Never print the connection string or put a password in command arguments.
$envPath = Join-Path $projectRoot '.env.local'
if ($Branch -eq 'production' -and $ProjectId -eq 'snowy-meadow-62290628' -and (Test-Path $envPath)) {
    $line = Get-Content $envPath | Where-Object { $_ -match '^DATABASE_URL_UNPOOLED=' } | Select-Object -First 1
    if (-not $line) { throw 'Missing DATABASE_URL_UNPOOLED; run neon env pull.' }
    $connection = $line.Substring('DATABASE_URL_UNPOOLED='.Length).Trim('"', "'")
} else {
    $connection = (& neon connection-string $Branch --project-id $ProjectId).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Unable to read the Neon connection.' }
}
$databaseUri = [Uri]$connection
if ($databaseUri.Host -match '-pooler\.') { throw 'Migrations require a direct connection.' }
$userInfo = $databaseUri.UserInfo.Split(':', 2)
$settings = @{
    SERVERPOD_DATABASE_HOST = $databaseUri.Host
    SERVERPOD_DATABASE_PORT = '5432'
    SERVERPOD_DATABASE_NAME = $databaseUri.AbsolutePath.TrimStart('/')
    SERVERPOD_DATABASE_USER = [Uri]::UnescapeDataString($userInfo[0])
    SERVERPOD_DATABASE_PASSWORD = [Uri]::UnescapeDataString($userInfo[1])
    SERVERPOD_DATABASE_REQUIRE_SSL = 'true'
    SERVERPOD_DATABASE_MAX_CONNECTION_COUNT = '3'
    FIREBASE_PROJECT_ID = 'yourname-lky'
}
# Authentication must initialize even in migration-only mode. These ephemeral
# values are never used to issue production tokens or persisted to the database.
foreach ($key in @('serviceSecret', 'jwtHmacSha512PrivateKey', 'jwtRefreshTokenHashPepper', 'emailSecretHashPepper')) {
    $bytes = [byte[]]::new(64)
    [Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    $settings["SERVERPOD_PASSWORD_$key"] = [Convert]::ToBase64String($bytes)
}
$previous = @{}
try {
    foreach ($key in $settings.Keys) {
        $previous[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
        [Environment]::SetEnvironmentVariable($key, $settings[$key], 'Process')
    }
    Push-Location (Join-Path $projectRoot 'yourname_server')
    try {
        & dart --packages=../.dart_tool/package_config.json bin/main.dart --mode=production --role=maintenance --apply-migrations
        if ($LASTEXITCODE -ne 0) { throw 'Serverpod migration failed.' }
    }
    finally { Pop-Location }
}
finally {
    foreach ($key in $previous.Keys) {
        [Environment]::SetEnvironmentVariable($key, $previous[$key], 'Process')
    }
}
