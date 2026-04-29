# ~/.dotfiles/setup.ps1
# One-off bootstrap: requires Administrator; installs/configures Scoop, core apps, modules, and writes profile stubs.

$ErrorActionPreference = 'Stop'

# Ensure TLS 1.2 for any web calls (important for PS5 sessions)
[Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor
    [Net.SecurityProtocolType]::Tls12

# Helper: write status
function Write-Status { param($msg,$color='White') Write-Host $msg -ForegroundColor $color }

# 1. Admin check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Status "CRITICAL: This setup script requires Administrator privileges." Red
    Write-Status "Run PowerShell as Administrator and re-run: & '$HOME\.dotfiles\setup.ps1'" Yellow
    exit 1
}
Write-Status "Administrator privileges confirmed." Green

# 2. Small safe executor
function Invoke-Safely {
    param([scriptblock]$Script, [string]$Description)
    try {
        & $Script
        Write-Status "[OK] $Description" Green
        return $true
    } catch {
        Write-Status "[FAIL] $Description" Red
        Write-Status $_.Exception.Message DarkRed
        return $false
    }
}

# 3. Execution policy (system-wide for the machine; required for some installers)
Invoke-Safely { Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force } "Set ExecutionPolicy LocalMachine:RemoteSigned"

# 4. SSH Agent: ensure service exists before touching it
$sshSvc = Get-Service -Name ssh-agent -ErrorAction SilentlyContinue
if ($null -ne $sshSvc) {
    if ($sshSvc.StartType -ne 'Automatic') {
        Invoke-Safely { Set-Service -Name ssh-agent -StartupType Automatic } "Set ssh-agent StartupType Automatic"
    }
    if ($sshSvc.Status -ne 'Running') {
        Invoke-Safely { Start-Service -Name ssh-agent } "Start ssh-agent service"
    }
} else {
    Write-Status "ssh-agent service not present; skipping service configuration." Yellow
}

# 5. Ensure network connectivity (simple check)
try {
    $null = (Invoke-WebRequest -Uri 'https://www.microsoft.com' -UseBasicParsing -TimeoutSec 10)
    Write-Status "Network check OK" Green
} catch {
    Write-Status "Network check failed. Some installs may not work. Proceeding anyway." Yellow
}

# 6. Install Scoop if missing (per-user install is fine; we still run as admin for other tasks)
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Status "Installing Scoop (per-user)..." Cyan
    # Use Process scope for the download step to avoid policy conflicts
    Invoke-Safely {
        Set-ExecutionPolicy RemoteSigned -Scope Process -Force
        Invoke-Expression (Invoke-RestMethod -UseBasicParsing -Uri 'https://get.scoop.sh')
    } "Install Scoop"
} else {
    Write-Status "Scoop already installed." Green
}

# 7. Configure Scoop for speed and reliability (if available)
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    $scoopConfigOps = @(
        @{k='aria2-enabled'; v='true'},
        @{k='aria2-max-connection-per-server'; v='16'},
        @{k='aria2-split'; v='16'},
        @{k='aria2-min-split-size'; v='1M'},
        @{k='aria2-retry-wait'; v='2'},
        @{k='aria2-retries'; v='10'},
        @{k='aria2-warning-enabled'; v='false'},
        @{k='use_sqlite_cache'; v='true'},
        @{k='use_search_cache'; v='true'},
        @{k='parallel_update'; v='true'},
        @{k='rm_old_versions'; v='true'},
        @{k='use_lessmsi'; v='true'}
    )
    foreach ($op in $scoopConfigOps) {
        Invoke-Safely { scoop config $($op.k) $($op.v) } "scoop config $($op.k)=$($op.v)"
    }

    # Add common buckets
    Invoke-Safely { scoop bucket add main } "scoop bucket add main"
    Invoke-Safely { scoop bucket add extras } "scoop bucket add extras"
    Invoke-Safely { scoop bucket add nerd-fonts } "scoop bucket add nerd-fonts"
} else {
    Write-Status "Scoop not available; skipping scoop configuration." Yellow
}

# 8. Install core packages via Scoop (prefer scoop; fallback to winget if scoop missing)
$packages = @('git','pwsh','oh-my-posh','notepadplusplus')
foreach ($pkg in $packages) {
    if (Get-Command $pkg -ErrorAction SilentlyContinue) {
        Write-Status "$pkg already available in PATH." Green
        continue
    }
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Invoke-Safely { scoop install $pkg } "scoop install $pkg"
    } else {
        # fallback to winget if available
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Invoke-Safely { winget install --id $pkg --silent --accept-package-agreements --accept-source-agreements } "winget install $pkg"
        } else {
            Write-Status "Neither scoop nor winget available to install $pkg." Yellow
        }
    }
}

# 9. PowerShell Gallery and modules (install for CurrentUser; non-interactive)
Invoke-Safely { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser } "Install NuGet provider"
Invoke-Safely { Install-Module -Name CompletionPredictor -Scope CurrentUser -Force -AllowClobber } "Install CompletionPredictor"
Invoke-Safely { Install-Module -Name PSReadLine -Scope CurrentUser -Force -AllowClobber } "Install PSReadLine"

# 10. Ensure powershell profile directories and write safe stubs
function New-ProfileStub {
    param([string]$TargetProfilePath, [string]$RepoScriptPath)
    $ProfileDir = Split-Path -Parent $TargetProfilePath
    if (-not (Test-Path $ProfileDir)) {
      New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
      }
    $StubContent = @"
# $RepoScriptPath (stub loader)
# Loads the repository profile script.
if (Test-Path "$RepoScriptPath") {
    . "$RepoScriptPath"
} else {
    Write-Host "Profile script not found at $RepoScriptPath" -ForegroundColor Yellow
}
"@
    Invoke-Safely { $StubContent | Set-Content -Path $TargetProfilePath -Encoding UTF8 } "Write profile stub to $TargetProfilePath"
}

# PS5 system profile path (system location)
$ps5ProfilePath = 'C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1'
$repoPs5 = Join-Path $HOME '.dotfiles\powershell\profile.ps5.ps1'
New-ProfileStub -TargetProfilePath $ps5ProfilePath -RepoScriptPath $repoPs5

# Pwsh7 user profile path (PowerShell default location)
$pwshProfileDir = Join-Path $HOME 'Documents\PowerShell'
$pwshProfilePath = Join-Path $pwshProfileDir 'Microsoft.PowerShell_profile.ps1'
$repoPwsh = Join-Path $HOME '.dotfiles\powershell\profile.pwsh7.ps1'
New-ProfileStub -TargetProfilePath $pwshProfilePath -RepoScriptPath $repoPwsh

Write-Status "Bootstrap finished. Please open a new PowerShell session (pwsh) to verify." Cyan
