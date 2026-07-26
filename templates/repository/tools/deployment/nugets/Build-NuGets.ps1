<#
.SYNOPSIS
Restores and packs the repository's NuGet packages.

.PARAMETER Configuration
Build configuration. The default is Release.

.PARAMETER OutputDirectory
Absolute or repository-relative package destination.

.PARAMETER NoRestore
Skips restore when the caller guarantees it has already completed.

.PARAMETER Version
Overrides the package version without editing committed project files.

.EXAMPLE
.\tools\deployment\nugets\Build-NuGets.ps1 -Version '1.2.3'
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [string]$OutputDirectory,

    [switch]$NoRestore,

    [string]$Version = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$effectiveVersion = $Version.Trim()
$msbuildProperties = @()
if (-not [string]::IsNullOrWhiteSpace($effectiveVersion)) {
    $msbuildProperties += "-p:Version=$effectiveVersion"
}

if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $repositoryRoot 'artifacts\packages'
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory = Join-Path $repositoryRoot $OutputDirectory
}

$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$solutions = @(
    Get-ChildItem -LiteralPath $repositoryRoot -File |
        Where-Object { $_.Extension -in @('.sln', '.slnx') } |
        Sort-Object Name
)

if ($solutions.Count -ne 1) {
    throw "Expected one canonical root solution, found $($solutions.Count). Customize this adapter to select the repository's packaging solution."
}

$operation = if ($NoRestore) {
    'Pack'
}
else {
    'Restore and pack'
}
$versionDescription = if ([string]::IsNullOrWhiteSpace($effectiveVersion)) {
    'using the committed package version'
}
else {
    "at package version '$effectiveVersion'"
}
if (-not $PSCmdlet.ShouldProcess(
        $OutputDirectory,
        "$operation NuGet packages $versionDescription from '$($solutions[0].FullName)'"
    )) {
    [pscustomobject]@{
        Repository = Split-Path $repositoryRoot -Leaf
        Solution = $solutions[0].Name
        Configuration = $Configuration
        PackageVersion = $effectiveVersion
        OutputDirectory = $OutputDirectory
        Status = 'Preview'
    }
    return
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

if (-not $NoRestore) {
    $restoreArguments = @(
        'restore',
        $solutions[0].FullName
    ) + $msbuildProperties
    & dotnet @restoreArguments
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet restore failed with exit code $LASTEXITCODE."
    }
}

# Add repository-specific packaging tests before this call when they are required.
$packArguments = @(
    'pack',
    $solutions[0].FullName,
    '--configuration', $Configuration,
    '--no-restore',
    '--output', $OutputDirectory,
    '-p:ContinuousIntegrationBuild=true'
) + $msbuildProperties
& dotnet @packArguments
if ($LASTEXITCODE -ne 0) {
    throw "dotnet pack failed with exit code $LASTEXITCODE."
}

[pscustomobject]@{
    Repository = Split-Path $repositoryRoot -Leaf
    Solution = $solutions[0].Name
    Configuration = $Configuration
    PackageVersion = $effectiveVersion
    OutputDirectory = $OutputDirectory
    Status = 'Succeeded'
}
