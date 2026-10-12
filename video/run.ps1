param([ValidateSet('studio','render','typecheck','still')][string]$Task = 'studio')
$ErrorActionPreference = 'Stop'
$bundle = Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies'
$nodeBin = Join-Path $bundle 'node/bin'
$pnpm = Join-Path $bundle 'bin/fallback/pnpm.cmd'
if (Test-Path $pnpm) { $env:PATH = $nodeBin + ';' + $env:PATH } else { $pnpm = 'pnpm' }
Push-Location $PSScriptRoot
try {
  & $pnpm run $Task
  if ($LASTEXITCODE -ne 0) { throw "$Task failed ($LASTEXITCODE)." }
  if ($Task -eq 'render') {
    $python = Join-Path $bundle 'python/python.exe'
    if (-not (Test-Path $python)) { $python = 'python' }
    & $python (Join-Path $PSScriptRoot 'master-v2.py')
    if ($LASTEXITCODE -ne 0) { throw 'Audio mastering failed.' }
    & $python (Join-Path $PSScriptRoot 'validate-v2.py')
    if ($LASTEXITCODE -ne 0) { throw 'Final MP4 verification failed.' }
  }
}
finally { Pop-Location }
