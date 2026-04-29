# ~/.dotfiles/powershell/profile.ps1
# Shared profile logic (PS5/Pwsh7): defines aliases, editor, prompt, loads utilities and PSReadLine.

# ll and la: show files and directories in a readable format
function ll { Get-ChildItem @args | Sort-Object -Property PSIsContainer, Name }
function la { Get-ChildItem -Force @args | Sort-Object -Property PSIsContainer, Name }

# Editor preference
$env:EDITOR = "notepad++"

# Load utility functions
$fn = "$HOME\.dotfiles\powershell\functions.ps1"
if (Test-Path $fn) { . $fn }

# Load PSReadLine customizations (separate file)
$psrl = "$HOME\.dotfiles\powershell\psreadline.ps1"
if (Test-Path $psrl) { . $psrl }

# Initialize oh-my-posh if available; fallback to default theme if custom theme missing
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ThemePath = "$HOME\.dotfiles\powershell\kali.omp.json"
    if (Test-Path $ThemePath) {
        oh-my-posh init pwsh --config $ThemePath | Invoke-Expression
    } else {
        # fallback to a built-in theme name (safe)
        try {
            oh-my-posh init pwsh --config 'paradox' | Invoke-Expression
        } catch {
            Write-Host "oh-my-posh available but failed to init theme; continuing with default prompt." -ForegroundColor Yellow
        }
    }
}
