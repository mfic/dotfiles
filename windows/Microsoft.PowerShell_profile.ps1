# PowerShell profile — oh-my-posh + Docker aliases

# oh-my-posh prompt (robbyrussell theme to match zsh)
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $shell = if ($PSVersionTable.PSVersion.Major -ge 6) { 'pwsh' } else { 'powershell' }
    $ThemesPath = $env:POSH_THEMES_PATH
    if (-not $ThemesPath) {
        $ThemesPath = Join-Path (Split-Path (Get-Command oh-my-posh).Source) "themes"
    }
    $ThemeFile = Join-Path $ThemesPath "robbyrussell.omp.json"
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    if (Test-Path $ThemeFile) {
        oh-my-posh init $shell --config $ThemeFile | Invoke-Expression
    }
    else {
        oh-my-posh init $shell | Invoke-Expression
    }
    $ErrorActionPreference = $prevEAP
}

# Docker aliases
function dc { docker compose @args }
function dcu { docker compose up -d @args }
function dcd { docker compose down @args }
function dcl { docker compose logs -f @args }
function dcdu { docker compose down @args; docker compose up -d @args }
function dps { docker ps @args }

# Navigation
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# ls aliases
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force -Hidden @args }

# Convenience
Set-Alias -Name vi -Value vim -ErrorAction SilentlyContinue

# Helper functions to run Docker containers
function Run-Ollama {
    $exists = docker ps -a --format '{{.Names}}' | Select-String -SimpleMatch 'ollama'

    if ($exists) {
        docker start ollama | Out-Null
    }
    else {
        docker run -d `
            --name ollama `
            --restart unless-stopped `
            -v ollama:/root/.ollama `
            -p 127.0.0.1:11434:11434 `
            ollama/ollama | Out-Null
    }
}
## Ollama CLI Helper
function ollama {
    docker start ollama | Out-Null 2>$null
    docker exec -it ollama ollama @args
}

# Update dotfiles repo and re-run the setup script
function Update-Dotfiles {
    $dir = if ($env:DOTFILES) { $env:DOTFILES } else { Join-Path $HOME "dotfiles" }
    if (-not (Test-Path $dir)) {
        Write-Error "Dotfiles directory not found: $dir"
        return
    }

    $changes = git -C $dir status --porcelain
    if ($changes) {
        Write-Host "[info] Uncommitted changes in $dir`:" -ForegroundColor Cyan
        git -C $dir status --short
        Write-Host "[info] Commit or stash your changes before updating." -ForegroundColor Cyan
        return
    }

    Write-Host "[info] Updating dotfiles in $dir..." -ForegroundColor Cyan
    git -C $dir pull
    if ($LASTEXITCODE -eq 0) {
        & (Join-Path $dir "windows\setup.ps1") -SkipGit
    }
}
Set-Alias -Name dfu -Value Update-Dotfiles

# Remove all timestamped dotfiles backup files
function Invoke-DotfilesCleanBackups {
    $found = $false
    Get-ChildItem $HOME -Recurse -Depth 4 -Filter '*.bak.*' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '\.bak\.\d+$' } |
        ForEach-Object {
            Write-Host "Removing $($_.FullName)"
            Remove-Item $_.FullName -Force
            $found = $true
        }
    if (-not $found) { Write-Host "[info] No backup files found." -ForegroundColor Cyan }
}
Set-Alias -Name dfclean -Value Invoke-DotfilesCleanBackups

# Source per-machine overrides
$LocalProfile = Join-Path $HOME "local_profile.ps1"
if (Test-Path $LocalProfile) { . $LocalProfile }

function Run-ItTools {
    $exists = docker ps -a --format '{{.Names}}' | Select-String -SimpleMatch 'it-tools'

    if ($exists) {
        docker start it-tools | Out-Null
    }
    else {
        docker run -d `
            --name it-tools `
            --restart unless-stopped `
            -p 127.0.0.1:8080:80 `
            corentinth/it-tools:latest | Out-Null
    }
}