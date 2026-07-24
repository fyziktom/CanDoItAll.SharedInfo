[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param(
    [string]$DestinationRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path,

    [string]$ManifestPath = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\config\repositories.json')).Path,

    [string[]]$Repository = @('CanDoItAll*')
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git is required to clone repositories.'
}

$DestinationRoot = [System.IO.Path]::GetFullPath($DestinationRoot)
if (-not (Test-Path -LiteralPath $DestinationRoot -PathType Container)) {
    throw "Destination root does not exist: $DestinationRoot"
}

$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$destinationPrefix = $DestinationRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

$results = foreach ($item in $manifest.repositories) {
    $selected = $false
    foreach ($pattern in $Repository) {
        if ([string]$item.name -like $pattern) {
            $selected = $true
            break
        }
    }

    if (-not $selected) {
        continue
    }

    $targetPath = [System.IO.Path]::GetFullPath((Join-Path $DestinationRoot ([string]$item.name)))
    if (-not $targetPath.StartsWith($destinationPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing target outside destination root: $targetPath"
    }

    if (Test-Path -LiteralPath $targetPath) {
        [pscustomobject]@{
            Repository = [string]$item.name
            Status = 'Existing'
            Path = $targetPath
        }
        continue
    }

    if ($PSCmdlet.ShouldProcess($targetPath, "Clone $($item.cloneUrl)")) {
        & git clone -- ([string]$item.cloneUrl) $targetPath
        if ($LASTEXITCODE -ne 0) {
            throw "git clone failed for $($item.name) with exit code $LASTEXITCODE."
        }

        [pscustomobject]@{
            Repository = [string]$item.name
            Status = 'Cloned'
            Path = $targetPath
        }
    }
    else {
        [pscustomobject]@{
            Repository = [string]$item.name
            Status = 'Preview'
            Path = $targetPath
        }
    }
}

$results
