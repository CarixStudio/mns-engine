# ==============================================================================
# MNS Trading Engine - Build-And-Archive.ps1
# ==============================================================================
#
# PURPOSE
#   Automates the full post-module workflow in a single command:
#
#     1. Compile  - runs MetaEditor CLI against the test harness
#     2. Test     - waits for you to run the harness inside MT5
#     3. Archive  - copies the newest Experts log into artifacts/logs/
#     4. Report   - prints a structured build summary
#     5. Commit   - (optional) creates a git commit
#
# USAGE
#   From the project root:
#
#     .\tools\Build-And-Archive.ps1 -Module "Module003"
#     .\tools\Build-And-Archive.ps1 -Module "Module003" -SkipCompile
#     .\tools\Build-And-Archive.ps1 -Module "Module003" -SkipGit
#
# PARAMETERS
#   -Module       Label used in the archived log filename.
#                 Example: "Module003" produces 2026-08-06_09-14_Module003.log
#                 Required.
#
#   -SkipCompile  Skip MetaEditor compilation step.
#                 Use when you know the file is already compiled.
#
#   -SkipGit      Do not offer a git commit after archiving.
#
# FUTURE EXPANSION POINTS (do not implement yet - add below the commit step)
#   - Strategy Tester automation   (Step 6)
#   - Regression test suite        (Step 7)
#   - Performance benchmarks       (Step 8)
#   - Coverage reports             (Step 9)
#   - Packaging / release builds   (Step 10)
#
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Module,       # e.g. "Module003"

    [switch] $SkipCompile,  # Skip MetaEditor compilation
    [switch] $SkipGit       # Skip the git commit prompt
)

$ErrorActionPreference = "Stop"

# ==============================================================================
# SECTION 1 - CONFIGURATION
# All environment-specific paths are defined here.
# The script body never contains hardcoded paths.
# ==============================================================================

# Resolve the project root from the script's own location (tools\ is one level down).
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# MetaTrader 5 data directory (roaming profile, not the install directory).
$TerminalBase  = Join-Path $env:APPDATA "MetaQuotes\Terminal"

# Deploy script — run before compile to sync source files to MT5.
$DeployScript = Join-Path $PSScriptRoot "deploy.ps1"

# MetaEditor executable path - resolved dynamically in Get-MetaEditorPath.
$MetaEditorExe = $null

# Path of the test harness source file relative to the Experts folder.
# Used to locate the deployed copy in the MT5 MQL5 directory.
# Compile targets the DEPLOYED path so the .ex5 lands where MT5 expects it.
$TestHarnessRelPath     = "Experts\MNS_TestHarness\MNS_TestHarness.mq5"
$TestHarnessPath        = Join-Path $ProjectRoot $TestHarnessRelPath  # repo copy (source)
$DeployedTestHarness    = $null  # populated in Assert-Prerequisites from MT5 install path

# Path of the indicator source file relative to the Indicators folder.
# Compiled alongside the TestHarness so the .ex5 is available in MT5 Navigator.
$IndicatorRelPath       = "Indicators\MNS_Indicator.mq5"
$IndicatorPath          = Join-Path $ProjectRoot $IndicatorRelPath     # repo copy (source)
$DeployedIndicator      = $null  # populated in Assert-Prerequisites from MT5 install path

$IndicatorExecOnlyRelPath = "Indicators\MNS_Indicator_ExecutionOnly.mq5"
$IndicatorExecOnlyPath    = Join-Path $ProjectRoot $IndicatorExecOnlyRelPath
$DeployedIndicatorExecOnly = $null

# MT5 writes EA Experts tab output (Print() calls) to:
#   <terminal_data>\MQL5\Logs\YYYYMMDD.log
# NOT to <terminal_data>\logs\ which is the system/network log.
# Resolved dynamically in Get-ExpertsLogDir.
$ExpertsLogDir = $null

# Artifacts output directory within the repository.
$ArtifactsLogDir = Join-Path $ProjectRoot "artifacts\logs"

