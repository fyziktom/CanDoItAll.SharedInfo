[CmdletBinding()]
param(
    [string]$StartPath = (Get-Location).Path,

    [switch]$AsObject
)

$ErrorActionPreference = 'Stop'

function Test-SharedInfoRoot {
    param([string]$Candidate)

    if (-not $Candidate) {
        return $false
    }

    $fullPath = [System.IO.Path]::GetFullPath($Candidate)
    return (
        (Test-Path -LiteralPath (Join-Path $fullPath 'AGENTS.md') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $fullPath 'docs/standards') -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $fullPath 'templates/repository') -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $fullPath 'tools/validation/Test-SharedInfo.ps1') -PathType Leaf)
    )
}

$resolvedStart = (Resolve-Path -LiteralPath $StartPath).Path
if (Test-Path -LiteralPath $resolvedStart -PathType Leaf) {
    $resolvedStart = Split-Path -Parent $resolvedStart
}

$candidates = [System.Collections.Generic.List[object]]::new()
if ($env:CANDOITALL_SHAREDINFO_ROOT) {
    $candidates.Add([pscustomobject]@{
        Path = $env:CANDOITALL_SHAREDINFO_ROOT
        Source = 'CANDOITALL_SHAREDINFO_ROOT'
    })
}

$cursor = [System.IO.DirectoryInfo]::new($resolvedStart)
while ($cursor) {
    if ($cursor.Name -eq 'CanDoItAll.SharedInfo') {
        $candidates.Add([pscustomobject]@{
            Path = $cursor.FullName
            Source = 'current ancestor'
        })
    }

    $candidates.Add([pscustomobject]@{
        Path = Join-Path $cursor.FullName 'CanDoItAll.SharedInfo'
        Source = 'child of current ancestor'
    })

    if ($cursor.Parent) {
        $candidates.Add([pscustomobject]@{
            Path = Join-Path $cursor.Parent.FullName 'CanDoItAll.SharedInfo'
            Source = 'sibling of current ancestor'
        })
    }

    $cursor = $cursor.Parent
}

$seen = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)
foreach ($candidate in $candidates) {
    $fullPath = [System.IO.Path]::GetFullPath($candidate.Path)
    if (-not $seen.Add($fullPath)) {
        continue
    }
    if (-not (Test-SharedInfoRoot -Candidate $fullPath)) {
        continue
    }

    $result = [pscustomobject]@{
        Root = $fullPath
        Source = $candidate.Source
    }
    if ($AsObject) {
        $result
    }
    else {
        $result.Root
    }
    return
}

throw @"
Could not locate CanDoItAll.SharedInfo from '$resolvedStart'.
Set CANDOITALL_SHAREDINFO_ROOT to a valid clone or place the repository beside the target repository.
"@
