<#
.SYNOPSIS
Restores and packs the repository's NuGet packages.

.PARAMETER Configuration
Build configuration. The default is Release.

.PARAMETER OutputDirectory
Absolute or repository-relative package destination. When omitted, a
versioned, timestamped run directory is created below artifacts/packages.

.PARAMETER NoRestore
Skips restore when the caller guarantees it has already completed.

.PARAMETER Version
Overrides the package version without editing committed project files.

.PARAMETER CreateRunDirectory
Treats an explicitly supplied OutputDirectory as a root and creates the same
versioned, timestamped child used by the default.

.EXAMPLE
.\tools\deployment\nugets\Build-NuGets.ps1 -Version '1.2.3'
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [string]$OutputDirectory,

    [switch]$NoRestore,

    [string]$Version = '',

    [switch]$CreateRunDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$effectiveVersion = $Version.Trim()
if ([string]::IsNullOrWhiteSpace($effectiveVersion)) {
    $versionCandidates = [System.Collections.Generic.List[string]]::new()
    $directoryBuildPropsPath = Join-Path $repositoryRoot 'Directory.Build.props'
    if (Test-Path -LiteralPath $directoryBuildPropsPath -PathType Leaf) {
        [xml]$directoryBuildProps = Get-Content -LiteralPath $directoryBuildPropsPath -Raw
        foreach ($propertyName in @(
            'CanDoItAllPackageBaseVersion',
            'Version',
            'VersionPrefix',
            'PackageVersion'
        )) {
            foreach ($node in @($directoryBuildProps.SelectNodes(
                "/*[local-name()='Project']/*[local-name()='PropertyGroup']/*[local-name()='$propertyName']"
            ))) {
                $candidate = $node.InnerText.Trim()
                if (-not [string]::IsNullOrWhiteSpace($candidate) -and
                    -not $candidate.Contains('$(')) {
                    $versionCandidates.Add($candidate)
                }
            }
        }
    }

    if ($versionCandidates.Count -eq 0) {
        throw (
            'Cannot determine the committed package version for the run-directory name. ' +
            'Pass -Version or customize this adapter to evaluate the repository version.'
        )
    }

    $effectiveVersion = $versionCandidates[0]
}

$msbuildProperties = @()
if (-not [string]::IsNullOrWhiteSpace($Version)) {
    $msbuildProperties += "-p:Version=$effectiveVersion"
}

if (-not $OutputDirectory) {
    $outputRoot = Join-Path $repositoryRoot 'artifacts\packages'
}
elseif ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    $outputRoot = $OutputDirectory
}
else {
    $outputRoot = Join-Path $repositoryRoot $OutputDirectory
}

$outputRoot = [System.IO.Path]::GetFullPath($outputRoot)
if (-not $OutputDirectory -or $CreateRunDirectory) {
    $runTimestamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
    $OutputDirectory = Join-Path $outputRoot "${effectiveVersion}_$runTimestamp"
}
else {
    $OutputDirectory = $outputRoot
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
$versionDescription = "at package version '$effectiveVersion'"
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