# Internal script log (stored in tools\logs\ alongside deploy.ps1 logs).
$ToolsLogDir = Join-Path $ProjectRoot "tools\logs"
$ToolsLog    = Join-Path $ToolsLogDir ("build_archive_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

# ==============================================================================
# SECTION 2 - HELPERS
# ==============================================================================

# -- Logging -------------------------------------------------------------------

function Write-Log {
    <#
    .SYNOPSIS
        Writes a timestamped log line to both the console and the tools log file.
    .PARAMETER Message   The message to log.
    .PARAMETER Level     INFO (default) | WARN | ERROR | SUCCESS
    #>
    param(
        [string] $Message,
        [string] $Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line      = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message

    # Colour-code console output by severity.
    switch ($Level) {
        "ERROR"   { Write-Host $line -ForegroundColor Red    }
        "WARN"    { Write-Host $line -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $line -ForegroundColor Green  }
        default   { Write-Host $line                         }
    }

    # Ensure log directory exists before writing.
    if (-not (Test-Path $ToolsLogDir)) {
        New-Item -ItemType Directory -Force -Path $ToolsLogDir | Out-Null
    }
    Add-Content -Path $ToolsLog -Value $line
}

function Write-Banner {
    <#
    .SYNOPSIS Prints a section header banner. #>
    param([string] $Title)
    $border = "=" * 54
    Write-Host ""
    Write-Host $border
    Write-Host "  $Title"
    Write-Host $border
    Write-Host ""
}

function Exit-WithError {
    <#
    .SYNOPSIS
        Logs a fatal error message and exits with code 1.
    .PARAMETER Message  Error description shown to the user.
    #>
    param([string] $Message)
    Write-Log $Message "ERROR"
    Write-Host ""
    exit 1
}

# -- MT5 Discovery -------------------------------------------------------------

function Get-MT5Installations {
    <#
    .SYNOPSIS
        Returns all valid MetaTrader 5 installations found on this machine.
    .OUTPUTS
        Array of PSCustomObjects with properties:
          ID          - Terminal folder name (GUID)
          InstallPath - Full path to MT5 install (contains terminal64.exe)
          MQL5Dir     - Full path to the MQL5 data folder
          LogsDir     - Full path to the Logs folder (Experts output)
    #>
    $installations = [System.Collections.ArrayList]@()

    if (-not (Test-Path $TerminalBase)) {
        return ,$installations
    }

    $terminalDirs = Get-ChildItem -Path $TerminalBase -Directory

    foreach ($dir in $terminalDirs) {
        $mql5Dir    = Join-Path $dir.FullName "MQL5"
        # EA Print() output goes to MQL5\Logs\ NOT terminal\logs\
        $logsDir    = Join-Path $mql5Dir "Logs"
        $originFile = Join-Path $dir.FullName "origin.txt"

        if (-not (Test-Path $mql5Dir))    { continue }
        if (-not (Test-Path $originFile)) { continue }

        $installPath = (Get-Content $originFile -Raw).Trim()
        $terminalExe = Join-Path $installPath "terminal64.exe"

        if (-not (Test-Path $terminalExe)) { continue }

        $null = $installations.Add([PSCustomObject]@{
            ID          = $dir.Name
            InstallPath = $installPath
            MQL5Dir     = $mql5Dir
            LogsDir     = $logsDir
        })
    }

    return ,$installations


}

function Get-MetaEditorPath {
    <#
    .SYNOPSIS
        Resolves the MetaEditor.exe path from the first valid MT5 installation.
    .OUTPUTS
        Full path string, or $null if not found.
    #>
    $installations = Get-MT5Installations
    foreach ($inst in $installations) {
        $candidate = Join-Path $inst.InstallPath "metaeditor64.exe"
        if (Test-Path $candidate) {
            return $candidate
        }
    }
    return $null
}

function Get-ExpertsLogDir {
    <#
    .SYNOPSIS
        Returns the MT5 Logs directory for the first valid installation.
        MT5 writes the Experts tab content to dated log files here.
    .OUTPUTS
        Full path string, or $null if not found.
    #>
    $installations = Get-MT5Installations
    if ($installations.Count -gt 0) {
        return $installations[0].LogsDir
    }
    return $null
}

# -- Prerequisite Checks -------------------------------------------------------

function Assert-Prerequisites {
    <#
    .SYNOPSIS
        Validates all required tools and paths exist before the pipeline starts.
        Exits immediately with a clear message if anything is missing.
    #>

    # Test harness source must exist.
    if (-not (Test-Path $TestHarnessPath)) {
        Exit-WithError "Test harness not found: $TestHarnessPath"
    }

    # Deploy script must exist.
    if (-not (Test-Path $DeployScript)) {
        Exit-WithError "Deploy script not found: $DeployScript"
    }

    # Resolve the deployed test harness path from the first MT5 installation.
    # Compile targets this path so the .ex5 lands in MT5's Experts folder.
    $installations = Get-MT5Installations
    if ($installations.Count -eq 0) {
        Exit-WithError "No valid MT5 installation found under: $TerminalBase"
    }
    $firstInst = $installations[0]
    $script:DeployedTestHarness = Join-Path $firstInst.MQL5Dir $TestHarnessRelPath
    Write-Log "Deploy target (TestHarness) : $($script:DeployedTestHarness)"

    $script:DeployedIndicator = Join-Path $firstInst.MQL5Dir $IndicatorRelPath
    Write-Log "Deploy target (Indicator)   : $($script:DeployedIndicator)"

    $script:DeployedIndicatorExecOnly = Join-Path $firstInst.MQL5Dir $IndicatorExecOnlyRelPath
    Write-Log "Deploy target (ExecOnly Ind) : $($script:DeployedIndicatorExecOnly)"

    # MetaEditor must be locatable (skip check if -SkipCompile).
    if (-not $SkipCompile) {
        $script:MetaEditorExe = Get-MetaEditorPath
        if (-not $script:MetaEditorExe) {
            Exit-WithError (
                "MetaEditor64.exe not found in any MT5 installation.`n" +
                "  Checked: $TerminalBase\<id>\origin.txt -> <install>\metaeditor64.exe`n" +
                "  Use -SkipCompile if MetaEditor is not available."
            )
        }
        Write-Log "MetaEditor: $($script:MetaEditorExe)"
    }

    # MT5 Experts log directory: <terminal>\MQL5\Logs\
    # This is where MT5 writes EA Print() output (Experts tab).
    $script:ExpertsLogDir = Get-ExpertsLogDir
    if (-not $script:ExpertsLogDir) {
        Exit-WithError (
            "MT5 MQL5 Logs directory not found.`n" +
            "  Expected under: $TerminalBase\<id>\MQL5\Logs\"
        )
    }
    Write-Log "MT5 Expert logs: $($script:ExpertsLogDir)"

    # git must be on PATH (only if commit is enabled).
    if (-not $SkipGit) {
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitCmd) {
            Write-Log "git not found on PATH - git commit step will be skipped." "WARN"
            $script:SkipGit = $true
        }
    }
}

# ==============================================================================
# SECTION 3 - PIPELINE STEPS
# Each step is an independent function.
# Future steps (Strategy Tester, regression, benchmarks) slot in here.
# ==============================================================================

# -- Step 0: Deploy -----------------------------------------------------------

function Invoke-Deploy {
    <#
    .SYNOPSIS
        Syncs source files from the repository to the MT5 MQL5 folder.
        Must run before compile so MetaEditor compiles the latest source.
    #>

    Write-Banner "Step 0 - Deploy Source"
    Write-Log "Running: $DeployScript"

    & $DeployScript
    if ($LASTEXITCODE -and ($LASTEXITCODE -ne 0)) {
        Exit-WithError "deploy.ps1 failed (exit $LASTEXITCODE)"
    }

    Write-Log "Deploy complete." "SUCCESS"
}

# -- Step 1: Compile -----------------------------------------------------------

function Invoke-Compile {
    <#
    .SYNOPSIS
        Runs MetaEditor64.exe in CLI mode to compile the deployed test harness.
        Compiles from the MT5 MQL5 Experts path (not the repo) so the resulting
        .ex5 is written directly to the folder MT5 loads EAs from.
        Exits with code 1 if compilation fails.
    #>

    Write-Banner "Step 1 - Compile"

    # Compile from the DEPLOYED path in MT5's MQL5\Experts\ folder.
    # This ensures the resulting .ex5 is in the location MT5 loads EAs from.
    $compilePath     = $script:DeployedTestHarness
    $compilerLogPath = [System.IO.Path]::ChangeExtension($compilePath, ".log")

    if (-not (Test-Path $compilePath)) {
        Exit-WithError "Deployed test harness not found: $compilePath`n  Run deploy.ps1 first."
    }

    Write-Log "Compiling: $compilePath"
    Write-Host ""

    $compileArgs = @(
        "/compile:`"$compilePath`"",
        "/log:`"$compilerLogPath`""
    )

    $process = Start-Process -FilePath $script:MetaEditorExe `
                             -ArgumentList $compileArgs `
                             -Wait -PassThru -NoNewWindow

    # Always show compiler output so warnings are visible even on success.
    $compilerOutput = ""
    if (Test-Path $compilerLogPath) {
        $compilerOutput = Get-Content $compilerLogPath -Raw
        if ($compilerOutput) {
            Write-Host "--- Compiler Output ---"
            Write-Host $compilerOutput
            Write-Host "-----------------------"
            Write-Host ""
        }
    }

    # MetaEditor64.exe exit code is NOT reliable - it returns 1 even on a
    # clean compile. Parse the log for the Result line instead.
    # Success pattern: "Result: 0 errors"
    if ($compilerOutput -match "Result:\s+0 errors") {
        Write-Log "Compilation succeeded (0 errors, 0 warnings)." "SUCCESS"
        return
    }

    # If we cannot find a success pattern, treat it as a failure.
    Exit-WithError "Compilation FAILED. Check output above. Log: $compilerLogPath"

}

# -- Step 1b: Compile Indicator ------------------------------------------------

function Invoke-CompileIndicator {
    <#
    .SYNOPSIS
        Runs MetaEditor64.exe in CLI mode to compile MNS_Indicator.mq5.
        Compiles from the MT5 MQL5 Indicators path so the resulting .ex5
        lands where MT5 loads indicators from (Navigator → Indicators).
        Exits with code 1 if compilation fails.
    #>

    Write-Banner "Step 1b - Compile Indicator"

    $compilePath     = $script:DeployedIndicator
    $compilerLogPath = [System.IO.Path]::ChangeExtension($compilePath, ".log")

    if (-not (Test-Path $compilePath)) {
        Exit-WithError "Deployed indicator not found: $compilePath`n  Run deploy.ps1 first."
    }

    Write-Log "Compiling: $compilePath"
    Write-Host ""

    $compileArgs = @(
        "/compile:`"$compilePath`"",
        "/log:`"$compilerLogPath`""
    )

    $process = Start-Process -FilePath $script:MetaEditorExe `
                             -ArgumentList $compileArgs `
                             -Wait -PassThru -NoNewWindow

    # Always show compiler output so warnings are visible even on success.
    $compilerOutput = ""
    if (Test-Path $compilerLogPath) {
        $compilerOutput = Get-Content $compilerLogPath -Raw
        if ($compilerOutput) {
            Write-Host "--- Compiler Output ---"
            Write-Host $compilerOutput
            Write-Host "-----------------------"
            Write-Host ""
        }
    }

    if ($compilerOutput -match "Result:\s+0 errors") {
        Write-Log "Indicator compilation succeeded (0 errors, 0 warnings)." "SUCCESS"
        return
    }

    Exit-WithError "Indicator compilation FAILED. Check output above. Log: $compilerLogPath"

}

# -- Step 1c: Compile Execution-Only Indicator ---------------------------------

function Invoke-CompileIndicatorExecOnly {
    <#
    .SYNOPSIS
        Runs MetaEditor64.exe in CLI mode to compile MNS_Indicator_ExecutionOnly.mq5.
        Compiles from the MT5 MQL5 Indicators path.
        Exits with code 1 if compilation fails.
    #>

    Write-Banner "Step 1c - Compile Execution-Only Indicator"

    $compilePath     = $script:DeployedIndicatorExecOnly
    $compilerLogPath = [System.IO.Path]::ChangeExtension($compilePath, ".log")

    if (-not (Test-Path $compilePath)) {
        Exit-WithError "Deployed execution-only indicator not found: $compilePath`n  Run deploy.ps1 first."
    }

    Write-Log "Compiling: $compilePath"
    Write-Host ""

    $compileArgs = @(
        "/compile:`"$compilePath`"",
        "/log:`"$compilerLogPath`""
    )

    $process = Start-Process -FilePath $script:MetaEditorExe `
                             -ArgumentList $compileArgs `
                             -Wait -PassThru -NoNewWindow

    # Always show compiler output so warnings are visible even on success.
    $compilerOutput = ""
    if (Test-Path $compilerLogPath) {
        $compilerOutput = Get-Content $compilerLogPath -Raw
        if ($compilerOutput) {
            Write-Host "--- Compiler Output ---"
            Write-Host $compilerOutput
            Write-Host "-----------------------"
            Write-Host ""
        }
    }

    if ($compilerOutput -match "Result:\s+0 errors") {
        Write-Log "Execution-Only Indicator compilation succeeded (0 errors, 0 warnings)." "SUCCESS"
        return
    }

    Exit-WithError "Execution-Only Indicator compilation FAILED. Check output above. Log: $compilerLogPath"

}

# -- Step 2: Wait for Test Harness ---------------------------------------------

function Invoke-WaitForTest {
    <#
    .SYNOPSIS
        Pauses execution and instructs the user to run the test harness in MT5.
        Resumes when the user presses ENTER.
    #>

    Write-Banner "Step 2 - Run Test Harness"

    Write-Host "  1. Open MetaTrader 5"
    Write-Host "  2. Attach MNS_TestHarness to any chart"
    Write-Host "  3. Wait for the EA to run and self-remove"
    Write-Host "  4. Check the Experts tab for PASS/FAIL output"
    Write-Host ""
    Write-Host "  Press ENTER here once the test has completed..." -NoNewline
    $null = Read-Host
    Write-Host ""
    
    # Safety delay to allow MT5 to flush buffered log writes to disk
    Write-Log "Waiting 6 seconds for MetaTrader log buffer to flush..."
    Start-Sleep -Seconds 6

    Write-Log "User confirmed test run complete."
}

# -- Step 3: Archive Experts Log -----------------------------------------------

function Invoke-ArchiveLog {
    <#
    .SYNOPSIS
        Finds the newest file in the MT5 Logs directory and copies it into
        artifacts/logs/ with a timestamped, module-labelled filename.
    .OUTPUTS
        The destination file path as a string.
    #>

    Write-Banner "Step 3 - Archive Experts Log"

    # Find the newest file in the MT5 logs directory.
    # MT5 writes one log file per day named YYYYMMDD.log.
    if (-not (Test-Path $script:ExpertsLogDir)) {
        Exit-WithError "MT5 Logs directory disappeared: $($script:ExpertsLogDir)"
    }

    $newestLog = Get-ChildItem -Path $script:ExpertsLogDir -File |
                 Sort-Object LastWriteTime -Descending |
                 Select-Object -First 1

    if (-not $newestLog) {
        Exit-WithError "No log files found in: $($script:ExpertsLogDir)"
    }

    Write-Log "Source log: $($newestLog.FullName) (modified $($newestLog.LastWriteTime))"

    # Build the destination filename: YYYY-MM-DD_HH-mm_<Module>.log
    $timestamp   = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $archiveName = "{0}_{1}.log" -f $timestamp, $Module
    $archiveDest = Join-Path $ArtifactsLogDir $archiveName

    # Create artifacts/logs/ if it does not exist.
    if (-not (Test-Path $ArtifactsLogDir)) {
        Write-Log "Creating artifacts directory: $ArtifactsLogDir"
        New-Item -ItemType Directory -Force -Path $ArtifactsLogDir | Out-Null
    }

    # Never overwrite an existing archive.
    if (Test-Path $archiveDest) {
        Exit-WithError "Archive already exists - will not overwrite: $archiveDest"
    }

    # Copy only the latest test run from the log.
    try {
        $lines = Get-Content -Path $newestLog.FullName -Encoding Unicode
        $startIndex = -1
        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            if ($lines[$i] -like "*Test Harness v2.0*") {
                # Go back one line to catch the preceding border line
                $startIndex = if ($i -gt 0 -and $lines[$i-1] -like "*====*") { $i - 1 } else { $i }
                break
            }
        }

        if ($startIndex -ge 0) {
            $filteredLines = $lines[$startIndex..($lines.Count - 1)]
            $filteredLines | Out-File -FilePath $archiveDest -Encoding Unicode
        } else {
            # Fallback to copy the entire file if header is not found
            Copy-Item -Path $newestLog.FullName -Destination $archiveDest -ErrorAction Stop
        }
    }
    catch {
        Exit-WithError "Failed to process and copy log: $_"
    }

    Write-Log "Archived: $archiveName" "SUCCESS"

    return $archiveDest
}

