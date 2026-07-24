[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $script:failures.Add($Message)
}

$requiredPaths = @(
    'README.md',
    'AGENTS.md',
    '.editorconfig',
    '.gitattributes',
    '.gitignore',
    'config/repositories.json',
    'codex/marketplace.json',
    'docs/architecture/source-of-truth.md',
    'docs/standards/repository-layout.md',
    'docs/standards/documentation.md',
    'docs/standards/git.md',
    'docs/standards/dotnet.md',
    'docs/standards/tooling.md',
    'docs/standards/nuget-packaging.md',
    'docs/standards/codex.md',
    'tools/deployment/nugets/Invoke-CanDoItAllNuGetBuilds.ps1',
    'tools/install/codex/Install-CodexSkills.ps1',
    'tools/install/repositories/Clone-CanDoItAllRepositories.ps1',
    'tools/inventory/Get-CanDoItAllRepositoryInventory.ps1'
)

foreach ($relativePath in $requiredPaths) {
    if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot $relativePath))) {
        Add-Failure "Missing required path: $relativePath"
    }
}

foreach ($relativePath in @('config/repositories.json', 'codex/marketplace.json')) {
    $path = Join-Path $repositoryRoot $relativePath
    if (Test-Path -LiteralPath $path) {
        try {
            Get-Content -Raw -LiteralPath $path | ConvertFrom-Json | Out-Null
        }
        catch {
            Add-Failure "Invalid JSON in $relativePath`: $($_.Exception.Message)"
        }
    }
}

$skillRoot = Join-Path $repositoryRoot 'codex\skills'
if (Test-Path -LiteralPath $skillRoot) {
    $seenSkillNames = @{}
    $skillFiles = @(
        Get-ChildItem -LiteralPath $skillRoot -Filter 'SKILL.md' -File -Recurse -Force |
            Where-Object { $_.FullName -notmatch '[\\/](tests|fixtures)[\\/]' }
    )

    foreach ($skillFile in $skillFiles) {
        $contents = Get-Content -Raw -LiteralPath $skillFile.FullName
        $frontmatter = [regex]::Match(
            $contents,
            '\A---\r?\n(?<yaml>.*?)\r?\n---',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
        if (-not $frontmatter.Success) {
            Add-Failure "Skill has invalid frontmatter: $($skillFile.FullName)"
            continue
        }

        $nameMatch = [regex]::Match(
            $frontmatter.Groups['yaml'].Value,
            '(?m)^name:\s*["'']?(?<name>[^"''\r\n]+)'
        )
        if (-not $nameMatch.Success) {
            Add-Failure "Skill has no name: $($skillFile.FullName)"
            continue
        }

        $skillName = $nameMatch.Groups['name'].Value.Trim()
        if ($skillFile.Directory.Name -ne $skillName) {
            Add-Failure "Skill folder '$($skillFile.Directory.Name)' does not match '$skillName'."
        }
        if ($seenSkillNames.ContainsKey($skillName)) {
            Add-Failure "Duplicate skill name '$skillName'."
        }
        else {
            $seenSkillNames[$skillName] = $skillFile.FullName
        }
    }

    if ($skillFiles.Count -eq 0) {
        Add-Failure 'No Codex skills found.'
    }
}
else {
    Add-Failure 'Missing codex/skills.'
}

$powerShellFiles = @(
    Get-ChildItem -LiteralPath $repositoryRoot -Filter '*.ps1' -File -Recurse -Force |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }
)
foreach ($powerShellFile in $powerShellFiles) {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $powerShellFile.FullName,
        [ref]$tokens,
        [ref]$parseErrors
    ) | Out-Null
    foreach ($parseError in $parseErrors) {
        Add-Failure "PowerShell parse error in $($powerShellFile.FullName): $($parseError.Message)"
    }
}

$markdownFiles = @(
    Get-ChildItem -LiteralPath $repositoryRoot -Filter '*.md' -File -Recurse -Force |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }
)
foreach ($markdownFile in $markdownFiles) {
    $contents = Get-Content -Raw -LiteralPath $markdownFile.FullName
    $links = [regex]::Matches($contents, '\[[^\]]*\]\((?<target>[^)]+)\)')
    foreach ($link in $links) {
        $rawTarget = $link.Groups['target'].Value.Trim().Trim('<', '>')
        if ($rawTarget -match '^(https?://|mailto:|#)' -or $rawTarget -match '\$\{') {
            continue
        }

        $relativeTarget = ($rawTarget -split '#', 2)[0]
        if (-not $relativeTarget) {
            continue
        }

        $resolvedTarget = [System.IO.Path]::GetFullPath(
            (Join-Path $markdownFile.DirectoryName $relativeTarget)
        )
        if (-not (Test-Path -LiteralPath $resolvedTarget)) {
            $source = $markdownFile.FullName.Substring($repositoryRoot.Length + 1)
            Add-Failure "Missing relative Markdown link from '$source' to '$rawTarget'."
        }
    }
}

$pluginRoot = Join-Path $repositoryRoot 'codex\plugins'
if (Test-Path -LiteralPath $pluginRoot) {
    foreach ($plugin in Get-ChildItem -LiteralPath $pluginRoot -Directory) {
        $manifestPath = Join-Path $plugin.FullName '.codex-plugin\plugin.json'
        if (-not (Test-Path -LiteralPath $manifestPath)) {
            Add-Failure "Plugin '$($plugin.Name)' has no .codex-plugin/plugin.json."
            continue
        }

        try {
            $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
            if ($manifest.name -ne $plugin.Name) {
                Add-Failure "Plugin folder '$($plugin.Name)' does not match manifest name '$($manifest.name)'."
            }
        }
        catch {
            Add-Failure "Invalid plugin manifest for '$($plugin.Name)': $($_.Exception.Message)"
        }
    }
}
else {
    Add-Failure 'Missing codex/plugins.'
}

[pscustomobject]@{
    Repository = $repositoryRoot
    SkillCount = if (Test-Path -LiteralPath $skillRoot) { $skillFiles.Count } else { 0 }
    MarkdownFileCount = $markdownFiles.Count
    PowerShellFileCount = $powerShellFiles.Count
    FailureCount = $failures.Count
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "SharedInfo validation failed with $($failures.Count) error(s)."
}
