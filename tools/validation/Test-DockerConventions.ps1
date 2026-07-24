[CmdletBinding()]
param(
    [string]$RepositoryPath = (Get-Location).Path,

    [string[]]$ComposeFile,

    [string]$EnvFile,

    [switch]$TemplateMode,

    [switch]$RequireDocker,

    [switch]$RunBuildChecks,

    [switch]$Production,

    [switch]$WarningsAsErrors
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath $RepositoryPath).Path
$findings = [System.Collections.Generic.List[object]]::new()

function Add-Finding {
    param(
        [ValidateSet('Error', 'Warning')]
        [string]$Severity,

        [string]$Code,

        [string]$Message,

        [string]$Path,

        [int]$Line = 0
    )

    $displayPath = $Path
    if ($Path -and [System.IO.Path]::IsPathRooted($Path)) {
        $pathPrefix = $repositoryRoot.TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar
        ) + [System.IO.Path]::DirectorySeparatorChar
        if ($Path.StartsWith($pathPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $displayPath = $Path.Substring($pathPrefix.Length)
        }
    }

    $script:findings.Add([pscustomobject]@{
        Severity = $Severity
        Code = $Code
        Path = $displayPath
        Line = if ($Line -gt 0) { $Line } else { $null }
        Message = $Message
    })
}

function Resolve-InputPath {
    param(
        [string]$Path,
        [string]$BasePath
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return (Resolve-Path -LiteralPath $Path).Path
    }

    return (Resolve-Path -LiteralPath (Join-Path $BasePath $Path)).Path
}

function Test-ImageReference {
    param(
        [string]$Image,
        [string]$Path,
        [int]$Line
    )

    $literalImage = $Image.Trim().Trim('"').Trim("'")
    if ($literalImage -match '\$\{') {
        return
    }

    if ($literalImage -match '(?i):latest(?:@|$)') {
        Add-Finding Error 'image-latest' "Image '$literalImage' uses the mutable latest tag." $Path $Line
        return
    }

    $hasDigest = $literalImage -match '(?i)@sha256:[0-9a-f]{64}$'
    $withoutDigest = ($literalImage -split '@', 2)[0]
    $lastSegment = ($withoutDigest -split '/')[-1]
    if (-not $hasDigest -and $lastSegment -notmatch ':') {
        Add-Finding Error 'image-unversioned' "Image '$literalImage' has no explicit tag or digest." $Path $Line
    }
}

if (-not $ComposeFile -or $ComposeFile.Count -eq 0) {
    $canonicalCompose = Join-Path $repositoryRoot 'compose.yaml'
    if (Test-Path -LiteralPath $canonicalCompose -PathType Leaf) {
        $ComposeFile = @($canonicalCompose)
    }
    else {
        $legacyNames = @(
            'compose.yml',
            'docker-compose.yaml',
            'docker-compose.yml'
        )
        $legacyPath = $legacyNames |
            ForEach-Object { Join-Path $repositoryRoot $_ } |
            Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
            Select-Object -First 1

        if ($legacyPath) {
            $ComposeFile = @($legacyPath)
            Add-Finding Warning 'compose-filename' (
                "Use canonical 'compose.yaml'; coordinate the rename with deployment tooling."
            ) $legacyPath
        }
        else {
            throw "No Compose file supplied and no root compose.yaml found in '$repositoryRoot'."
        }
    }
}

$resolvedComposeFiles = @(
    foreach ($path in $ComposeFile) {
        Resolve-InputPath -Path $path -BasePath $repositoryRoot
    }
)

$resolvedEnvFile = $null
if ($EnvFile) {
    $resolvedEnvFile = Resolve-InputPath -Path $EnvFile -BasePath $repositoryRoot
}

