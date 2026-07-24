[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [string]$OutputDirectory,

    [switch]$NoRestore
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
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

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

if (-not $NoRestore) {
    & dotnet restore $solutions[0].FullName
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet restore failed with exit code $LASTEXITCODE."
    }
}

# Add repository-specific packaging tests before this call when they are required.
& dotnet pack $solutions[0].FullName `
    --configuration $Configuration `
    --no-restore `
    --output $OutputDirectory `
    -p:ContinuousIntegrationBuild=true
if ($LASTEXITCODE -ne 0) {
    throw "dotnet pack failed with exit code $LASTEXITCODE."
}

[pscustomobject]@{
    Repository = Split-Path $repositoryRoot -Leaf
    Solution = $solutions[0].Name
    Configuration = $Configuration
    OutputDirectory = $OutputDirectory
}
