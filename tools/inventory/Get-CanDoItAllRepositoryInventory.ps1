[CmdletBinding()]
param(
    [string]$RepositoriesRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,

    [string]$ManifestPath = (Resolve-Path (Join-Path $PSScriptRoot '..\..\config\repositories.json')).Path,

    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'

$RepositoriesRoot = [System.IO.Path]::GetFullPath($RepositoriesRoot)
if (-not (Test-Path -LiteralPath $RepositoriesRoot -PathType Container)) {
    throw "Repositories root does not exist: $RepositoriesRoot"
}

$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$nugetEntryPoint = [string]$manifest.contracts.nugetBuildEntryPoint
$validationEntryPoint = [string]$manifest.contracts.repositoryValidationEntryPoint

$rows = foreach ($repository in $manifest.repositories) {
    $path = Join-Path $RepositoriesRoot $repository.name
    $exists = Test-Path -LiteralPath $path -PathType Container

    $solutions = @()
    $skillCount = 0
    if ($exists) {
        $solutions = @(
            Get-ChildItem -LiteralPath $path -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -in @('.sln', '.slnx') }
        )
        $skillRoots = @(
            'codex\skills',
            '.codex\skills',
            'skills',
            'tools\AI\cfo_financial_management_skills_pack\skills'
        )
        $skillFiles = foreach ($skillRoot in $skillRoots) {
            $candidate = Join-Path $path $skillRoot
            if (Test-Path -LiteralPath $candidate -PathType Container) {
                Get-ChildItem -LiteralPath $candidate -Filter 'SKILL.md' -File -Recurse -Force -ErrorAction SilentlyContinue |
                    Where-Object { $_.FullName -notmatch '[\\/](tests|fixtures)[\\/]' }
            }
        }
        $skillCount = @($skillFiles | Sort-Object FullName -Unique).Count
    }

    [pscustomobject]@{
        Repository = [string]$repository.name
        Exists = $exists
        GitRepository = $exists -and (Test-Path -LiteralPath (Join-Path $path '.git'))
        Readme = $exists -and (Test-Path -LiteralPath (Join-Path $path 'README.md'))
        EditorConfig = $exists -and (Test-Path -LiteralPath (Join-Path $path '.editorconfig'))
        GlobalJson = $exists -and (Test-Path -LiteralPath (Join-Path $path 'global.json'))
        SolutionCount = $solutions.Count
        NuGetCompatible = $exists -and (Test-Path -LiteralPath (Join-Path $path $nugetEntryPoint))
        ValidationCompatible = $exists -and (Test-Path -LiteralPath (Join-Path $path $validationEntryPoint))
        SkillCount = $skillCount
        Path = $path
    }
}

if ($AsJson) {
    $rows | ConvertTo-Json -Depth 4
}
else {
    $rows
}