$usesInterpolation = $false
foreach ($composePath in $resolvedComposeFiles) {
    $lines = @(Get-Content -LiteralPath $composePath)
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        $lineNumber = $index + 1

        if ($line -match '\$\{[A-Za-z_][A-Za-z0-9_]*') {
            $usesInterpolation = $true
        }
        if ($line -match '^version\s*:') {
            Add-Finding Error 'compose-version' 'Remove the obsolete top-level version property.' $composePath $lineNumber
        }
        if ($line -match '^\s+container_name\s*:') {
            Add-Finding Error 'container-name' 'Do not set container_name; use Compose project scoping.' $composePath $lineNumber
        }
        if ($line -match '^\s+privileged\s*:\s*(?:true|["'']true["''])\s*(?:#.*)?$') {
            Add-Finding Error 'privileged' 'Privileged containers require a documented exception and are rejected by the baseline.' $composePath $lineNumber
        }
        if ($line -match '^\s+(?:network_mode|pid)\s*:\s*["'']?host["'']?\s*(?:#.*)?$') {
            Add-Finding Error 'host-namespace' 'Host network or PID namespace is rejected by the baseline.' $composePath $lineNumber
        }
        if ($line -match '(?i)(?:/var/run/docker\.sock|//\./pipe/docker_engine)') {
            Add-Finding Error 'docker-control' 'Do not grant an application access to the Docker daemon socket or pipe.' $composePath $lineNumber
        }
        if ($line -match (
            '^\s+(?<key>[A-Za-z0-9_.-]*(?i:password|passwd|secret|api[_-]?key|' +
            'private[_-]?key|(?:access|auth|bearer|refresh|jwt)[_-]?token|' +
            'token[_-]?(?:secret|key))[A-Za-z0-9_.-]*)\s*:\s*(?<value>[^#]+?)\s*$'
        )) {
            $secretKey = $Matches['key']
            $secretValue = $Matches['value'].Trim().Trim('"').Trim("'")
            $isFileReference = $secretKey -match '(?i)(?:_FILE|File)$'
            $isVariableReference = $secretValue -match '\$\{'
            $hasVariableDefault = $secretValue -match (
                '\$\{[A-Za-z_][A-Za-z0-9_]*(?::-|-)[^}]*\}'
            )
            $isMountedSecret = $secretValue -match '(?i)^/run/secrets/'
            $isMergeDirective = $secretValue -match '^!(?:override|reset)\b'
            if (-not $isFileReference -and
                -not $isMountedSecret -and
                -not $isMergeDirective -and
                $secretValue -and
                (-not $isVariableReference -or $hasVariableDefault)) {
                Add-Finding Error 'committed-secret' (
                    "Secret-like setting '$secretKey' contains a committed value or fallback."
                ) $composePath $lineNumber
            }
        }
        if ($line -match (
            '(?i)(?:password|passwd|pwd|secret|api[_-]?key|private[_-]?key|' +
            '(?:access|auth|bearer|refresh|jwt)[_-]?token|token[_-]?(?:secret|key))\s*='
        ) -and (
            $line -notmatch '\$\{' -or
            $line -match '\$\{[A-Za-z_][A-Za-z0-9_]*(?::-|-)[^}]*\}'
        )) {
            Add-Finding Error 'committed-secret' (
                'A committed configuration value appears to embed a secret.'
            ) $composePath $lineNumber
        }
        if ($line -match '^\s+image\s*:\s*(?<image>[^#]+?)\s*$') {
            Test-ImageReference -Image $Matches['image'] -Path $composePath -Line $lineNumber
        }
    }
}

$toolRoot = Join-Path $repositoryRoot 'tools'
if (Test-Path -LiteralPath $toolRoot -PathType Container) {
    $lifecycleFiles = @(
        Get-ChildItem -LiteralPath $toolRoot -File -Recurse -Force |
            Where-Object { $_.Extension -in @('.ps1', '.sh', '.cmd', '.bat') }
    )
    foreach ($file in $lifecycleFiles) {
        $matches = Select-String -LiteralPath $file.FullName -Pattern (
            '(?i)docker(?:-|\s+)compose\s+down[^\r\n]*(?:--volumes|-v(?:\s|$))'
        )
        foreach ($match in $matches) {
            $isExplicitReset = $file.BaseName -match '(?i)(reset|remove|destroy|purge)'
            if (-not $isExplicitReset) {
                Add-Finding Error 'destructive-stop' (
                    'Volume deletion is allowed only in a separately named destructive reset tool.'
                ) $file.FullName $match.LineNumber
            }
        }
    }
}

