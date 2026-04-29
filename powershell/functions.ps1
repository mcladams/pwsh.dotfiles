# ~/.dotfiles/powershell/functions.ps1
# Utility functions sourced by profile.ps1.

function Update-Profile {
    Write-Host "Reloading profile from $PROFILE..." -ForegroundColor Cyan
    . $PROFILE
}
Set-Alias -Name reload-profile -Value Update-Profile

function which {
    Get-Command @args
}
