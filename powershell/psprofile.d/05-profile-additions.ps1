# powershell profile for dotconf git; use 'conf' not 'git' in $env:USERPROFILE
function conf { git --git-dir=$env:USERPROFILE\.conf.git --work-tree=$env:USERPROFILE $args }

# aliases
  Set-Alias -Name npp -Value "$env:PROGRAMFILES\Notepad++\notepad++.exe"
  # prevent conf rm removing from working tree
  Set-Alias -Name "conf rm" -Value "conf rm --cached"

# something from pshazz module for loading ssh agent or keys
try { $null = gcm pshazz -ea stop; pshazz init } catch { }

# script to update scoop weekly
if (Get-Command scoop 2> $null) {
  $doUpdate = $true;
  $now = [int]$(Get-Date -UFormat %s);
  if ($lastupdate = Get-Content "$env:LOCALAPPDATA\last-scoop-update-timestamp" 2> $null) {
    if ( ([int]$lastupdate + (7 * 24 * 60 * 60)) -gt ($now) ) {
      $doUpdate = $false
    }
  }
  if ($doUpdate) {
    scoop update;
    sudo scoop update -a -g;
    sudo scoop cleanup -a -g;
    $now > "$env:LOCALAPPDATA\last-scoop-update-timestamp";
  }
}

Import-Module C:\'Program Files'\PowerToys\WinGetCommandNotFound.psd1