if (-not $TemplateMode) {
    $envExample = Join-Path $repositoryRoot '.env.example'
    if ($usesInterpolation -and
        -not (Test-Path -LiteralPath $envExample -PathType Leaf)) {
        Add-Finding Error 'env-contract' (
            'Compose interpolation is used, but the repository has no root .env.example contract.'
        ) $resolvedComposeFiles[0]
    }
    if (Test-Path -LiteralPath $envExample -PathType Leaf) {
        $gitIgnorePath = Join-Path $repositoryRoot '.gitignore'
        if (-not (Test-Path -LiteralPath $gitIgnorePath -PathType Leaf)) {
            Add-Finding Error 'env-ignore' 'A repository with .env.example must have a root .gitignore.' $envExample
        }
        else {
            $gitIgnore = Get-Content -Raw -LiteralPath $gitIgnorePath
            if ($gitIgnore -notmatch '(?m)^\.env(?:\s|$)' -or
                $gitIgnore -notmatch '(?m)^\.env\.\*(?:\s|$)' -or
                $gitIgnore -notmatch '(?m)^!\.env\.example(?:\s|$)') {
                Add-Finding Error 'env-ignore' (
                    'Ignore .env and .env.* while explicitly retaining .env.example.'
                ) $gitIgnorePath
            }
        }
    }
}

$dockerCommand = Get-Command docker -ErrorAction SilentlyContinue
$resolvedModel = $null
if (-not $dockerCommand) {
    $severity = if ($RequireDocker) { 'Error' } else { 'Warning' }
    Add-Finding $severity 'docker-unavailable' (
        'Docker CLI is unavailable; native Compose and Dockerfile checks were skipped.'
    ) $repositoryRoot
}
else {
    $composeArguments = [System.Collections.Generic.List[string]]::new()
    $composeArguments.Add('compose')
    $composeArguments.Add('--profile')
    $composeArguments.Add('*')
    if ($resolvedEnvFile) {
        $composeArguments.Add('--env-file')
        $composeArguments.Add($resolvedEnvFile)
    }
    foreach ($composePath in $resolvedComposeFiles) {
        $composeArguments.Add('-f')
        $composeArguments.Add($composePath)
    }
    $composeArguments.Add('config')
    $composeArguments.Add('--format')
    $composeArguments.Add('json')

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $modelJson = @(& $dockerCommand.Source @composeArguments 2>$null) -join [Environment]::NewLine
    $composeExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($composeExitCode -ne 0) {
        Add-Finding Error 'compose-config' (
            "docker compose config failed with exit code $composeExitCode."
        ) $resolvedComposeFiles[0]
    }
    else {
        try {
            $resolvedModel = $modelJson | ConvertFrom-Json
        }
        catch {
            Add-Finding Error 'compose-json' (
                "Docker returned an unreadable resolved model: $($_.Exception.Message)"
            ) $resolvedComposeFiles[0]
        }
    }
}

$dockerfilePaths = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)

