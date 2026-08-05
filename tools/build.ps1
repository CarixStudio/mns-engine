# ============================================================
# MNS Trading Engine — Build Script
# ============================================================
# Orchestrates the full local build pipeline:
#   1. Clean compiled binaries
#   2. Deploy source to MT5
#   3. Prompt to compile in MetaEditor
#
# Usage:
#   .\tools\build.ps1
#   .\tools\build.ps1 -DryRun
#   .\tools\build.ps1 -Verbose
# ============================================================

param(
    [switch] $DryRun,     # Pass through to deploy.ps1
    [switch] $Verbose     # Pass through to deploy.ps1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptsDir = $PSScriptRoot

Write-Host ""
Write-Host "========================================="
Write-Host " MNS Trading Engine — Build"
Write-Host "========================================="
Write-Host ""

# ── Step 1: Clean ────────────────────────────────────────────
Write-Host "--- Step 1: Clean ---"
& "$ScriptsDir\clean.ps1"
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    Write-Host "ERROR: clean.ps1 failed." -ForegroundColor Red
    exit 1
}

# ── Step 2: Deploy ───────────────────────────────────────────
Write-Host "--- Step 2: Deploy ---"
$deployArgs = @()
if ($DryRun)  { $deployArgs += "-DryRun" }
if ($Verbose) { $deployArgs += "-Verbose" }

& "$ScriptsDir\deploy.ps1" @deployArgs
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    Write-Host "ERROR: deploy.ps1 failed." -ForegroundColor Red
    exit 1
}

# ── Step 3: Prompt ───────────────────────────────────────────
Write-Host "========================================="
Write-Host " Build complete."
Write-Host ""
Write-Host " Next steps:"
Write-Host "   1. Open MetaEditor"
Write-Host "   2. Press F7 to compile"
Write-Host "   3. Verify zero errors and warnings"
Write-Host "   4. Open MT5 and test"
Write-Host "========================================="
Write-Host ""
