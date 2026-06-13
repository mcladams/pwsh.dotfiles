#!C:\Program\Files\PowerShell\7\pwsh.exe
#
# dotPShelpers.ps1 helpful functions to be sourced by $PROFILE
# (dot.. means don't directly run it)

function q-alias ($cmdletname) {
    # Query Alias: find an existing PS alias or maybe define a new one
	# Check if the cmdlet exists
    $cmdlet = Get-Command -Name $cmdletname -ErrorAction SilentlyContinue
    if (-not $cmdlet) {
        Write-Host "The cmdlet '$cmdletname' does not exist."
        # Suggest similar cmdlets
        $similarCmdlets = Get-Command -Name "*$cmdletname*" -ErrorAction SilentlyContinue
        if ($similarCmdlets) {
            Write-Host "Did you mean one of these?"
            $similarCmdlets | Format-Table -Property Name -AutoSize
        } else {
            Write-Host "No similar cmdlets found."
        }
        return
    }
    
    # Find existing aliases for the cmdlet
    $aliases = Get-Alias | Where-Object -FilterScript { $_.Definition -eq $cmdletname }
    if ($aliases) {
        $aliases | Format-Table -Property Definition, Name -AutoSize
    } else {
        Write-Host "There are no aliases defined for '$cmdletname'."
        # Prompt the user to define a new alias
        $input = Read-Host "Would you like to set one? If so type 'y' followed by space and your alias, anything else exits"
        if ($input -match "^y\s+(.+)$") {
            $newAlias = $matches[1]
            New-Alias -Name $newAlias -Value $cmdletname
            Write-Host "Alias '$newAlias' has been created for '$cmdletname'."
        } else {
            Write-Host "Exiting without creating an alias."
        }
    }
}
