#Requires -RunAsAdministrator
# Requires fd.exe (install with scoop or winget)
#
# Block-Outgoing.ps1
#
# Provides the no-callhome function, which blocks outbound access for specific executables or all executables within a directory.
# If sourced, only functions and variables are loaded.
# If executed, the function runs with supplied arguments.
#
# v. 1.0.0 - linted and refactored and tested

function Block-Outgoing {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]  # Ensuring path validity upfront
        [string[]]$Path
    )

    foreach ($item in $Path) {
        try {
            if (Test-Path -Path $item -PathType Leaf) {
                # If it's a file, apply firewall rule directly
                New-NetFirewallRule -DisplayName "Block $item" -Direction Outbound -Action Block -Program $item -ErrorAction Stop
                Write-Verbose "Blocked outbound access for $item"
            }
            elseif (Test-Path -Path $item -PathType Container) {
                # If it's a directory, find executables using `fd` and block them
                $executables = fd -tx . $item
                foreach ($exe in $executables) {
                    New-NetFirewallRule -DisplayName "Block $exe" -Direction Outbound -Action Block -Program $exe -ErrorAction Stop
                    Write-Verbose "Blocked outbound access for $exe"
                }
            }
            else {
                Write-Warning "Invalid path: $item"
            }
        }
        catch {
            Write-Error "Failed to block outbound access for $item - $($_.Exception.Message)"
        }
    }
}

# Handling execution vs sourcing logic
if ($MyInvocation.InvocationName -eq '.') {
    Write-Verbose "Function Block-Outgoing loaded into session."
} else {
    Write-Verbose "Executed: Running primary function."
    Block-Outgoing @Args
}
