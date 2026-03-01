# PowerShell profile — oh-my-posh + Docker aliases

# oh-my-posh prompt (robbyrussell theme to match zsh)
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ThemesPath = $env:POSH_THEMES_PATH
    if (-not $ThemesPath) {
        $ThemesPath = Join-Path (Split-Path (Get-Command oh-my-posh).Source) "themes"
    }
    $ThemeFile = Join-Path $ThemesPath "robbyrussell.omp.json"
    if (Test-Path $ThemeFile) {
        oh-my-posh init pwsh --config $ThemeFile | Invoke-Expression
    } else {
        oh-my-posh init pwsh | Invoke-Expression
    }
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
