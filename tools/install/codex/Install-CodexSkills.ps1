[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$CodexHome = $(if ($env:CODEX_HOME) {
        $env:CODEX_HOME
    }
    else {
        Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex'
    }),

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$sourceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\codex\skills')).Path
$targetRoot = [System.IO.Path]::GetFullPath((Join-Path $CodexHome 'skills'))
$targetPrefix = $targetRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

$skillDirectories = @(
    Get-ChildItem -LiteralPath $sourceRoot -Filter 'SKILL.md' -File -Recurse -Force |
        Where-Object {
            $_.FullName -notmatch '[\\/](tests|fixtures)[\\/]'
        } |
        ForEach-Object { $_.Directory } |
        Sort-Object FullName -Unique
)

$packages = @()
$seenNames = @{}
foreach ($directory in $skillDirectories) {
    $skillFile = Join-Path $directory.FullName 'SKILL.md'
    $nameLine = Select-String -LiteralPath $skillFile -Pattern '^name:\s*(.+)$' | Select-Object -First 1
    if (-not $nameLine) {
        throw "Skill has no name in frontmatter: $skillFile"
    }

    $skillName = $nameLine.Matches[0].Groups[1].Value.Trim().Trim('"').Trim("'")
    if ($directory.Name -ne $skillName) {
        throw "Skill folder '$($directory.Name)' does not match skill name '$skillName'."
    }
    if ($seenNames.ContainsKey($skillName)) {
        throw "Duplicate skill name '$skillName': $($seenNames[$skillName]); $($directory.FullName)"
    }

    $seenNames[$skillName] = $directory.FullName
    $packages += [pscustomobject]@{
        Name = $skillName
        Source = $directory.FullName
        Kind = 'Skill'
    }
}

$supportDirectories = @(
    Get-ChildItem -LiteralPath $sourceRoot -Directory -Force |
        Where-Object {
            $_.Name.StartsWith('_', [System.StringComparison]::Ordinal) -and
            -not (Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md'))
        }
)
foreach ($directory in $supportDirectories) {
    $packages += [pscustomobject]@{
        Name = $directory.Name
        Source = $directory.FullName
        Kind = 'Support'
    }
}

$results = foreach ($package in ($packages | Sort-Object Name)) {
    $targetPath = [System.IO.Path]::GetFullPath((Join-Path $targetRoot $package.Name))
    if (-not $targetPath.StartsWith($targetPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing target outside Codex skill root: $targetPath"
    }

    if ((Test-Path -LiteralPath $targetPath) -and -not $Force) {
        [pscustomobject]@{
            Name = $package.Name
            Kind = $package.Kind
            Status = 'Existing'
            Target = $targetPath
        }
        continue
    }

    if ($PSCmdlet.ShouldProcess($targetPath, "Install $($package.Kind.ToLowerInvariant()) '$($package.Name)'")) {
        if (-not (Test-Path -LiteralPath $targetRoot)) {
            New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
        }
        if (Test-Path -LiteralPath $targetPath) {
            Remove-Item -LiteralPath $targetPath -Recurse -Force
        }

        Copy-Item -LiteralPath $package.Source -Destination $targetRoot -Recurse -Force
        [pscustomobject]@{
            Name = $package.Name
            Kind = $package.Kind
            Status = 'Installed'
            Target = $targetPath
        }
    }
    else {
        [pscustomobject]@{
            Name = $package.Name
            Kind = $package.Kind
            Status = 'Preview'
            Target = $targetPath
        }
    }
}

$results
