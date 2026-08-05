# ============================================================
# MNS Trading Engine — Deployment Script
# ============================================================
# Copies engine source folders from the repository into every
# detected MetaTrader 5 MQL5 directory on this machine.
#
# Supports multiple MT5 installations automatically.
# Verifies terminal64.exe exists before deploying.
# Logs every deployment action with timestamp.
# ============================================================

param(
    [switch] $DryRun,           # Preview actions without copying
    [switch] $Verbose           # Show each file copied
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Paths ────────────────────────────────────────────────────
$RepoRoot   = Split-Path -Parent $PSScriptRoot
$LogDir     = Join-Path $RepoRoot "tools\logs"
$LogFile    = Join-Path $LogDir ("deploy_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$TerminalBase = Join-Path $env:APPDATA "MetaQuotes\Terminal"

$DeployFolders = @(
    "Experts",
    "Include",
    "Indicators",
    "Scripts",
    "Libraries"
)

# ── Helpers ──────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

function Write-Header {
    $border = "=" * 50
    Write-Host ""
    Write-Host $border
    Write-Host " MNS Trading Engine — Deployment"
    if ($DryRun) { Write-Host " *** DRY RUN — no files will be copied ***" }
    Write-Host $border
    Write-Host ""
}

# ── Discover MT5 Installations ────────────────────────────────
function Get-MT5Installations {
    $installations = @()

    if (-not (Test-Path $TerminalBase)) {
        return $installations
    }

    Get-ChildItem -Path $TerminalBase -Directory | ForEach-Object {
        $terminalExe = Join-Path $_.FullName "terminal64.exe"
        $mql5Dir     = Join-Path $_.FullName "MQL5"

        if ((Test-Path $terminalExe) -and (Test-Path $mql5Dir)) {
            $installations += [PSCustomObject]@{
                ID         = $_.Name
                TerminalExe = $terminalExe
                MQL5Dir    = $mql5Dir
            }
        }
    }

    return $installations
}

# ── Deploy to a Single Installation ──────────────────────────
function Deploy-ToInstallation {
    param([PSCustomObject]$Installation)

    Write-Log ("Deploying to terminal: {0}" -f $Installation.ID)
    Write-Log ("  MQL5 path: {0}" -f $Installation.MQL5Dir)

    $deployedCount = 0
    $skippedCount  = 0

    foreach ($Folder in $DeployFolders) {
        $Source      = Join-Path $RepoRoot $Folder
        $Destination = Join-Path $Installation.MQL5Dir $Folder

        if (-not (Test-Path $Source)) {
            Write-Log ("  Skipping '$Folder' — source not found in repo.") "WARN"
            $skippedCount++
            continue
        }

        Write-Log ("  Syncing: $Folder")

        if (-not $DryRun) {
            $robocopyArgs = @(
                $Source,
                $Destination,
                "/MIR",    # Mirror source to destination
                "/NFL",    # No file list
                "/NDL",    # No directory list
                "/NJH",    # No job header
                "/NJS",    # No job summary
                "/NP"      # No progress percentage
            )

            if ($Verbose) {
                $robocopyArgs = $robocopyArgs | Where-Object { $_ -ne "/NFL" }
            }

            $result = robocopy @robocopyArgs
            $exitCode = $LASTEXITCODE

            # robocopy exit codes 0-7 indicate success
            if ($exitCode -gt 7) {
                Write-Log ("  ERROR: robocopy failed for '$Folder' (exit code $exitCode)") "ERROR"
            }
        }

        $deployedCount++
    }

    Write-Log ("  Done — $deployedCount folder(s) deployed, $skippedCount skipped.")
}

# ── Main ──────────────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

Write-Header

$installations = Get-MT5Installations

if ($installations.Count -eq 0) {
    Write-Log "No MetaTrader 5 installations found." "ERROR"
    Write-Log "Expected location: $TerminalBase" "ERROR"
    exit 1
}

Write-Log ("Found {0} MT5 installation(s)." -f $installations.Count)
Write-Host ""

foreach ($inst in $installations) {
    Deploy-ToInstallation -Installation $inst
    Write-Host ""
}

Write-Log "Deployment complete."
Write-Host ""
Write-Host "Log saved to: $LogFile"
Write-Host ""
