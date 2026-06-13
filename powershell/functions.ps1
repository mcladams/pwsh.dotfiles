# ~/.dotfiles/powershell/functions.ps1
# Utility functions sourced by profile.ps1.

function Update-Profile {
    Write-Host "Reloading profile from $PROFILE..." -ForegroundColor Cyan
    . $PROFILE
}
Set-Alias -Name reload-profile -Value Update-Profile

# This not required as which provided from scoop package either busybox / gow / coreutils
# function which {
#    Get-Command @args
# }

function gemini-cli {
    node "C:\Users\Mike\source\repos\mcladams\kali-gemini-cli\scripts\start.js" @args
}
Set-Alias -Name gemini -Value gemini-cli
