#Requires -Version 5.1
<#
.SYNOPSIS
    Installs the extract tool on Windows.
.DESCRIPTION
    Downloads the extract Python script, validates it, installs it, and writes
    an extract.bat launcher so you can call 'extract' directly from CMD or
    PowerShell without typing 'python'.
.PARAMETER InstallDir
    Directory to install into. Defaults to %USERPROFILE%\.local\bin
.PARAMETER NoGlobalLink
    Do not attempt to add the install directory to the user PATH.
.PARAMETER NoAutoUpdate
    Print guidance for disabling auto-update via config.yaml.
.PARAMETER Quiet
    Suppress non-error output.
.EXAMPLE
    irm https://raw.githubusercontent.com/omnious0o0/extract/main/.extract/install.ps1 | iex
.EXAMPLE
    .\install.ps1 -InstallDir C:\tools\extract
#>
[CmdletBinding()]
param(
    [string]$InstallDir = "",
    [switch]$NoGlobalLink,
    [switch]$NoAutoUpdate,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRepo  = "omnious0o0/extract"
$SourceUrl    = if ($env:EXTRACT_SOURCE_URL) { $env:EXTRACT_SOURCE_URL } else {
    "https://raw.githubusercontent.com/$ProjectRepo/main/extract"
}
$DefaultInstallDir = Join-Path $env:USERPROFILE ".local\bin"

# ── helpers ──────────────────────────────────────────────────────────────────

function Write-Logo {
    Write-Host " ███████╗██╗  ██╗████████╗██████╗  █████╗  ██████╗████████╗" -ForegroundColor Blue
    Write-Host " ██╔════╝╚██╗██╔╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝" -ForegroundColor Blue
    Write-Host " █████╗   ╚███╔╝    ██║   ██████╔╝███████║██║        ██║   " -ForegroundColor Blue
    Write-Host " ██╔══╝   ██╔██╗    ██║   ██╔══██╗██╔══██║██║        ██║   " -ForegroundColor Blue
    Write-Host " ███████╗██╔╝ ██╗   ██║   ██║  ██║██║  ██║╚██████╗   ██║   " -ForegroundColor Blue
    Write-Host " ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝   " -ForegroundColor Blue
}

function Info([string]$Message) {
    if (-not $Quiet) { Write-Host "[i] $Message" -ForegroundColor Cyan }
}

function Ok([string]$Message) {
    if (-not $Quiet) { Write-Host "[ok] $Message" -ForegroundColor Green }
}

function Warn([string]$Message) {
    Write-Host "[warn] $Message" -ForegroundColor Yellow
}

function Die([string]$Message) {
    Write-Host "[error] $Message" -ForegroundColor Red -Stream Error
    exit 1
}

# ── python detection ──────────────────────────────────────────────────────────

function Find-Python {
    foreach ($candidate in @("python", "python3", "py")) {
        try {
            $exe = (Get-Command $candidate -ErrorAction SilentlyContinue).Source
            if (-not $exe) { continue }
            $ver = & $exe --version 2>&1
            if ($ver -match "^Python 3\.") { return $exe }
        } catch { }
    }
    return $null
}

# ── install dir resolution ────────────────────────────────────────────────────

function Resolve-InstallDir {
    if ($InstallDir -ne "") { return $InstallDir }

    # Check if default dir is already on PATH
    $pathDirs = $env:PATH -split ";"
    if ($pathDirs -contains $DefaultInstallDir) { return $DefaultInstallDir }

    # Check if there's already an extract somewhere writable
    $existing = (Get-Command "extract" -ErrorAction SilentlyContinue).Source
    if ($existing) {
        $existingDir = Split-Path $existing -Parent
        if (Test-Path $existingDir) { return $existingDir }
    }

    return $DefaultInstallDir
}

# ── download ──────────────────────────────────────────────────────────────────

function Download-Extract([string]$Destination) {
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers["User-Agent"] = "extract-installer/powershell"
        $wc.DownloadFile($SourceUrl, $Destination)
    } catch {
        # Fallback: Invoke-WebRequest (slower but more universally available)
        Invoke-WebRequest -Uri $SourceUrl -OutFile $Destination -UseBasicParsing
    }
}

# ── validation ────────────────────────────────────────────────────────────────

function Validate-Payload([string]$PythonExe, [string]$FilePath) {
    $lines = Get-Content $FilePath -TotalCount 5 -Encoding UTF8

    if ($lines[0] -ne "#!/usr/bin/env python3") {
        Die "Downloaded file failed shebang validation."
    }
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    if ($content -notmatch "(?m)^VERSION = ") {
        Die "Downloaded file missing VERSION metadata."
    }
    if ($content -notmatch "(?m)^def main\(") {
        Die "Downloaded file missing entrypoint (def main)."
    }
    # Syntax check
    $result = & $PythonExe -m py_compile $FilePath 2>&1
    if ($LASTEXITCODE -ne 0) {
        Die "Downloaded file failed Python syntax validation: $result"
    }
}

