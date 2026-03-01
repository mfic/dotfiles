# Windows dotfiles setup script
# Run as: .\setup.ps1

$ErrorActionPreference = "Stop"
$DotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Setting up dotfiles on Windows..." -ForegroundColor Cyan

# Symlink helper — falls back to copy if not running as admin / Developer Mode off
function Link-File {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Label
    )
    try {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -Force | Out-Null
        Write-Host "Linked $Label" -ForegroundColor Green
    } catch [System.UnauthorizedAccessException] {
        Copy-Item -Path $Source -Destination $Destination -Force
        Write-Host "Copied $Label (symlink requires admin or Developer Mode)" -ForegroundColor Yellow
        $script:UsedCopy = $true
    }
}
$script:UsedCopy = $false

# Install oh-my-posh if not present
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Host "Installing oh-my-posh..." -ForegroundColor Yellow
    winget install JanDeDobbeleer.OhMyPosh -s winget
    Write-Host "oh-my-posh installed. You may need to restart your terminal." -ForegroundColor Green
}

# Create PowerShell profile directory if needed
$ProfileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

# Link PowerShell profile
$ProfileSource = Join-Path $DotfilesDir "Microsoft.PowerShell_profile.ps1"
if (Test-Path $PROFILE) {
    $Backup = "$PROFILE.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Write-Host "Backing up existing profile to $Backup" -ForegroundColor Yellow
    Move-Item $PROFILE $Backup
}
Link-File -Source $ProfileSource -Destination $PROFILE -Label "PowerShell profile"

# Vim config
$VimrcSource = Join-Path (Split-Path $DotfilesDir) "vim\vimrc"
$VimrcDest = Join-Path $env:USERPROFILE "_vimrc"
if (Test-Path $VimrcDest) {
    $Backup = "$VimrcDest.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Move-Item $VimrcDest $Backup
}
Link-File -Source $VimrcSource -Destination $VimrcDest -Label "_vimrc"

# Neovim config
$NvimDir = Join-Path $env:LOCALAPPDATA "nvim"
if (-not (Test-Path $NvimDir)) {
    New-Item -ItemType Directory -Path $NvimDir -Force | Out-Null
}
$NvimSource = Join-Path (Split-Path $DotfilesDir) "nvim\init.vim"
$NvimDest = Join-Path $NvimDir "init.vim"
if (Test-Path $NvimDest) {
    $Backup = "$NvimDest.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Move-Item $NvimDest $Backup
}
Link-File -Source $NvimSource -Destination $NvimDest -Label "nvim/init.vim"

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green

if ($script:UsedCopy) {
    Write-Host ""
    Write-Host "Tip: Enable Developer Mode in Windows Settings > System > For developers" -ForegroundColor Cyan
    Write-Host "     to allow symlinks without admin. Then re-run this script." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Recommended: Install a Nerd Font for oh-my-posh icons:" -ForegroundColor Cyan
Write-Host "  oh-my-posh font install" -ForegroundColor White
Write-Host "  Then set it as your terminal font in Windows Terminal settings." -ForegroundColor White
