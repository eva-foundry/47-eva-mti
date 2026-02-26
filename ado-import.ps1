# EVA-FEATURE: F47-01
# EVA-STORY: F47-01-001
# EVA-STORY: F47-01-002
# EVA-STORY: F47-01-003
# EVA-STORY: F47-01-004
# EVA-STORY: F47-02-001
# ado-import.ps1
# Imports ado-artifacts.json into ADO (eva-poc) using the shared 38-ado-poc import script.
# Usage:
#   .\ado-import.ps1             -- live run
#   .\ado-import.ps1 -DryRun     -- validate schema / dry run only
param(
    [switch]$DryRun
)

$sharedScript = "C:\AICOE\eva-foundation\38-ado-poc\scripts\ado-import-project.ps1"

if (-not (Test-Path $sharedScript)) {
    throw "[FAIL] Shared import script not found: $sharedScript"
}

$artifactsFile = Join-Path $PSScriptRoot "ado-artifacts.json"

if (-not (Test-Path $artifactsFile)) {
    throw "[FAIL] ado-artifacts.json not found in: $PSScriptRoot"
}

Write-Host "[INFO] Project  : 47-eva-mti -- EVA Machine Trust Index"
Write-Host "[INFO] Artifacts: $artifactsFile"
Write-Host "[INFO] Dry run  : $DryRun"
Write-Host ""

& $sharedScript -ArtifactsFile $artifactsFile -DryRun:$DryRun
