param([string]$ProjectId = 'whosme-511315')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$localDir = Join-Path $projectRoot '.local'
New-Item -ItemType Directory -Path $localDir -Force | Out-Null
$databaseLine = Get-Content (Join-Path $projectRoot '.env.local') |
    Where-Object { $_ -match '^DATABASE_URL=' } | Select-Object -First 1
if (-not $databaseLine) { throw 'Run neon env pull first.' }
$databaseUri = [Uri]($databaseLine.Substring('DATABASE_URL='.Length).Trim('"', "'"))
$userInfo = $databaseUri.UserInfo.Split(':', 2)
$secretNames = @(& gcloud secrets list --project=$ProjectId --format='value(name)' --quiet)
if ($LASTEXITCODE -ne 0) { throw 'Unable to list production secrets.' }
$secrets = [ordered]@{
    'whosme-database-password' = [Uri]::UnescapeDataString($userInfo[1])
    'whosme-service-secret' = $null
    'whosme-jwt-signing-key' = $null
    'whosme-jwt-refresh-pepper' = $null
    'whosme-email-pepper' = $null
}
foreach ($name in $secrets.Keys) {
    if ($name -notin $secretNames) {
        $value = $secrets[$name]
        if (-not $value) {
            $bytes = [byte[]]::new(64)
            [Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
            $value = [Convert]::ToBase64String($bytes)
        }
        $temporaryFile = Join-Path $localDir "$name.tmp"
        try {
            [IO.File]::WriteAllText($temporaryFile, $value)
            & gcloud secrets create $name --project=$ProjectId --replication-policy=automatic --data-file=$temporaryFile --quiet
            if ($LASTEXITCODE -ne 0) { throw "Unable to create secret $name." }
        }
        finally { Remove-Item -LiteralPath $temporaryFile -ErrorAction SilentlyContinue }
    }
    & gcloud secrets add-iam-policy-binding $name --project=$ProjectId `
        --member="serviceAccount:whosme-backend@$ProjectId.iam.gserviceaccount.com" `
        --role=roles/secretmanager.secretAccessor --quiet --format=none
    if ($LASTEXITCODE -ne 0) { throw "Unable to grant access to $name." }
}
$settings = @{
    SERVERPOD_DATABASE_HOST = $databaseUri.Host
    SERVERPOD_DATABASE_PORT = '5432'
    SERVERPOD_DATABASE_NAME = $databaseUri.AbsolutePath.TrimStart('/')
    SERVERPOD_DATABASE_USER = [Uri]::UnescapeDataString($userInfo[0])
    SERVERPOD_DATABASE_REQUIRE_SSL = 'true'
    SERVERPOD_DATABASE_MAX_CONNECTION_COUNT = '5'
    SERVERPOD_API_SERVER_PUBLIC_HOST = "whosme-api-759833941649.us-east4.run.app"
    SERVERPOD_API_SERVER_PUBLIC_PORT = '443'
    SERVERPOD_API_SERVER_PUBLIC_SCHEME = 'https'
    SERVERPOD_SESSION_CONSOLE_LOG_ENABLED = 'true'
    FIREBASE_PROJECT_ID = 'yourname-lky'
}
$settings | ConvertTo-Json | Set-Content (Join-Path $localDir 'cloud-run.production.json') -Encoding utf8
Write-Host 'Production environment prepared; secrets are stored in Secret Manager.'
