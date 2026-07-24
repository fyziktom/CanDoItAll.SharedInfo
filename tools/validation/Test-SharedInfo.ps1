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
    'docs/standards/docker.md',
    'docs/inventory/2026-07-24-docker-baseline.md',
    'templates/repository/docker/.dockerignore',
    'templates/repository/docker/.env.example',
    'templates/repository/docker/compose.yaml',
    'templates/repository/docker/compose.override.yaml.example',
    'templates/repository/docker/compose.production.yaml.example',
    'templates/repository/docker/Dockerfile.dotnet',
    'templates/repository/docker/README.md',
    'templates/repository/dotnet/Directory.Build.props',
    'templates/repository/tools/validation/Test-Docker.ps1',
    'codex/skills/apply-candoitall-shared-standards/SKILL.md',
    'codex/skills/apply-candoitall-shared-standards/agents/openai.yaml',
    'codex/skills/apply-candoitall-shared-standards/references/standards-map.md',
    'codex/skills/apply-candoitall-shared-standards/scripts/Find-CanDoItAllSharedInfo.ps1',
    'tools/deployment/nugets/Invoke-CanDoItAllNuGetBuilds.ps1',
    'tools/deployment/nugets/tests/Test-Invoke-CanDoItAllNuGetBuilds.ps1',
    'tools/install/codex/Install-CodexSkills.ps1',
    'tools/install/repositories/Clone-CanDoItAllRepositories.ps1',
    'tools/inventory/Get-CanDoItAllRepositoryInventory.ps1',
    'tools/validation/Test-DockerConventions.ps1'
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

