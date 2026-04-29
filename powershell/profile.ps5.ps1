# ~/.dotfiles/powershell/profile.ps5.ps1
# PowerShell 5 specific profile: sets TLS 1.2, loads shared profile, and marks environment.

# Ensure TLS 1.2 for PS5 sessions
[Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor
    [Net.SecurityProtocolType]::Tls12

. "$HOME\.dotfiles\powershell\profile.ps1"
$env:POWERSHELL_DISTRIBUTION = "PS5"
