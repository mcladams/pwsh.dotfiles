function conf { git.exe --git-dir="$HOME\.conf.git\" --work-tree=$HOME $args }

function restore {
    # git restore items staged for deletion to the work-tree
    # mainly for newly cloned bare repository with git-dir=*.git
    $gitdir = (Get-ChildItem -Directory -Filter "*.git").Name
    $status_D = $(git --git-dir=$gitdir --work-tree=. status --short | grep 'D  ').substring(3)
    foreach ($file in $status_D) {
        git --git-dir=$gitdir  --work-tree=. restore $file --staged --worktree
    }
}
function mtime {
    param (
        [ScriptBlock]$Command
    )
    
    $executionTime = [math]::round((Measure-Command {
        & $Command
    }).TotalSeconds, 2)
    
    Write-Output "`t`t`t$executionTime s"
}
# dot-functions.ps1
# source this in the nomal way to use the functions and add to $PROFILE

# Recursively take ownership and set owner with full permissions
function Own-Full-Perms {
    param ( [string]$_path )

    takeown /F "$_path" /R /D Y /SKIPSL >$null 
    icacls "$_path" /grant:r ${env:USERNAME}:F /T /L /C /Q
}

# Measure execution time of a scriptblock and return seconds
function mtime {
    param (
        [ScriptBlock]$Command
    )
    
    $executionTime = [math]::round((Measure-Command {
        & $Command
    }).TotalSeconds, 2)
    
    Write-Output "`t`t`t$executionTime s"
}

function IsAdmin {
    $IsAdmininstrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($IsAdmininstrator) {
        Write-Output "The PowerShell session is running with elevated privileges (as Administrator)."
    } else {
        Write-Output "The PowerShell session is not running with elevated privileges."
    }
}

# Frequent robocopy options
function robosync { robocopy $args /E /ZB /SJ /SL /COPYALL /DCOPY:DATE /MT /R:1 /W:0 /NS /NC /NFL /NDL /ETA }
function robosync-noown { robocopy $args /E /ZB /SJ /SL /COPY:DAT /DCOPY:DAT /MT /R:1 /W:0 /NS /NC /NFL /NDL /ETA }
function robosync-purge { robocopy $args /E /PURGE /ZB /SJ /SL /COPYALL /DCOPY:DATE /MT /R:1 /W:0 /NS /NC /NFL /NDL /ETA }

# ZFS functions
function zls { zfs.exe list -o name,used,available,referenced,overlay,canmount,mounted,driveletter,mountpoint $args }
