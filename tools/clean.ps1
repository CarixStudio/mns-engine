# ============================================================
# MNS Trading Engine — Clean Script
# ============================================================
# Removes all compiled MQL5 binaries (.ex5) from the repo.
# Run before deploying to ensure stale binaries are not
# copied to MT5.
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot

Write-Host ""
Write-Host "========================================="
Write-Host " MNS Trading Engine — Clean"
Write-Host "========================================="
Write-Host ""

$files = Get-ChildItem -Path $RepoRoot -Recurse -Include "*.ex5" -ErrorAction SilentlyContinue

if ($files.Count -eq 0) {
    Write-Host "  Nothing to clean — no .ex5 files found."
} else {
    foreach ($file in $files) {
        Write-Host ("  Removing: {0}" -f $file.FullName)
        Remove-Item -Force $file.FullName
    }
    Write-Host ""
    Write-Host ("  Removed {0} compiled file(s)." -f $files.Count)
}

Write-Host ""
Write-Host "Clean complete."
Write-Host ""
exit 0