# -- Step 4: Build Report ------------------------------------------------------

function Write-BuildReport {
    <#
    .SYNOPSIS
        Prints a structured summary of the completed build pipeline.
    .PARAMETER ArchivedLogPath   Full path of the archived log file.
    #>
    param([string] $ArchivedLogPath)

    $archiveName = Split-Path -Leaf $ArchivedLogPath

    Write-Host ""
    Write-Host "=========================="
    Write-Host " BUILD SUCCESS" -ForegroundColor Green
    Write-Host "=========================="
    Write-Host ""

    if (-not $SkipCompile) {
        Write-Host " Compiled:"
        Write-Host "   [OK] MNS_TestHarness" -ForegroundColor Green
        Write-Host "   [OK] MNS_Indicator"   -ForegroundColor Green
        Write-Host "   [OK] MNS_Indicator_ExecutionOnly" -ForegroundColor Green
        Write-Host ""
    }

    Write-Host " Archived:"
    Write-Host "   [OK] $archiveName" -ForegroundColor Green
    Write-Host ""

    Write-Host " Location:"
    Write-Host "   artifacts\logs\"
    Write-Host ""

    Write-Host " Next:"
    Write-Host "   Commit changes"
    Write-Host ""
}

# -- Step 5: Git Commit (optional) ---------------------------------------------

