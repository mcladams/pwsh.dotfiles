# ~/.dotfiles/powershell/profile.pwsh7.ps1
# PowerShell 7 specific profile: loads shared profile and marks environment.

. "$HOME\.dotfiles\powershell\profile.ps1"
$env:POWERSHELL_DISTRIBUTION = "Pwsh7"