if ($resolvedModel -and $resolvedModel.services) {
    foreach ($serviceProperty in $resolvedModel.services.PSObject.Properties) {
        $serviceName = $serviceProperty.Name
        $service = $serviceProperty.Value

        if ($service.image) {
            Test-ImageReference -Image ([string]$service.image) -Path $resolvedComposeFiles[0] -Line 0
            if ($Production -and
                [string]$service.image -notmatch '(?i)@sha256:[0-9a-f]{64}$') {
                Add-Finding Error 'mutable-production-image' (
                    "Production service '$serviceName' is not pinned to a sha256 digest."
                ) $resolvedComposeFiles[0]
            }
        }

        if ($service.container_name) {
            Add-Finding Error 'container-name' (
                "Service '$serviceName' sets container_name."
            ) $resolvedComposeFiles[0]
        }
        if ($service.privileged -eq $true) {
            Add-Finding Error 'privileged' "Service '$serviceName' is privileged." $resolvedComposeFiles[0]
        }
        if ($service.network_mode -eq 'host' -or $service.pid -eq 'host') {
            Add-Finding Error 'host-namespace' (
                "Service '$serviceName' uses a host namespace."
            ) $resolvedComposeFiles[0]
        }

        foreach ($port in @($service.ports)) {
            if (-not $port) {
                continue
            }
            if (-not $port.host_ip -or $port.host_ip -in @('0.0.0.0', '::')) {
                Add-Finding Warning 'host-port' (
                    "Service '$serviceName' publishes port $($port.published):$($port.target) on all interfaces."
                ) $resolvedComposeFiles[0]
            }
        }

        foreach ($volume in @($service.volumes)) {
            if (-not $volume) {
                continue
            }
            if ($volume.type -eq 'volume' -and -not $volume.source) {
                Add-Finding Error 'anonymous-volume' (
                    "Service '$serviceName' uses an anonymous persistent volume at '$($volume.target)'."
                ) $resolvedComposeFiles[0]
            }
            if ($volume.type -eq 'bind' -and
                $serviceName -match '(?i)(db|database|postgres|mysql|maria|qdrant|vector)' -and
                -not $volume.read_only) {
                Add-Finding Warning 'engine-bind-mount' (
                    "Data service '$serviceName' has a writable host bind mount at '$($volume.target)'; prefer a named volume."
                ) $resolvedComposeFiles[0]
            }
            if ($Production -and
                $volume.type -eq 'bind' -and
                (
                    [string]$volume.target -match '(?i)^/(?:app|src|source|workspace)(?:/|$)' -or
                    [string]$volume.source -match '(?i)(?:^|[\\/])src(?:[\\/]|$)'
                )) {
                Add-Finding Error 'production-source-bind' (
                    "Production service '$serviceName' bind-mounts source code at '$($volume.target)'."
                ) $resolvedComposeFiles[0]
            }
        }

        if ($service.depends_on) {
            foreach ($dependencyProperty in $service.depends_on.PSObject.Properties) {
                $dependencyName = $dependencyProperty.Name
                $dependency = $dependencyProperty.Value
                if ($dependency.condition -eq 'service_healthy') {
                    $dependencyService = $resolvedModel.services.PSObject.Properties[$dependencyName].Value
                    if (-not $dependencyService.healthcheck) {
                        Add-Finding Error 'missing-healthcheck' (
                            "Service '$serviceName' waits for '$dependencyName' to be healthy, but it has no healthcheck."
                        ) $resolvedComposeFiles[0]
                    }
                }
            }
        }

        if ($service.build) {
            if ($Production) {
                Add-Finding Error 'production-build' (
                    "Production service '$serviceName' retains a local build context; reset it in the production overlay."
                ) $resolvedComposeFiles[0]
            }
            $buildContext = $null
            $dockerfileName = 'Dockerfile'
            if ($service.build -is [string]) {
                $buildContext = [string]$service.build
            }
            else {
                $buildContext = [string]$service.build.context
                if ($service.build.dockerfile) {
                    $dockerfileName = [string]$service.build.dockerfile
                }
            }

            if (-not [System.IO.Path]::IsPathRooted($buildContext)) {
                $buildContext = [System.IO.Path]::GetFullPath(
                    (Join-Path (Split-Path -Parent $resolvedComposeFiles[0]) $buildContext)
                )
            }

            $dockerfilePath = if ([System.IO.Path]::IsPathRooted($dockerfileName)) {
                [System.IO.Path]::GetFullPath($dockerfileName)
            }
            else {
                [System.IO.Path]::GetFullPath((Join-Path $buildContext $dockerfileName))
            }

            if (-not (Test-Path -LiteralPath $dockerfilePath -PathType Leaf)) {
                Add-Finding Error 'missing-dockerfile' (
                    "Service '$serviceName' references missing Dockerfile '$dockerfileName'."
                ) $dockerfilePath
            }
            else {
                $dockerfilePaths.Add($dockerfilePath) | Out-Null
            }

            $dockerIgnore = Join-Path $buildContext '.dockerignore'
            $dockerfileIgnore = "$dockerfilePath.dockerignore"
            if (-not (Test-Path -LiteralPath $dockerIgnore -PathType Leaf) -and
                -not (Test-Path -LiteralPath $dockerfileIgnore -PathType Leaf)) {
                Add-Finding Error 'missing-dockerignore' (
                    "Build context for '$serviceName' has no .dockerignore or Dockerfile-specific ignore file."
                ) $buildContext
            }
            elseif (Test-Path -LiteralPath $dockerIgnore -PathType Leaf) {
                $ignoreContents = Get-Content -Raw -LiteralPath $dockerIgnore
                $ignoreChecks = [ordered]@{
                    git = '(?m)^/?\.git(?:/|\s|$)'
                    environment = '(?m)^/?\.env(?:\.\*|\s|$)'
                    build_output = '(?im)^(?:\*\*/)?(?:\[Bb\]in|bin)(?:/|\s|$)'
                    intermediate_output = '(?im)^(?:\*\*/)?(?:\[Oo\]bj|obj)(?:/|\s|$)'
                    generated_artifacts = '(?im)^(?:\*\*/)?(?:artifacts|output|outputs)(?:/|\s|$)'
                    codex_runtime = '(?im)^(?:\*\*/)?\.(?:codex|agents|playwright|mcp-state)(?:/|\s|$)'
                }
                foreach ($ignoreCheck in $ignoreChecks.GetEnumerator()) {
                    if ($ignoreContents -notmatch $ignoreCheck.Value) {
                        Add-Finding Warning 'dockerignore-coverage' (
                            "Build context ignore file does not cover $($ignoreCheck.Key.Replace('_', ' '))."
                        ) $dockerIgnore
                    }
                }
            }

            if ($RunBuildChecks -and (Test-Path -LiteralPath $dockerfilePath -PathType Leaf)) {
                $previousErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Continue'
                & $dockerCommand.Source build --check --file $dockerfilePath $buildContext *> $null
                $buildCheckExitCode = $LASTEXITCODE
                $ErrorActionPreference = $previousErrorActionPreference
                if ($buildCheckExitCode -ne 0) {
                    Add-Finding Error 'dockerfile-check' (
                        "docker build --check failed for service '$serviceName'."
                    ) $dockerfilePath
                }
            }
        }
    }
}