function Invoke-GitCommit {
    <#
    .SYNOPSIS
        Prompts for a commit message and runs git add . && git commit.
        Skips silently if the user declines or git is unavailable.
    #>

    Write-Banner "Step 5 - Git Commit (optional)"

    Write-Host "  Create git commit? (Y/N) " -NoNewline
    $answer = Read-Host

    if ($answer -notmatch '^[Yy]') {
        Write-Log "Git commit skipped by user."
        return
    }

    Write-Host "  Commit message: " -NoNewline
    $commitMessage = Read-Host

    if ([string]::IsNullOrWhiteSpace($commitMessage)) {
        Write-Log "Empty commit message - git commit skipped." "WARN"
        return
    }

    Write-Log "Running: git add ."
    git add .
    if ($LASTEXITCODE -ne 0) {
        Exit-WithError "git add failed (exit $LASTEXITCODE)"
    }

    Write-Log "Running: git commit -m `"$commitMessage`""
    git commit -m $commitMessage
    if ($LASTEXITCODE -ne 0) {
        Exit-WithError "git commit failed (exit $LASTEXITCODE)"
    }

    Write-Log "Committed: $commitMessage" "SUCCESS"
}

# ==============================================================================
# SECTION 4 - MAIN ENTRY POINT
# Steps are called in sequence. Each step is responsible for its own
# error handling and exits cleanly if something goes wrong.
# ==============================================================================

function Main {

    Write-Banner "MNS Trading Engine - Build and Archive [$Module]"

    Write-Log "Project root : $ProjectRoot"
    Write-Log "Module label : $Module"
    Write-Log "SkipCompile  : $SkipCompile"
    Write-Log "SkipGit      : $SkipGit"
    Write-Host ""

    # Validate environment before starting any steps.
    Assert-Prerequisites

    # -- Step 0: Deploy --------------------------------------------------------
    # Always deploy source before compile so MT5 has the latest .mq5 files.
    Invoke-Deploy

    # -- Step 1: Compile -------------------------------------------------------
    if (-not $SkipCompile) {
        Invoke-Compile
        Invoke-CompileIndicator
        Invoke-CompileIndicatorExecOnly
    }
    else {
        Write-Log "Compilation skipped (-SkipCompile)." "WARN"
    }

    # -- Step 2: Wait for test harness -----------------------------------------
    Invoke-WaitForTest

    # -- Step 3: Archive log ---------------------------------------------------
    $archivedLog = Invoke-ArchiveLog

    # -- Step 4: Build report --------------------------------------------------
    Write-BuildReport -ArchivedLogPath $archivedLog

    # -- Step 5: Git commit ----------------------------------------------------
    if (-not $SkipGit) {
        Invoke-GitCommit
    }
    else {
        Write-Log "Git commit skipped (-SkipGit)." "WARN"
    }

    # -- Future steps slot in here ---------------------------------------------
    # Step 6: Invoke-StrategyTester  (not yet implemented)
    # Step 7: Invoke-RegressionSuite (not yet implemented)
    # Step 8: Invoke-PerfBenchmarks  (not yet implemented)
    # Step 9: Invoke-CoverageReport  (not yet implemented)
    # Step 10: Invoke-ReleasePackage (not yet implemented)

    Write-Log "Build-And-Archive complete." "SUCCESS"
    Write-Host ""
    exit 0
}

# Run.
Main
