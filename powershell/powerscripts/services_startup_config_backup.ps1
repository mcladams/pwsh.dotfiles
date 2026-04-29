# Description: This script backs up the Windows Services startup configuration to Batch & REG files.
# Converted to PowerShell by Michael C Adams, 14 February 2025

# Forked from visual basic script (.vbs) original by Ramesh Srinivasan after a web search came up with his blog page
# https://www.winhelponline.com/blog/backup-windows-services-configuration/ 

# Ensure the script is running as Administrator
If (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as an Administrator."
    Start-Process -FilePath "PowerShell" -ArgumentList "-NoProfile -WindowStyle Hidden -Command `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Set file names for REG and Batch files
$DateStamp = Get-Date -Format "yyyyMMdd"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RegFile = Join-Path $ScriptDir "svc_curr_state_$DateStamp.reg"
$BatFile = Join-Path $ScriptDir "svc_curr_state_$DateStamp.bat"
$SvcKey = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\"

# Create the REG file header
$RegContent = @"
Windows Registry Editor Version 5.00

; Services Startup Configuration Backup $(Get-Date)

"@

# Create the BAT file header
$BatContent = @"
@echo off
echo Restore Service Startup State saved at $(Get-Date)

"@

$Services = Get-CimInstance -ClassName Win32_Service
$TotalServices = $Services.Count
$PerUserServiceCount = 0
$SkippedServices = @()

foreach ($Service in $Services) {
    $StartMode = $Service.StartMode.ToLower()
    $ServiceName = $Service.Name

    # Handle per-user services
    if ($Service.ServiceType -eq 'Unknown') {
        $TemplateServiceName = $ServiceName.Split('_')[0]
        try {
            $ServiceType = Get-ItemProperty -Path "Registry::$SvcKey$TemplateServiceName" -Name Type -ErrorAction Stop
            if ($ServiceType.Type -in 80, 96) {
                $PerUserServiceCount++
                $ServiceName = $TemplateServiceName
            }
        } catch {
            # Service not found, skip
            continue
        }
    }

    $RegContent += "[$SvcKey$ServiceName]`n"

    # Handle services with spaces in their names
    $QuotedServiceName = if ($ServiceName.Contains(' ')) { "`"$ServiceName`"" } else { $ServiceName }

    switch ($StartMode) {
        'boot' {
            $RegContent += '"Start"=dword:00000000`n'
            $BatContent += "sc.exe config $QuotedServiceName start= boot`n"
        }
        'system' {
            $RegContent += '"Start"=dword:00000001`n'
            $BatContent += "sc.exe config $QuotedServiceName start= system`n"
        }
        'auto' {
            $RegContent += '"Start"=dword:00000002`n'
            if ($Service.DelayedAutoStart) {
                $RegContent += '"DelayedAutostart"=dword:00000001`n'
                $BatContent += "sc.exe config $QuotedServiceName start= delayed-auto`n"
            } else {
                $RegContent += '"DelayedAutostart"=-`n'
                $BatContent += "sc.exe config $QuotedServiceName start= auto`n"
            }
        }
        'manual' {
            $RegContent += '"Start"=dword:00000003`n'
            $BatContent += "sc.exe config $QuotedServiceName start= demand`n"
        }
        'disabled' {
            $RegContent += '"Start"=dword:00000004`n'
            $BatContent += "sc.exe config $QuotedServiceName start= disabled`n"
        }
        default {
            $SkippedServices += $ServiceName
            continue
        }
    }
    $RegContent += "`n"
}

# Write the contents to the REG and BAT files
Set-Content -Path $RegFile -Value $RegContent -Encoding Unicode
$BatContent += "pause`n"
Set-Content -Path $BatFile -Value $BatContent -Encoding ASCII

# Display the summary
if ($SkippedServices.Count -gt 0) {
    Write-Host "$TotalServices - Total # of Services (including $PerUserServiceCount Per-user Services)"
    Write-Host "`nThe following services could not be backed up:`n"
    $SkippedServices | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "$TotalServices Services found (including $PerUserServiceCount Per-user Services) and their startup configuration has been backed up."
}

# Optionally, open the generated files in Notepad
# Invoke-Item $RegFile
# Invoke-Item $BatFile