foreach ($dockerfilePath in $dockerfilePaths) {
    $dockerfileLines = @(Get-Content -LiteralPath $dockerfilePath)
    $fromCount = 0
    $hasUser = $false
    $stageAliases = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    for ($index = 0; $index -lt $dockerfileLines.Count; $index++) {
        $line = $dockerfileLines[$index]
        $lineNumber = $index + 1

        if ($line -match (
            '(?i)^\s*FROM(?:\s+--platform=\S+)?\s+(?<image>\S+)' +
            '(?:\s+AS\s+(?<alias>[a-z0-9._-]+))?'
        )) {
            $fromCount++
            $fromImage = $Matches['image']
            if (-not $stageAliases.Contains($fromImage)) {
                Test-ImageReference -Image $fromImage -Path $dockerfilePath -Line $lineNumber
            }
            if ($Matches['alias']) {
                $stageAliases.Add($Matches['alias']) | Out-Null
            }
        }
        if ($line -match '^\s*USER\s+\S+') {
            $hasUser = $true
        }
        if ($line -match '^\s*(?:ARG|ENV)\s+[^#]*(?i:password|passwd|secret|token|api[_-]?key|private[_-]?key)') {
            Add-Finding Error 'build-secret' (
                'Secret-like Dockerfile ARG or ENV is forbidden; use a BuildKit secret mount.'
            ) $dockerfilePath $lineNumber
        }
        if ($line -match '^\s*(?:ENTRYPOINT|CMD)\s+[^\[]') {
            Add-Finding Warning 'shell-entrypoint' (
                'Prefer JSON/exec form for ENTRYPOINT and CMD so the process receives signals.'
            ) $dockerfilePath $lineNumber
        }
    }

    if ($fromCount -lt 2) {
        Add-Finding Warning 'single-stage' 'Application images should use a multi-stage build.' $dockerfilePath
    }
    if (-not $hasUser) {
        Add-Finding Warning 'root-user' 'Application images should set a non-root USER.' $dockerfilePath
    }
}

$findingKeys = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::Ordinal
)
$uniqueFindings = [System.Collections.Generic.List[object]]::new()
foreach ($finding in $findings) {
    $findingKey = (
        "$($finding.Severity)|$($finding.Code)|$($finding.Path)|" +
        "$($finding.Line)|$($finding.Message)"
    )
    if ($findingKeys.Add($findingKey)) {
        $uniqueFindings.Add($finding)
    }
}
$findings = $uniqueFindings

$errorCount = @($findings | Where-Object Severity -eq 'Error').Count
$warningCount = @($findings | Where-Object Severity -eq 'Warning').Count
$effectiveFailureCount = $errorCount + $(if ($WarningsAsErrors) { $warningCount } else { 0 })

$result = [pscustomobject]@{
    Repository = $repositoryRoot
    ComposeFiles = $resolvedComposeFiles
    DockerfileCount = $dockerfilePaths.Count
    ErrorCount = $errorCount
    WarningCount = $warningCount
    FailureCount = $effectiveFailureCount
    Findings = @($findings)
}

$result

foreach ($finding in $findings) {
    $location = if ($finding.Line) {
        "$($finding.Path):$($finding.Line)"
    }
    else {
        $finding.Path
    }
    $message = "[$($finding.Code)] $location - $($finding.Message)"
    if ($finding.Severity -eq 'Error' -or $WarningsAsErrors) {
        Write-Error $message -ErrorAction Continue
    }
    else {
        Write-Warning $message
    }
}

if ($effectiveFailureCount -gt 0) {
    throw "Docker convention validation failed with $effectiveFailureCount effective failure(s)."
}
