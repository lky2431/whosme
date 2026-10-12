param(
    [string]$ProjectId = 'whosme-511315',
    [string]$Region = 'us-east4',
    [string]$ImageTag = (Get-Date -Format 'yyyyMMdd-HHmmss'),
    [switch]$SkipBuild
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$image = "$Region-docker.pkg.dev/$ProjectId/whosme/backend:$ImageTag"
$envFile = Join-Path $projectRoot '.local/cloud-run.production.json'
if (-not (Test-Path $envFile)) { throw 'Run tool/configure-cloud-run.ps1 first.' }
Push-Location $projectRoot
try {
    if (-not $SkipBuild) {
        & gcloud builds submit . --config=tool/cloudbuild.yaml "--substitutions=_IMAGE=$image" --project=$ProjectId --quiet
        if ($LASTEXITCODE -ne 0) { throw 'Container build failed.' }
    }
    $secretBindings = @(
        'SERVERPOD_DATABASE_PASSWORD=whosme-database-password:1'
        'SERVERPOD_PASSWORD_serviceSecret=whosme-service-secret:1'
        'SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey=whosme-jwt-signing-key:1'
        'SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper=whosme-jwt-refresh-pepper:1'
        'SERVERPOD_PASSWORD_emailSecretHashPepper=whosme-email-pepper:1'
    ) -join ','
    # Run tool/migrate-neon.ps1 before deploying a schema-changing release.
    # The service never runs migrations automatically during instance startup.
    & gcloud run deploy whosme-api --project=$ProjectId --region=$Region --image=$image `
        --service-account="whosme-backend@$ProjectId.iam.gserviceaccount.com" `
        --port=8080 --cpu=1 --memory=512Mi --min-instances=0 --max-instances=3 `
        --concurrency=80 --timeout=3600 --allow-unauthenticated `
        --env-vars-file=$envFile --set-secrets=$secretBindings --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Cloud Run deployment failed.' }
}
finally { Pop-Location }
