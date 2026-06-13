# Source this file to load the helper functions

function Limit-LongString {
    param(
        [string]$String,
        [int]$NoLines = 1
    )

    ($String -split "`n" | Select-Object -First $NoLines) -join "`n"
}


function Format-ModuleGalleryMetadata {
    param(
        [Parameter(Mandatory)]
        $Meta
    )

    $sizeMB = if ($Meta.packageSize) {
        [math]::Round($Meta.packageSize / 1MB, 2)
    } else { 0 }

    $published = if ($Meta.published) {
        (Get-Date $Meta.published).ToString("yyyy-MM-dd HH:mm")
    }

    $updated = if ($Meta.lastUpdated) {
        (Get-Date $Meta.lastUpdated).ToString("yyyy-MM-dd HH:mm")
    }

    @"
┌───────────────────────────────────────────────────────────────
│   PSGallery Metadata Summary
├───────────────────────────────────────────────────────────────
│   Module Name        : $($Meta.Name)
│   Version            : $($Meta.NormalizedVersion)
│   Size               : $sizeMB MB
│
│   First Published    : $published
│   Last Updated       : $updated
│
│   Total Downloads    : $($Meta.downloadCount)
│   Version Downloads  : $($Meta.versionDownloadCount)
└───────────────────────────────────────────────────────────────
"@
}


function Get-ModuleInsight {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [Alias('Name')]
        $Module,

        [switch]$v,
        [switch]$v1,
        [switch]$vv,
        [switch]$v2,
        [switch]$vvv,
        [switch]$v3
    )

    begin {
        # Normalize verbosity
        $Verbosity = switch ($true) {
            { $v3 -or $vvv } { 3; break }
            { $v2 -or $vv }  { 2; break }
            { $v1 -or $v }   { 1; break }
            default          { 1 }
        }

        $results = @()
    }

    process {
        # Normalize module input
        $name = switch ($Module) {
            { $_ -is [string] } { $_ }
            { $_ -is [System.Management.Automation.PSModuleInfo] } { $_.Name }
            default { $_.ToString() }
        }

        if (-not $name) {
            Write-Warning "Skipping empty module name"
            return
        }

        # Try to fetch PSGallery metadata (may be null)
        $gallery = Find-Module -Name $name -ErrorAction SilentlyContinue

        # Basic metadata
        $meta = [ordered]@{
            Name        = $name
            Description = $gallery.Description
            Published   = $gallery.PublishedDate
            Updated     = $gallery.UpdatedDate
            Downloads   = $gallery.DownloadCount
        }

        # Verbosity 2 → include command table
        if ($Verbosity -ge 2) {
            $meta.Commands = Get-Command -Module $name |
                Where-Object { $_.CommandType -ne 'Alias' } |
                Select-Object Name, CommandType, Parameters
        }

        # Verbosity 3 → full metadata scraper
        if ($Verbosity -ge 3) {
            $meta.FullMetadata = Get-Command -Module $name |
                Where-Object { $_.CommandType -ne 'Alias' } |
                ForEach-Object {
                    $help = $null
                    try { $help = Get-Help $_.Name -Full -ErrorAction Stop } catch {}

                    [pscustomobject]@{
                        Name          = $_.Name
                        Parameters    = $_.Parameters
                        ParameterSets = $_.ParameterSets
                        ReturnType    = $_.ReturnType
                        HelpInputs    = $help | Select-String 'INPUTS'  | ForEach-Object Line
                        HelpOutputs   = $help | Select-String 'OUTPUTS' | ForEach-Object Line
                        Examples      = $help.Examples
                    }
                }
        }

        $results += [pscustomobject]$meta
    }

    end {
        $results
    }
}
