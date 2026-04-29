#!\\C:\Program Files\PowerShell\7\pwsh.exe
# PS_functions.ps1 - custom functions sourced by $PROFILE

function pstime() {
    param([string[]]$args)
    $command = $args -join ' '
    $measure = Measure-Command { Invoke-Expression $command | Out-Default }
    Write-Output $measure.TotalSeconds
}

function SizeGB() {
    param([int64]$Size)
    return [math]::Round( $Size / 1GB, 2)
}

function CompactVHD {
    param([string]$vxPath)
    $initGB = SizeGB (Get-Item -Path $vxPath).Length
    $vxPath
    Optimize-VHD -Path $vxPath -Mode Full
    $finGB = SizeGB (Get-Item -Path $vxPath).Length
    $compPC = [math]::Round( ($initGB - $finGB) / $initGB * 100, 0)
    Write-Host "Size: $finGB GB, $compPC % additional compression"
}
