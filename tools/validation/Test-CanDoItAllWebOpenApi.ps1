[CmdletBinding()]
param(
    [string]$OpenApiPath,
    [string]$ManifestPath
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$supportRoot = Join-Path $repositoryRoot 'codex\skills\_candoitall-api-shared'
if ([string]::IsNullOrWhiteSpace($OpenApiPath)) {
    $OpenApiPath = Join-Path $supportRoot 'references\candoitall-web.openapi.json'
}
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $supportRoot 'manifest.json'
}

$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $script:failures.Add($Message)
}

if (-not (Test-Path -LiteralPath $OpenApiPath -PathType Leaf)) {
    Add-Failure "OpenAPI artifact does not exist: $OpenApiPath"
}
if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    Add-Failure "OpenAPI manifest does not exist: $ManifestPath"
}

$document = $null
$manifest = $null
if ($failures.Count -eq 0) {
    try {
        $document = Get-Content -Raw -LiteralPath $OpenApiPath | ConvertFrom-Json
    }
    catch {
        Add-Failure "OpenAPI artifact is not valid JSON: $($_.Exception.Message)"
    }

    try {
        $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
    }
    catch {
        Add-Failure "OpenAPI manifest is not valid JSON: $($_.Exception.Message)"
    }
}

$actualHash = $null
$pathCount = 0
$operationCount = 0
$schemaCount = 0
$pathOperationCounts = @{}
$httpMethods = @('get', 'put', 'post', 'delete', 'options', 'head', 'patch', 'trace')

