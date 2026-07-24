[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$RepositoriesRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path,

    [string[]]$Repository = @('CanDoItAll*'),

    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path 'artifacts\packages'),

    [switch]$NoRestore,

    [switch]$FailOnMissing,

    [switch]$StopOnFailure
)

$ErrorActionPreference = 'Stop'

$entryPointRelativePath = 'tools\deployment\nugets\Build-NuGets.ps1'
$RepositoriesRoot = [System.IO.Path]::GetFullPath($RepositoriesRoot)
$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)

if (-not (Test-Path -LiteralPath $RepositoriesRoot -PathType Container)) {
    throw "Repositories root does not exist: $RepositoriesRoot"
}

$directories = @(
    Get-ChildItem -LiteralPath $RepositoriesRoot -Directory |
        Where-Object { $_.Name -like 'CanDoItAll*' } |
        Sort-Object Name
)

$results = [System.Collections.Generic.List[object]]::new()
$failed = $false
$missing = $false

foreach ($directory in $directories) {
    $selected = $false
    foreach ($pattern in $Repository) {
        if ($directory.Name -like $pattern) {
            $selected = $true
            break
        }
    }

    if (-not $selected) {
        continue
    }

    $entryPoint = Join-Path $directory.FullName $entryPointRelativePath
    if (-not (Test-Path -LiteralPath $entryPoint -PathType Leaf)) {
        $missing = $true
        $results.Add([pscustomobject]@{
            Repository = $directory.Name
            Status = 'NotCompatible'
            OutputDirectory = $null
            Message = "Missing $entryPointRelativePath"
        })
        continue
    }

    $repositoryOutput = Join-Path $OutputRoot $directory.Name
    if (-not $PSCmdlet.ShouldProcess($directory.FullName, "Build NuGet packages into '$repositoryOutput'")) {
        $results.Add([pscustomobject]@{
            Repository = $directory.Name
            Status = 'Preview'
            OutputDirectory = $repositoryOutput
            Message = $entryPoint
        })
        continue
    }

    try {
        & $entryPoint `
            -Configuration $Configuration `
            -OutputDirectory $repositoryOutput `
            -NoRestore:$NoRestore

        $results.Add([pscustomobject]@{
            Repository = $directory.Name
            Status = 'Succeeded'
            OutputDirectory = $repositoryOutput
            Message = $entryPoint
        })
    }
    catch {
        $failed = $true
        $results.Add([pscustomobject]@{
            Repository = $directory.Name
            Status = 'Failed'
            OutputDirectory = $repositoryOutput
            Message = $_.Exception.Message
        })

        if ($StopOnFailure) {
            break
        }
    }
}

$results

if ($failed) {
    throw 'One or more repository NuGet builds failed.'
}
if ($missing -and $FailOnMissing) {
    throw 'One or more selected repositories do not implement the shared NuGet build entry point.'
}
