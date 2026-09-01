# ============================================================
# MNS Trading Engine - Deployment Script
# ============================================================
# Copies engine source folders from the repository into every
# detected MetaTrader 5 MQL5 directory on this machine.
#
# Supports multiple MT5 installations automatically.
# Verifies terminal64.exe exists before deploying.
# Logs every deployment action with timestamp.
# ============================================================

param(
    [switch] $DryRun,
    [switch] $VerboseOutput
)

$ErrorActionPreference = "Stop"

# Paths
$RepoRoot     = Split-Path -Parent $PSScriptRoot
$LogDir       = Join-Path $RepoRoot "tools\logs"
$LogFile      = Join-Path $LogDir ("deploy_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$TerminalBase = Join-Path $env:APPDATA "MetaQuotes\Terminal"

$DeployFolders = @("Experts", "Include", "Indicators", "Scripts", "Libraries")

# Helpers
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
    Write-Host " MNS Trading Engine - Deployment"
    if ($DryRun) { Write-Host " *** DRY RUN - no files will be copied ***" }
    Write-Host $border
    Write-Host ""
}

# Discover MT5 installations
function Get-MT5Installations {
    $installations = @()
    if (-not (Test-Path $TerminalBase)) { return $installations }

    Get-ChildItem -Path $TerminalBase -Directory | ForEach-Object {
        $mql5Dir    = Join-Path $_.FullName "MQL5"
        $originFile = Join-Path $_.FullName "origin.txt"

        if (Test-Path $mql5Dir) {
            $isValid = $false
            $installPath = ""
            if (Test-Path $originFile) {
                $installPath = (Get-Content $originFile -Encoding Unicode -Raw).Trim()
                $terminalExe = Join-Path $installPath "terminal64.exe"
                if (Test-Path $terminalExe) {
                    $isValid = $true
                }
            }

            if ($isValid) {
                $installations += [PSCustomObject]@{
                    ID          = $_.Name
                    InstallPath = $installPath
                    MQL5Dir     = $mql5Dir
                }
            }
        }
    }
    return $installations
}

# Deploy to a single installation
function Deploy-ToInstallation {
    param([PSCustomObject]$Installation)

    Write-Log ("Deploying to terminal: {0}" -f $Installation.ID)
    Write-Log ("  Install path: {0}" -f $Installation.InstallPath)
    Write-Log ("  MQL5 path: {0}" -f $Installation.MQL5Dir)

    $deployedCount = 0
    $skippedCount  = 0

    foreach ($Folder in $DeployFolders) {
        $Source      = Join-Path $RepoRoot $Folder
        $Destination = Join-Path $Installation.MQL5Dir $Folder

        if (-not (Test-Path $Source)) {
            Write-Log ("  Skipping '$Folder' - source not found in repo.") "WARN"
            $skippedCount++
            continue
        }

        Write-Log ("  Syncing: $Folder")

        if (-not $DryRun) {
            $robocopyArgs = @(
                $Source, $Destination,
                "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NP"
            )
            if ($VerboseOutput) {
                $robocopyArgs = $robocopyArgs | Where-Object { $_ -ne "/NFL" }
            }

            robocopy @robocopyArgs | Out-Null
            if ($LASTEXITCODE -gt 7) {
                Write-Log ("  ERROR: robocopy failed for '$Folder' (exit $LASTEXITCODE)") "ERROR"
            }
        }

        $deployedCount++
    }

    Write-Log ("  Done - $deployedCount folder(s) deployed, $skippedCount skipped.")
}

# Main
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
Write-Header

$installations = Get-MT5Installations

if ($installations.Count -eq 0) {
    Write-Log "No MetaTrader 5 installations found." "ERROR"
    Write-Log "Expected data directory: $TerminalBase" "ERROR"
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
Write-Host "Log: $LogFile"
Write-Host ""
exit 0
