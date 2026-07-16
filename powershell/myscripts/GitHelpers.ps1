function Invoke-GitPullShallowDir {
    <#
    .SYNOPSIS
        Performs a shallow sparse checkout of a directory from a remote GitHub repository.

    .DESCRIPTION
        Downloads the LICENSE file (if present), performs a sparse checkout of the specified
        directory from the remote GitHub repository, moves the extracted files to the target
        directory, removes Git metadata, and writes a provenance file.

    .PARAMETER RepoUrl
        The HTTPS URL of the GitHub repository.

    .PARAMETER RemoteDir
        The directory path inside the remote repository to extract.

    .PARAMETER TargetDir
        The local directory name to place the extracted files into.
        Defaults to the same name as RemoteDir.

    .EXAMPLE
        Invoke-GitPullShallowDir -RepoUrl "https://github.com/user/repo.git" `
                                 -RemoteDir "skills/windows-wsl-coordination" `
                                 -TargetDir "windows-wsl-coordination"

    .NOTES
        Author: Michael
        Purpose: APM skill extraction with provenance tracking.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepoUrl,

        [Parameter(Mandatory)]
        [string]$RemoteDir,

        [Parameter()]
        [string]$TargetDir
    )

    begin {
        if ([string]::IsNullOrWhiteSpace($TargetDir)) {
            $TargetDir = $RemoteDir
        }

        $rawBase = $RepoUrl -replace '^https://github.com/', '' -replace '\.git$', ''
        $startDir = Get-Location
    }

    process {
        # Create target directory
        New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
        Set-Location $TargetDir

        # --- Fetch LICENSE file ---
        Write-Verbose "Fetching LICENSE files from GitHub..."
        $licenseNames = @("LICENSE", "LICENSE.md", "LICENSE.txt")
        $licenseFound = $false

        foreach ($name in $licenseNames) {
            $url = "https://raw.githubusercontent.com/$rawBase/main/$name"

            try {
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
                $response.Content | Set-Content -Path $name -Encoding UTF8
                Write-Verbose "Retrieved LICENSE file: $name"
                $licenseFound = $true
                break
            }
            catch {
                if (Test-Path $name) { Remove-Item $name -Force }
            }
        }

        if (-not $licenseFound) {
            Write-Warning "No LICENSE file found in remote repository."
        }

        # --- Sparse Git Checkout ---
        git init | Out-Null
        git remote add origin $RepoUrl
        git config core.sparseCheckout true

        ".git/info/sparse-checkout" | Out-Null
        $RemoteDir | Out-File -FilePath ".git/info/sparse-checkout" -Encoding UTF8 -Append

        git fetch --depth=1 --filter=blob:none origin main
        git checkout main

        # --- Move extracted files ---
        $remoteTop = $RemoteDir.Split('/')[0]

        Get-ChildItem -Path $RemoteDir -Force | ForEach-Object {
            Move-Item -Path $_.FullName -Destination .
        }

        if (Test-Path $remoteTop) {
            Remove-Item $remoteTop -Recurse -Force
        }

        Remove-Item .git -Recurse -Force

        # --- Provenance ---
        $provenance = "Folder '$TargetDir' and LICENSE extracted from '$RepoUrl' on $(Get-Date)"
        $provenance | Tee-Object -FilePath ".provenance" -Encoding UTF8
    }

    end {
        Set-Location $startDir
    }
}