$packageHomepageChecks = @(
    [pscustomobject]@{
        Path = 'docs/standards/nuget-packaging.md'
        RequiredText = @(
            'https://aicandoitall.com',
            'PackageProjectUrl',
            'RepositoryUrl'
        )
    },
    [pscustomobject]@{
        Path = 'templates/repository/dotnet/Directory.Build.props'
        RequiredText = @(
            'https://aicandoitall.com',
            'PackageProjectUrl'
        )
    },
    [pscustomobject]@{
        Path = (
            'codex/skills/apply-candoitall-shared-standards/' +
            'references/standards-map.md'
        )
        RequiredText = @(
            'https://aicandoitall.com',
            'PackageProjectUrl',
            'RepositoryUrl'
        )
    }
)
foreach ($packageHomepageCheck in $packageHomepageChecks) {
    $packageHomepagePath = Join-Path $repositoryRoot $packageHomepageCheck.Path
    if (-not (Test-Path -LiteralPath $packageHomepagePath -PathType Leaf)) {
        continue
    }

    $packageHomepageContents = Get-Content -Raw -LiteralPath $packageHomepagePath
    foreach ($requiredText in $packageHomepageCheck.RequiredText) {
        if (-not $packageHomepageContents.Contains($requiredText)) {
            Add-Failure (
                "NuGet homepage contract text '$requiredText' is missing from " +
                "$($packageHomepageCheck.Path)."
            )
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

        $frontmatterContents = $frontmatter.Groups['yaml'].Value
        $frontmatterLines = @($frontmatterContents -split '\r?\n')
        $frontmatterValues = @{}
        foreach ($frontmatterLine in $frontmatterLines) {
            if ([string]::IsNullOrWhiteSpace($frontmatterLine) -or
                $frontmatterLine.TrimStart().StartsWith('#')) {
                continue
            }

            $fieldMatch = [regex]::Match(
                $frontmatterLine,
                '^(?<field>[a-z][a-z0-9_-]*):\s*(?<value>.*)$'
            )
            if (-not $fieldMatch.Success) {
                Add-Failure (
                    "Skill frontmatter supports only single-line name and description fields: " +
                    "$($skillFile.FullName)"
                )
                continue
            }

            $fieldName = $fieldMatch.Groups['field'].Value
            if ($fieldName -notin @('name', 'description')) {
                Add-Failure (
                    "Unsupported skill frontmatter field '$fieldName' in $($skillFile.FullName)."
                )
                continue
            }
            if ($frontmatterValues.ContainsKey($fieldName)) {
                Add-Failure (
                    "Duplicate skill frontmatter field '$fieldName' in $($skillFile.FullName)."
                )
                continue
            }

            $fieldValue = $fieldMatch.Groups['value'].Value.Trim()
            if ($fieldValue.Length -ge 2 -and
                (($fieldValue.StartsWith('"') -and $fieldValue.EndsWith('"')) -or
                    ($fieldValue.StartsWith("'") -and $fieldValue.EndsWith("'")))) {
                $fieldValue = $fieldValue.Substring(1, $fieldValue.Length - 2)
            }
            $frontmatterValues[$fieldName] = $fieldValue.Trim()
        }

        if (-not $frontmatterValues.ContainsKey('name') -or
            [string]::IsNullOrWhiteSpace($frontmatterValues['name'])) {
            Add-Failure "Skill has no name: $($skillFile.FullName)"
            continue
        }
        if (-not $frontmatterValues.ContainsKey('description') -or
            [string]::IsNullOrWhiteSpace($frontmatterValues['description'])) {
            Add-Failure "Skill has no description: $($skillFile.FullName)"
        }

        $skillName = $frontmatterValues['name']
        if ($skillName.Length -gt 64 -or
            $skillName -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
            Add-Failure (
                "Skill name '$skillName' must be at most 64 lowercase letters, numbers, " +
                "and single hyphens."
            )
        }
        if ($skillFile.Directory.Name -ne $skillName) {
            Add-Failure "Skill folder '$($skillFile.Directory.Name)' does not match '$skillName'."
        }
        if ($seenSkillNames.ContainsKey($skillName)) {
            Add-Failure "Duplicate skill name '$skillName'."
        }
        else {
            $seenSkillNames[$skillName] = $skillFile.FullName
        }

        if ($contents -match '(?im)^\s*\[TODO(?::|\])') {
            Add-Failure "Skill still contains scaffold TODO text: $($skillFile.FullName)"
        }

        $agentPath = Join-Path $skillFile.Directory.FullName 'agents\openai.yaml'
        if (Test-Path -LiteralPath $agentPath -PathType Leaf) {
            $agentContents = Get-Content -Raw -LiteralPath $agentPath
            if ($agentContents -notmatch '(?m)^interface:\s*$') {
                Add-Failure "Skill agent metadata has no interface block: $agentPath"
            }

            $interfaceValues = @{}
            foreach ($interfaceField in @(
                'display_name',
                'short_description',
                'default_prompt'
            )) {
                $interfaceMatch = [regex]::Match(
                    $agentContents,
                    "(?m)^  $interfaceField" +
                    ":\s*(?<quoted>`"(?:[^`"\\]|\\.)*`"|'(?:[^']|'')*')\s*$"
                )
                if (-not $interfaceMatch.Success) {
                    Add-Failure (
                        "Skill agent metadata must contain quoted interface.$interfaceField`: " +
                        $agentPath
                    )
                    continue
                }

                $quotedValue = $interfaceMatch.Groups['quoted'].Value
                $interfaceValue = $quotedValue.Substring(1, $quotedValue.Length - 2)
                if ($quotedValue.StartsWith("'")) {
                    $interfaceValue = $interfaceValue.Replace("''", "'")
                }
                $interfaceValues[$interfaceField] = $interfaceValue
            }

            if ($interfaceValues.ContainsKey('display_name') -and
                [string]::IsNullOrWhiteSpace($interfaceValues['display_name'])) {
                Add-Failure "Skill agent display_name is empty: $agentPath"
            }
            if ($interfaceValues.ContainsKey('short_description')) {
                $shortDescriptionLength = $interfaceValues['short_description'].Length
                if ($shortDescriptionLength -lt 25 -or $shortDescriptionLength -gt 64) {
                    Add-Failure (
                        "Skill agent short_description must be 25-64 characters " +
                        "($shortDescriptionLength found): $agentPath"
                    )
                }
            }
            if ($interfaceValues.ContainsKey('default_prompt') -and
                $interfaceValues['default_prompt'] -notmatch
                    [regex]::Escape("`$$skillName")) {
                Add-Failure (
                    "Skill agent default_prompt must mention `$$skillName`: $agentPath"
                )
            }
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

            foreach ($declarationName in @('mcpServers', 'apps')) {
                $declaration = $manifest.PSObject.Properties[$declarationName]
                if (-not $declaration) {
                    continue
                }

                $declaredPaths = @()
                if ($declaration.Value -is [string]) {
                    $declaredPaths += [string]$declaration.Value
                }
                elseif ($declaration.Value -is [System.Collections.IEnumerable]) {
                    foreach ($declaredValue in $declaration.Value) {
                        if ($declaredValue -is [string]) {
                            $declaredPaths += [string]$declaredValue
                        }
                        elseif ($declaredValue.PSObject.Properties['path']) {
                            $declaredPaths += [string]$declaredValue.path
                        }
                    }
                }
                elseif ($declaration.Value.PSObject.Properties['path']) {
                    $declaredPaths += [string]$declaration.Value.path
                }

                foreach ($declaredPath in $declaredPaths) {
                    if ([string]::IsNullOrWhiteSpace($declaredPath)) {
                        Add-Failure (
                            "Plugin '$($plugin.Name)' declares an empty $declarationName path."
                        )
                        continue
                    }

                    $resolvedDeclaredPath = if (
                        [System.IO.Path]::IsPathRooted($declaredPath)
                    ) {
                        [System.IO.Path]::GetFullPath($declaredPath)
                    }
                    else {
                        [System.IO.Path]::GetFullPath(
                            (Join-Path $plugin.FullName $declaredPath)
                        )
                    }
                    if (-not (Test-Path -LiteralPath $resolvedDeclaredPath)) {
                        Add-Failure (
                            "Plugin '$($plugin.Name)' declares missing " +
                            "$declarationName path '$declaredPath'."
                        )
                    }
                }
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

$marketplacePath = Join-Path $repositoryRoot 'codex\marketplace.json'
if (Test-Path -LiteralPath $marketplacePath -PathType Leaf) {
    try {
        $marketplace = Get-Content -Raw -LiteralPath $marketplacePath | ConvertFrom-Json
        foreach ($marketplacePlugin in @($marketplace.plugins)) {
            if (-not $marketplacePlugin.name) {
                Add-Failure 'Marketplace contains a plugin with no name.'
                continue
            }
            if (-not $marketplacePlugin.source -or
                $marketplacePlugin.source.source -ne 'local' -or
                -not $marketplacePlugin.source.path) {
                continue
            }

            $marketplaceSource = [System.IO.Path]::GetFullPath(
                (Join-Path (Split-Path -Parent $marketplacePath) $marketplacePlugin.source.path)
            )
            if (-not (Test-Path -LiteralPath $marketplaceSource -PathType Container)) {
                Add-Failure (
                    "Marketplace plugin '$($marketplacePlugin.name)' has missing local " +
                    "source '$($marketplacePlugin.source.path)'."
                )
            }
        }
    }
    catch {
        Add-Failure "Cannot validate marketplace plugin sources: $($_.Exception.Message)"
    }
}

$dockerValidatorPath = Join-Path $repositoryRoot 'tools\validation\Test-DockerConventions.ps1'
$dockerTemplatePath = Join-Path $repositoryRoot 'templates\repository\docker'
if ((Test-Path -LiteralPath $dockerValidatorPath -PathType Leaf) -and
    (Test-Path -LiteralPath $dockerTemplatePath -PathType Container)) {
    try {
        $dockerTemplateResult = & $dockerValidatorPath `
            -RepositoryPath $dockerTemplatePath `
            -ComposeFile 'compose.yaml' `
            -EnvFile '.env.example' `
            -TemplateMode
        if ($dockerTemplateResult.FailureCount -gt 0) {
            Add-Failure (
                "Shared Docker template has $($dockerTemplateResult.FailureCount) " +
                'effective Docker convention failure(s).'
            )
        }

        $productionEnvironment = [ordered]@{
            PRODUCTION_API_IMAGE = (
                'registry.example.invalid/candoitall-sample-api:1.0.0@sha256:' +
                ('a' * 64)
            )
            PRODUCTION_POSTGRES_IMAGE = 'postgres:17-alpine@sha256:' + ('b' * 64)
            DB_PASSWORD_FILE = Join-Path (
                Join-Path $dockerTemplatePath '.validation'
            ) 'db-password'
            DB_VOLUME_NAME = 'candoitall-sample-validation-db-data'
        }
        $previousEnvironment = @{}
        try {
            foreach ($entry in $productionEnvironment.GetEnumerator()) {
                $previousEnvironment[$entry.Key] = [Environment]::GetEnvironmentVariable(
                    $entry.Key,
                    [EnvironmentVariableTarget]::Process
                )
                [Environment]::SetEnvironmentVariable(
                    $entry.Key,
                    $entry.Value,
                    [EnvironmentVariableTarget]::Process
                )
            }

            $dockerProductionResult = & $dockerValidatorPath `
                -RepositoryPath $dockerTemplatePath `
                -ComposeFile @('compose.yaml', 'compose.production.yaml.example') `
                -EnvFile '.env.example' `
                -TemplateMode `
                -Production
            if ($dockerProductionResult.FailureCount -gt 0) {
                Add-Failure (
                    "Shared production Docker template has " +
                    "$($dockerProductionResult.FailureCount) effective convention failure(s)."
                )
            }
        }
        finally {
            foreach ($entry in $previousEnvironment.GetEnumerator()) {
                [Environment]::SetEnvironmentVariable(
                    $entry.Key,
                    $entry.Value,
                    [EnvironmentVariableTarget]::Process
                )
            }
        }
    }
    catch {
        Add-Failure "Shared Docker template validation failed: $($_.Exception.Message)"
    }
}

$nugetTestPath = Join-Path (
    $repositoryRoot
) 'tools\deployment\nugets\tests\Test-Invoke-CanDoItAllNuGetBuilds.ps1'
if (Test-Path -LiteralPath $nugetTestPath -PathType Leaf) {
    try {
        $nugetTestLiteral = "'$($nugetTestPath.Replace("'", "''"))'"
        $nugetChildCommand = @"
`$ErrorActionPreference = 'Stop'
try {
    & $nugetTestLiteral | ConvertTo-Json -Compress
    exit 0
}
catch {
    [Console]::Error.WriteLine(`$_.Exception.ToString())
    exit 1
}
"@
        $nugetEncodedCommand = [Convert]::ToBase64String(
            [Text.Encoding]::Unicode.GetBytes($nugetChildCommand)
        )
        $nugetStartInfo = [Diagnostics.ProcessStartInfo]::new()
        $nugetStartInfo.FileName = (Get-Process -Id $PID).Path
        $nugetStartInfo.Arguments = (
            "-NoLogo -NoProfile -NonInteractive -EncodedCommand $nugetEncodedCommand"
        )
        $nugetStartInfo.UseShellExecute = $false
        $nugetStartInfo.CreateNoWindow = $true
        $nugetStartInfo.RedirectStandardOutput = $true
        $nugetStartInfo.RedirectStandardError = $true

        $nugetProcess = [Diagnostics.Process]::new()
        $nugetProcess.StartInfo = $nugetStartInfo
        try {
            if (-not $nugetProcess.Start()) {
                throw 'PowerShell did not start for NuGet orchestration regression tests.'
            }
            $nugetStandardOutputTask = $nugetProcess.StandardOutput.ReadToEndAsync()
            $nugetStandardErrorTask = $nugetProcess.StandardError.ReadToEndAsync()
            $nugetProcess.WaitForExit()
            $nugetStandardOutput = $nugetStandardOutputTask.GetAwaiter().GetResult()
            $nugetStandardError = $nugetStandardErrorTask.GetAwaiter().GetResult()
            if ($nugetProcess.ExitCode -ne 0) {
                throw (
                    "NuGet regression child process exited with code " +
                    "$($nugetProcess.ExitCode): $($nugetStandardError.Trim())"
                )
            }
        }
        finally {
            $nugetProcess.Dispose()
        }

        $nugetResultJson = @(
            $nugetStandardOutput -split '\r?\n' |
                Where-Object { $_.Trim() -match '^\{.*\}$' }
        ) | Select-Object -Last 1
        if (-not $nugetResultJson) {
            throw 'NuGet regression child process returned no JSON result.'
        }
        $nugetTestResult = $nugetResultJson | ConvertFrom-Json
        if (-not $nugetTestResult -or
            $nugetTestResult.Status -ne 'Passed' -or
            $nugetTestResult.AssertionCount -lt 1) {
            Add-Failure 'NuGet orchestration regression tests did not report a passing result.'
        }
    }
    catch {
        Add-Failure "NuGet orchestration regression tests failed: $($_.Exception.Message)"
    }
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