if ($document -and $manifest) {
    if ([int]$manifest.schemaVersion -ne 1) {
        Add-Failure "Unsupported OpenAPI manifest schema version '$($manifest.schemaVersion)'."
    }
    if ([string]$manifest.source.repository -ne 'CanDoItAll') {
        Add-Failure "OpenAPI manifest source repository must be 'CanDoItAll'."
    }
    if ([string]::IsNullOrWhiteSpace([string]$manifest.source.branch)) {
        Add-Failure 'OpenAPI manifest source branch cannot be empty.'
    }
    if ([string]$manifest.source.commit -notmatch '^[0-9a-fA-F]{40}$') {
        Add-Failure "OpenAPI manifest source commit must be a full 40-character Git hash."
    }
    if ([string]$manifest.source.webProject -ne
        'src/App/CanDoItAll.Web/CanDoItAll.Web.csproj') {
        Add-Failure 'OpenAPI manifest records an unexpected source web project.'
    }
    if ([string]$manifest.source.environment -ne 'Development') {
        Add-Failure "OpenAPI manifest environment must be 'Development'."
    }
    $workingTreeCleanProperty = $manifest.source.PSObject.Properties['workingTreeClean']
    if (-not $workingTreeCleanProperty) {
        Add-Failure 'OpenAPI manifest must record source.workingTreeClean.'
    }
    elseif (-not [bool]$manifest.source.workingTreeClean) {
        if ([string]::IsNullOrWhiteSpace([string]$manifest.source.workingTreeNote)) {
            Add-Failure (
                'A non-clean OpenAPI source must include source.workingTreeNote.'
            )
        }
        if ([string]$manifest.source.workingTreeStatusSha256 -notmatch
            '^[0-9a-fA-F]{64}$') {
            Add-Failure (
                'A non-clean OpenAPI source must include a SHA-256 working-tree ' +
                'status fingerprint.'
            )
        }
    }
    try {
        $generatedUtc = $manifest.source.generatedUtc
        $generatedAt = if ($generatedUtc -is [DateTimeOffset]) {
            [DateTimeOffset]$generatedUtc
        }
        elseif ($generatedUtc -is [DateTime]) {
            [DateTimeOffset]::new([DateTime]$generatedUtc)
        }
        else {
            [DateTimeOffset]::Parse(
                [string]$generatedUtc,
                [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::RoundtripKind
            )
        }
        if ($generatedAt.Offset -ne [TimeSpan]::Zero) {
            Add-Failure 'OpenAPI manifest generatedUtc must use UTC.'
        }
    }
    catch {
        Add-Failure 'OpenAPI manifest generatedUtc must be a round-trip timestamp.'
    }
    foreach ($requiredRuntimeDocumentPath in @(
        '/openapi/v1.json',
        '/swagger/v1/swagger.json'
    )) {
        if ($requiredRuntimeDocumentPath -notin @($manifest.source.runtimeDocumentPaths)) {
            Add-Failure (
                "OpenAPI manifest does not record runtime document path " +
                "'$requiredRuntimeDocumentPath'."
            )
        }
    }

    $manifestArtifactPath = [System.IO.Path]::GetFullPath(
        (Join-Path (Split-Path -Parent $ManifestPath) ([string]$manifest.artifact.file))
    )
    $actualArtifactPath = [System.IO.Path]::GetFullPath($OpenApiPath)
    if ($manifestArtifactPath -ne $actualArtifactPath) {
        Add-Failure (
            "OpenAPI manifest artifact path '$manifestArtifactPath' does not match " +
            "validated artifact '$actualArtifactPath'."
        )
    }

    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $OpenApiPath).Hash
    if ($actualHash -ne [string]$manifest.artifact.sha256) {
        Add-Failure (
            "OpenAPI SHA-256 '$actualHash' does not match manifest value " +
            "'$($manifest.artifact.sha256)'."
        )
    }

    if ([string]$document.openapi -ne [string]$manifest.artifact.openapiVersion) {
        Add-Failure (
            "OpenAPI version '$($document.openapi)' does not match manifest value " +
            "'$($manifest.artifact.openapiVersion)'."
        )
    }
    if ([string]$document.info.title -ne [string]$manifest.artifact.documentTitle) {
        Add-Failure (
            "OpenAPI title '$($document.info.title)' does not match manifest value " +
            "'$($manifest.artifact.documentTitle)'."
        )
    }
    if ([string]$document.info.version -ne [string]$manifest.artifact.documentVersion) {
        Add-Failure (
            "OpenAPI document version '$($document.info.version)' does not match manifest " +
            "value '$($manifest.artifact.documentVersion)'."
        )
    }
    $documentServerUrls = @($document.servers | ForEach-Object { [string]$_.url })
    if ($documentServerUrls.Count -ne 1 -or
        $documentServerUrls[0] -ne [string]$manifest.artifact.serverUrl -or
        [string]$manifest.artifact.serverUrl -ne 'http://localhost:5032/') {
        Add-Failure (
            "OpenAPI document must contain only the canonical server URL " +
            "'http://localhost:5032/'."
        )
    }

    if (-not $document.paths) {
        Add-Failure 'OpenAPI document has no paths object.'
    }
    else {
        $pathProperties = @($document.paths.PSObject.Properties)
        $pathCount = $pathProperties.Count
        foreach ($pathProperty in $pathProperties) {
            $route = [string]$pathProperty.Name
            if (-not $route.StartsWith('/')) {
                Add-Failure "OpenAPI path does not begin with '/': $route"
            }

            $routeOperationCount = 0
            foreach ($pathItemProperty in @($pathProperty.Value.PSObject.Properties)) {
                $method = $pathItemProperty.Name.ToLowerInvariant()
                if ($method -notin $httpMethods) {
                    continue
                }

                $routeOperationCount++
                $operationCount++
                $operation = $pathItemProperty.Value
                if (-not $operation.PSObject.Properties['responses']) {
                    Add-Failure "OpenAPI operation $($method.ToUpperInvariant()) $route has no responses."
                }
            }

            if ($routeOperationCount -eq 0) {
                Add-Failure "OpenAPI path has no HTTP operations: $route"
            }
            $pathOperationCounts[$route] = $routeOperationCount
        }
    }

    if ($document.components -and $document.components.schemas) {
        $schemaCount = @($document.components.schemas.PSObject.Properties).Count
    }

    $expectedPathCount = [int]$manifest.artifact.pathCount
    $expectedOperationCount = [int]$manifest.artifact.operationCount
    $expectedSchemaCount = [int]$manifest.artifact.schemaCount
    if ($pathCount -ne $expectedPathCount) {
        Add-Failure "OpenAPI has $pathCount paths; manifest requires $expectedPathCount."
    }
    if ($operationCount -ne $expectedOperationCount) {
        Add-Failure (
            "OpenAPI has $operationCount operations; manifest requires " +
            "$expectedOperationCount."
        )
    }
    if ($schemaCount -ne $expectedSchemaCount) {
        Add-Failure "OpenAPI has $schemaCount schemas; manifest requires $expectedSchemaCount."
    }

    $assignedRoutes = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    $familyPathTotal = 0
    $familyOperationTotal = 0
    foreach ($routeFamily in @($manifest.routeFamilies)) {
        $prefix = [string]$routeFamily.prefix
        if ([string]::IsNullOrWhiteSpace($prefix) -or -not $prefix.StartsWith('/')) {
            Add-Failure "Invalid route-family prefix in manifest: '$prefix'."
            continue
        }

        $familyRoutes = @(
            $pathOperationCounts.Keys |
                Where-Object { $_ -eq $prefix -or $_.StartsWith($prefix + '/') }
        )
        $familyPathCount = $familyRoutes.Count
        $familyOperationCount = 0
        foreach ($familyRoute in $familyRoutes) {
            $familyOperationCount += [int]$pathOperationCounts[$familyRoute]
            if (-not $assignedRoutes.Add($familyRoute)) {
                Add-Failure "OpenAPI route belongs to overlapping route families: $familyRoute"
            }
        }

        $expectedFamilyPathCount = [int]$routeFamily.pathCount
        $expectedFamilyOperationCount = [int]$routeFamily.operationCount
        if ($familyPathCount -ne $expectedFamilyPathCount) {
            Add-Failure (
                "Route family '$prefix' has $familyPathCount paths; manifest requires " +
                "$expectedFamilyPathCount."
            )
        }
        if ($familyOperationCount -ne $expectedFamilyOperationCount) {
            Add-Failure (
                "Route family '$prefix' has $familyOperationCount operations; manifest " +
                "requires $expectedFamilyOperationCount."
            )
        }

        $familyPathTotal += $familyPathCount
        $familyOperationTotal += $familyOperationCount
    }

    $unassignedRoutes = @(
        $pathOperationCounts.Keys | Where-Object { -not $assignedRoutes.Contains($_) }
    )
    foreach ($unassignedRoute in $unassignedRoutes) {
        Add-Failure "OpenAPI route is not assigned to a manifest route family: $unassignedRoute"
    }
    if ($familyPathTotal -ne $pathCount) {
        Add-Failure (
            "Route-family path total is $familyPathTotal but the OpenAPI document has " +
            "$pathCount paths."
        )
    }
    if ($familyOperationTotal -ne $operationCount) {
        Add-Failure (
            "Route-family operation total is $familyOperationTotal but the OpenAPI " +
            "document has $operationCount operations."
        )
    }

    foreach ($operationSet in @($manifest.documentedOperationSets)) {
        $setName = [string]$operationSet.name
        $setPrefix = [string]$operationSet.prefix
        if ([string]::IsNullOrWhiteSpace($setName) -or
            [string]::IsNullOrWhiteSpace($setPrefix)) {
            Add-Failure 'Documented operation set has no name or prefix.'
            continue
        }

        $declaredOperations = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::Ordinal
        )
        foreach ($declaredOperation in @($operationSet.operations)) {
            $declaredMethod = ([string]$declaredOperation.method).ToUpperInvariant()
            $declaredPath = [string]$declaredOperation.path
            $declaredOperationKey = "$declaredMethod $declaredPath"
            if ($declaredMethod.ToLowerInvariant() -notin $httpMethods -or
                [string]::IsNullOrWhiteSpace($declaredPath)) {
                Add-Failure (
                    "Documented operation set '$setName' contains invalid operation " +
                    "'$declaredOperationKey'."
                )
                continue
            }
            if (-not $declaredOperations.Add($declaredOperationKey)) {
                Add-Failure (
                    "Documented operation set '$setName' contains duplicate operation " +
                    "'$declaredOperationKey'."
                )
                continue
            }

            $declaredPathProperty = $document.paths.PSObject.Properties[$declaredPath]
            if (-not $declaredPathProperty) {
                Add-Failure (
                    "Documented operation set '$setName' references missing path " +
                    "'$declaredPath'."
                )
                continue
            }
            $declaredMethodProperty = $declaredPathProperty.Value.PSObject.Properties[
                $declaredMethod.ToLowerInvariant()
            ]
            if (-not $declaredMethodProperty) {
                Add-Failure (
                    "Documented operation set '$setName' references missing operation " +
                    "'$declaredOperationKey'."
                )
                continue
            }
            if ([string]$declaredMethodProperty.Value.operationId -ne
                [string]$declaredOperation.operationId) {
                Add-Failure (
                    "Operation '$declaredOperationKey' has operationId " +
                    "'$($declaredMethodProperty.Value.operationId)'; manifest requires " +
                    "'$($declaredOperation.operationId)'."
                )
            }
        }

        $actualSetOperations = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::Ordinal
        )
        foreach ($setPathProperty in @(
            $document.paths.PSObject.Properties |
                Where-Object {
                    $_.Name -eq $setPrefix -or $_.Name.StartsWith($setPrefix + '/')
                }
        )) {
            foreach ($setMethodProperty in @(
                $setPathProperty.Value.PSObject.Properties |
                    Where-Object Name -in $httpMethods
            )) {
                [void]$actualSetOperations.Add(
                    $setMethodProperty.Name.ToUpperInvariant() + ' ' + $setPathProperty.Name
                )
            }
        }

        foreach ($actualSetOperation in $actualSetOperations) {
            if (-not $declaredOperations.Contains($actualSetOperation)) {
                Add-Failure (
                    "Documented operation set '$setName' omits OpenAPI operation " +
                    "'$actualSetOperation'."
                )
            }
        }
        foreach ($declaredOperationKey in $declaredOperations) {
            if (-not $actualSetOperations.Contains($declaredOperationKey)) {
                Add-Failure (
                    "Documented operation set '$setName' contains non-current operation " +
                    "'$declaredOperationKey'."
                )
            }
        }

        $skillFile = [System.IO.Path]::GetFullPath(
            (Join-Path (Split-Path -Parent $ManifestPath) ([string]$operationSet.skillFile))
        )
        if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
            Add-Failure "Documented operation set '$setName' has missing skill file: $skillFile"
            continue
        }

        $skillContents = Get-Content -Raw -LiteralPath $skillFile
        $routeAppendix = [string]$operationSet.routeAppendix
        if ([string]::IsNullOrWhiteSpace($routeAppendix)) {
            $routeAppendix = 'api-docs-skills-parity:routes'
        }
        if ($routeAppendix -notmatch '^api-docs-skills-parity:[a-z0-9-]+$') {
            Add-Failure (
                "Documented operation set '$setName' has invalid route appendix " +
                "marker '$routeAppendix'."
            )
            continue
        }

        $appendixStartMarker = "<!-- ${routeAppendix}:start -->"
        $appendixEndMarker = "<!-- ${routeAppendix}:end -->"
        $appendixMatch = [regex]::Match(
            $skillContents,
            '(?s)' +
                [regex]::Escape($appendixStartMarker) +
                '(?<body>.*?)' +
                [regex]::Escape($appendixEndMarker)
        )
        if (-not $appendixMatch.Success) {
            Add-Failure (
                "Documented operation set '$setName' skill has no '$routeAppendix' " +
                'route appendix markers.'
            )
            continue
        }

        $appendixOperations = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::Ordinal
        )
        foreach ($routeMatch in [regex]::Matches(
            $appendixMatch.Groups['body'].Value,
            '(?m)^\|\s*`(?<method>GET|PUT|POST|DELETE|OPTIONS|HEAD|PATCH|TRACE)`' +
                '\s*\|\s*`(?<route>[^`]+)`\s*\|'
        )) {
            $appendixPath = [regex]::Replace(
                $routeMatch.Groups['route'].Value,
                ':[^}]+',
                ''
            )
            [void]$appendixOperations.Add(
                $routeMatch.Groups['method'].Value + ' ' + $appendixPath
            )
        }
        foreach ($declaredOperationKey in $declaredOperations) {
            if (-not $appendixOperations.Contains($declaredOperationKey)) {
                Add-Failure (
                    "Skill route appendix for '$setName' omits '$declaredOperationKey'."
                )
            }
        }
        foreach ($appendixOperation in $appendixOperations) {
            if (-not $declaredOperations.Contains($appendixOperation)) {
                Add-Failure (
                    "Skill route appendix for '$setName' contains non-current operation " +
                    "'$appendixOperation'."
                )
            }
        }
    }
}

$result = [pscustomobject]@{
    OpenApiPath = $OpenApiPath
    ManifestPath = $ManifestPath
    OpenApiVersion = if ($document) { [string]$document.openapi } else { $null }
    PathCount = $pathCount
    OperationCount = $operationCount
    SchemaCount = $schemaCount
    Sha256 = $actualHash
    FailureCount = $failures.Count
    Status = if ($failures.Count -eq 0) { 'Passed' } else { 'Failed' }
}

$result
if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "CanDoItAll web OpenAPI validation failed with $($failures.Count) error(s)."
}
