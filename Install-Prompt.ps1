#Requires -Version 7.0
<#
.SYNOPSIS
    Installs Oh My Posh and configures the custom PowerShell prompt theme.

.DESCRIPTION
    This script:
    1. Installs Oh My Posh (if not already installed)
    2. Installs a Nerd Font (required for icons)
    3. Copies the custom theme to the Oh My Posh themes directory
    4. Configures the PowerShell profile to load the theme

.NOTES
    Run this script in an ELEVATED (Administrator) PowerShell 7+ terminal.
    After installation, restart your terminal and select the Nerd Font in
    your terminal settings (e.g., "CaskaydiaCove Nerd Font").
#>

param(
    [string]$FontName = "CaskaydiaCove"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$themeName = "BenCustomised.omp.json"
$themeSource = Join-Path $scriptDir $themeName

Write-Host "`n=== Oh My Posh Prompt Setup ===" -ForegroundColor Cyan

# --- 1. Install Oh My Posh ---
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Oh My Posh is already installed." -ForegroundColor Green
    oh-my-posh version
} else {
    Write-Host "[..] Installing Oh My Posh via winget..." -ForegroundColor Yellow
    winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        Write-Host "[OK] Oh My Posh installed successfully." -ForegroundColor Green
    } else {
        Write-Host "[!!] Oh My Posh installed but not found in PATH. Restart your terminal and re-run this script." -ForegroundColor Red
        exit 1
    }
}

# --- 2. Install Nerd Font ---
Write-Host "`n[..] Installing $FontName Nerd Font..." -ForegroundColor Yellow
try {
    oh-my-posh font install $FontName
    Write-Host "[OK] $FontName Nerd Font installed." -ForegroundColor Green
} catch {
    Write-Host "[!!] Font installation failed: $_" -ForegroundColor Red
    Write-Host "     You can install manually from https://www.nerdfonts.com/font-downloads" -ForegroundColor Yellow
}

# --- 3. Copy theme ---
$themesDir = Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\themes"
if (-not (Test-Path $themesDir)) {
    # Fallback for different install locations
    $poshPath = (Get-Command oh-my-posh).Source | Split-Path
    $themesDir = Join-Path $poshPath "themes"
}
if (-not (Test-Path $themesDir)) {
    New-Item -ItemType Directory -Path $themesDir -Force | Out-Null
}
$themeDest = Join-Path $themesDir $themeName
Copy-Item $themeSource $themeDest -Force
Write-Host "[OK] Theme copied to: $themeDest" -ForegroundColor Green

# --- 4. Configure PowerShell profile ---
$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$initLine = 'oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/BenCustomised.omp.json" | Invoke-Expression'

if (Test-Path $PROFILE) {
    $profileContent = Get-Content $PROFILE -Raw
    if ($profileContent -match "oh-my-posh init") {
        Write-Host "[OK] Profile already contains Oh My Posh init. Skipping." -ForegroundColor Green
    } else {
        Add-Content -Path $PROFILE -Value "`n# Oh My Posh prompt`n$initLine"
        Write-Host "[OK] Added Oh My Posh init to profile: $PROFILE" -ForegroundColor Green
    }
} else {
    Set-Content -Path $PROFILE -Value "# Oh My Posh prompt`n$initLine"
    Write-Host "[OK] Created profile with Oh My Posh init: $PROFILE" -ForegroundColor Green
}

# --- Done ---
Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host @"

Next steps:
  1. Restart your terminal
  2. Set your terminal font to "$FontName Nerd Font" (or "CaskaydiaCove NF"):
     - Windows Terminal: Settings > Profiles > Defaults > Appearance > Font face
     - VS Code: Settings > Terminal > Integrated: Font Family

"@ -ForegroundColor White