function Verify-Executable([string]$PythonExe, [string]$ScriptPath) {
    $env:EXTRACT_NO_AUTO_UPDATE = "1"
    & $PythonExe $ScriptPath --version 2>&1 | Out-Null
    Remove-Item Env:\EXTRACT_NO_AUTO_UPDATE -ErrorAction SilentlyContinue
    return ($LASTEXITCODE -eq 0)
}

# ── PATH helper ───────────────────────────────────────────────────────────────

function Add-ToUserPath([string]$Dir) {
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $existing = $userPath -split ";" | Where-Object { $_ -ieq $Dir }
    if ($existing) { return }
    $newPath = ($Dir + ";" + $userPath).TrimEnd(";")
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Ok "Added $Dir to your user PATH (restart your terminal to apply)"
}

# ── main ──────────────────────────────────────────────────────────────────────

if (-not $Quiet) {
    Write-Logo
    Write-Host "extract installer" -ForegroundColor DarkGray
    Write-Host ""
}

$pythonExe = Find-Python
if (-not $pythonExe) {
    Die "Python 3 not found. Install it from https://www.python.org/downloads/ and re-run."
}
Info "Using Python: $pythonExe"

$resolvedInstallDir = Resolve-InstallDir
$targetScript = Join-Path $resolvedInstallDir "extract"
$targetBat    = Join-Path $resolvedInstallDir "extract.bat"

Info "Installing into $resolvedInstallDir"
if (-not (Test-Path $resolvedInstallDir)) {
    New-Item -ItemType Directory -Force -Path $resolvedInstallDir | Out-Null
}

# Download to temp file
$tmpDownload = [System.IO.Path]::GetTempFileName()
try {
    Info "Downloading extract from $SourceUrl"
    Download-Extract $tmpDownload
    Validate-Payload $pythonExe $tmpDownload

    # Stage inside install dir for atomic-ish move
    $tmpStaged = Join-Path $resolvedInstallDir (".extract.staged." + [System.IO.Path]::GetRandomFileName())
    Copy-Item $tmpDownload $tmpStaged -Force

    if (-not (Verify-Executable $pythonExe $tmpStaged)) {
        Die "Staged extract binary failed execution check."
    }

    # Backup existing if present
    $backupPath = $null
    if (Test-Path $targetScript) {
        $backupPath = [System.IO.Path]::GetTempFileName()
        Copy-Item $targetScript $backupPath -Force
        Info "Backed up existing extract"
    }

    try {
        Move-Item $tmpStaged $targetScript -Force
        $tmpStaged = $null
    } catch {
        if ($backupPath -and (Test-Path $backupPath)) {
            Copy-Item $backupPath $targetScript -Force
        }
        Die "Failed to install extract: $_"
    }

    if (-not (Verify-Executable $pythonExe $targetScript)) {
        if ($backupPath -and (Test-Path $backupPath)) {
            Copy-Item $backupPath $targetScript -Force
        }
        Die "Installed extract failed execution check."
    }

    if ($backupPath -and (Test-Path $backupPath)) {
        Remove-Item $backupPath -Force -ErrorAction SilentlyContinue
    }

    Ok "Installed extract to $targetScript"

} finally {
    if (Test-Path $tmpDownload) { Remove-Item $tmpDownload -Force -ErrorAction SilentlyContinue }
    if ($tmpStaged -and (Test-Path $tmpStaged)) { Remove-Item $tmpStaged -Force -ErrorAction SilentlyContinue }
}

# Write extract.bat launcher
$batContent = "@echo off`r`n`"$pythonExe`" `"$targetScript`" %*`r`n"
Set-Content -Path $targetBat -Value $batContent -Encoding ASCII -NoNewline
Ok "Created extract.bat launcher at $targetBat"

# PATH management
$pathDirs = $env:PATH -split ";"
if ($pathDirs -contains $resolvedInstallDir -or ($pathDirs | Where-Object { $_ -ieq $resolvedInstallDir })) {
    Ok "$resolvedInstallDir is already in PATH; 'extract' is globally runnable"
} elseif (-not $NoGlobalLink) {
    Add-ToUserPath $resolvedInstallDir
} else {
    Warn "$resolvedInstallDir is not in PATH"
    Write-Host "  Add it manually: [System.Environment]::SetEnvironmentVariable('PATH', '$resolvedInstallDir;' + `$env:PATH, 'User')"
}

if ($NoAutoUpdate) {
    Info "To disable auto-update, add 'auto_update: false' to your project's config.yaml"
} else {
    Info "Auto-update is controlled per-project via config.yaml (auto_update: true/false)"
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green -NoNewline
Write-Host " Run: " -NoNewline
Write-Host "extract ." -ForegroundColor Cyan
