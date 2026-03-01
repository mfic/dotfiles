# Windows dotfiles setup script
# Run as: .\setup.ps1

$ErrorActionPreference = "Stop"
$DotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Setting up dotfiles on Windows..." -ForegroundColor Cyan

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
New-Item -ItemType SymbolicLink -Path $PROFILE -Target $ProfileSource -Force | Out-Null
Write-Host "Linked PowerShell profile" -ForegroundColor Green

# Vim config
$VimrcSource = Join-Path (Split-Path $DotfilesDir) "vim\vimrc"
$VimrcDest = Join-Path $env:USERPROFILE "_vimrc"
if (Test-Path $VimrcDest) {
    $Backup = "$VimrcDest.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Move-Item $VimrcDest $Backup
}
New-Item -ItemType SymbolicLink -Path $VimrcDest -Target $VimrcSource -Force | Out-Null
Write-Host "Linked _vimrc" -ForegroundColor Green

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
New-Item -ItemType SymbolicLink -Path $NvimDest -Target $NvimSource -Force | Out-Null
Write-Host "Linked nvim/init.vim" -ForegroundColor Green

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Recommended: Install a Nerd Font for oh-my-posh icons:" -ForegroundColor Cyan
Write-Host "  oh-my-posh font install" -ForegroundColor White
Write-Host "  Then set it as your terminal font in Windows Terminal settings." -ForegroundColor White
