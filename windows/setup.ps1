# Windows dotfiles setup script
# Run as: .\setup.ps1

$ErrorActionPreference = "Stop"
$DotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Setting up dotfiles on Windows..." -ForegroundColor Cyan

# Ensure scripts can run (RemoteSigned allows local scripts, blocks unsigned downloads)
$Policy = Get-ExecutionPolicy -Scope CurrentUser
if ($Policy -eq "Restricted" -or $Policy -eq "Undefined") {
    Write-Host "Setting execution policy to RemoteSigned for current user..." -ForegroundColor Yellow
    Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
    Write-Host "Execution policy set to RemoteSigned" -ForegroundColor Green
}

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

# Install FiraCode Nerd Font
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-Host "Installing FiraCode Nerd Font..." -ForegroundColor Yellow
    oh-my-posh font install FiraCode
    Write-Host "FiraCode Nerd Font installed" -ForegroundColor Green
}

# Set FiraCode Nerd Font as default in Windows Terminal
$WtSettingsPath = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $WtSettingsPath) {
    $WtSettings = Get-Content $WtSettingsPath -Raw | ConvertFrom-Json
    if (-not $WtSettings.profiles.defaults) {
        $WtSettings.profiles | Add-Member -NotePropertyName "defaults" -NotePropertyValue @{} -Force
    }
    $FontObj = [PSCustomObject]@{ face = "FiraCode Nerd Font" }
    $WtSettings.profiles.defaults | Add-Member -NotePropertyName "font" -NotePropertyValue $FontObj -Force
    $WtSettings | ConvertTo-Json -Depth 10 | Set-Content $WtSettingsPath -Encoding UTF8
    Write-Host "Set FiraCode Nerd Font as default in Windows Terminal" -ForegroundColor Green
}

# Link PowerShell profile for both PS 5 and PS 7
$ProfileSource = Join-Path $DotfilesDir "Microsoft.PowerShell_profile.ps1"
$ProfilePaths = @(
    Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    Join-Path $env:USERPROFILE "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
)
foreach ($ProfilePath in $ProfilePaths) {
    $ProfileDir = Split-Path -Parent $ProfilePath
    if (-not (Test-Path $ProfileDir)) {
        New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    }
    if (Test-Path $ProfilePath) {
        $Backup = "$ProfilePath.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Write-Host "Backing up existing profile to $Backup" -ForegroundColor Yellow
        Move-Item $ProfilePath $Backup
    }
    $Label = "PowerShell profile ($(Split-Path -Leaf (Split-Path -Parent $ProfilePath)))"
    Link-File -Source $ProfileSource -Destination $ProfilePath -Label $Label
}

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

# Git config — prompt for user identity, generate .gitconfig with include
Write-Host ""
Write-Host "Setting up git configuration..." -ForegroundColor Cyan
$GitConfigSource = Join-Path (Split-Path $DotfilesDir) "git\gitconfig"
$GitConfigDest = Join-Path $env:USERPROFILE ".gitconfig"

$CurrentName = git config --global user.name 2>$null
$CurrentEmail = git config --global user.email 2>$null

if ($CurrentName) {
    $GitName = Read-Host "Git user name [$CurrentName]"
    if (-not $GitName) { $GitName = $CurrentName }
} else {
    $GitName = Read-Host "Git user name"
    while (-not $GitName) { $GitName = Read-Host "Git user name (required)" }
}

if ($CurrentEmail) {
    $GitEmail = Read-Host "Git user email [$CurrentEmail]"
    if (-not $GitEmail) { $GitEmail = $CurrentEmail }
} else {
    $GitEmail = Read-Host "Git user email"
    while (-not $GitEmail) { $GitEmail = Read-Host "Git user email (required)" }
}

if (Test-Path $GitConfigDest) {
    $Backup = "$GitConfigDest.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Write-Host "Backing up existing .gitconfig to $Backup" -ForegroundColor Yellow
    Move-Item $GitConfigDest $Backup
}

@"
[include]
    path = $GitConfigSource
[user]
    name = $GitName
    email = $GitEmail
"@ | Set-Content $GitConfigDest -Encoding UTF8
Write-Host "Git configured as: $GitName <$GitEmail>" -ForegroundColor Green

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green

if ($script:UsedCopy) {
    Write-Host ""
    Write-Host "Tip: Enable Developer Mode in Windows Settings > System > For developers" -ForegroundColor Cyan
    Write-Host "     to allow symlinks without admin. Then re-run this script." -ForegroundColor Cyan
}
