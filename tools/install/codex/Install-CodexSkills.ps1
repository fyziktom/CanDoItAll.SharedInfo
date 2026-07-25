[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$CodexHome = $(if ($env:CODEX_HOME) {
        $env:CODEX_HOME
    }
    else {
        Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex'
    }),

    [ValidatePattern('^_?[a-z0-9][a-z0-9_-]*$')]
    [string[]]$PackageName,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$sourceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\codex\skills')).Path
$targetRoot = [System.IO.Path]::GetFullPath((Join-Path $CodexHome 'skills'))
$targetPrefix = $targetRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

if ($targetRoot.Equals($sourceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'The Codex installation root cannot be the maintained skill source directory.'
}

if (Test-Path -LiteralPath $targetRoot) {
    $targetRootItem = Get-Item -LiteralPath $targetRoot -Force
    if (($targetRootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Refusing a Codex skill root that is a reparse point: $targetRoot"
    }
}

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

if ($PackageName) {
    $requestedNames = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($name in $PackageName) {
        $requestedNames.Add($name) | Out-Null
    }

    $availableNames = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($package in $packages) {
        $availableNames.Add($package.Name) | Out-Null
    }

    $missingNames = @(
        foreach ($name in $requestedNames) {
            if (-not $availableNames.Contains($name)) {
                $name
            }
        }
    )
    if ($missingNames.Count -gt 0) {
        throw "Unknown Codex package(s): $($missingNames -join ', ')"
    }

    $packages = @(
        $packages |
            Where-Object { $requestedNames.Contains($_.Name) }
    )
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
            $targetItem = Get-Item -LiteralPath $targetPath -Force
            if (($targetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Refusing to replace a reparse-point package target: $targetPath"
            }
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
