[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string[]]$ComposeFile = @('compose.yaml'),

    [string]$EnvFile,

    [switch]$RunBuildChecks,

    [switch]$Production,

    [switch]$Smoke,

    [ValidateRange(1, 3600)]
    [int]$WaitTimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$composePaths = @(
    foreach ($path in $ComposeFile) {
        if ([System.IO.Path]::IsPathRooted($path)) {
            (Resolve-Path -LiteralPath $path).Path
        }
        else {
            (Resolve-Path -LiteralPath (Join-Path $repositoryRoot $path)).Path
        }
    }
)
$docker = Get-Command docker -ErrorAction Stop

$composeArguments = [System.Collections.Generic.List[string]]::new()
$composeArguments.Add('compose')
if ($EnvFile) {
    $envPath = if ([System.IO.Path]::IsPathRooted($EnvFile)) {
        (Resolve-Path -LiteralPath $EnvFile).Path
    }
    else {
        (Resolve-Path -LiteralPath (Join-Path $repositoryRoot $EnvFile)).Path
    }
    $composeArguments.Add('--env-file')
    $composeArguments.Add($envPath)
}
foreach ($composePath in $composePaths) {
    $composeArguments.Add('-f')
    $composeArguments.Add($composePath)
}

& $docker.Source @composeArguments config --quiet
if ($LASTEXITCODE -ne 0) {
    throw "Compose validation failed with exit code $LASTEXITCODE."
}

$sharedInfoCandidates = @(
    $env:CANDOITALL_SHAREDINFO_ROOT
    (Join-Path (Split-Path -Parent $repositoryRoot) 'CanDoItAll.SharedInfo')
) | Where-Object { $_ }

$sharedValidator = $null
foreach ($candidate in $sharedInfoCandidates) {
    $validator = Join-Path $candidate 'tools\validation\Test-DockerConventions.ps1'
    if (Test-Path -LiteralPath $validator -PathType Leaf) {
        $sharedValidator = (Resolve-Path -LiteralPath $validator).Path
        break
    }
}

if ($sharedValidator) {
    $sharedArguments = @{
        RepositoryPath = $repositoryRoot
        ComposeFile = $composePaths
        RequireDocker = $true
        WarningsAsErrors = $true
    }
    if ($EnvFile) {
        $sharedArguments.EnvFile = $envPath
    }
    if ($RunBuildChecks) {
        $sharedArguments.RunBuildChecks = $true
    }
    if ($Production) {
        $sharedArguments.Production = $true
    }
    & $sharedValidator @sharedArguments
}
else {
    Write-Warning (
        'CanDoItAll.SharedInfo was not found; shared policy and Dockerfile checks were skipped. ' +
        'Set CANDOITALL_SHAREDINFO_ROOT or clone SharedInfo beside this repository.'
    )
}

if (-not $Smoke) {
    return
}
if ($Production) {
    throw (
        'The template refuses -Production with -Smoke because a production overlay may ' +
        'attach external durable data. Use a separate disposable smoke overlay.'
    )
}

$projectName = "candoitall-sample-validation-$PID"
if (-not $PSCmdlet.ShouldProcess(
        $projectName,
        'Start and wait for the disposable smoke stack, then remove its containers and volumes'
    )) {
    return
}

$started = $false
try {
    $started = $true
    & $docker.Source @composeArguments -p $projectName up -d --wait --wait-timeout $WaitTimeoutSeconds
    if ($LASTEXITCODE -ne 0) {
        throw "Compose smoke startup failed with exit code $LASTEXITCODE."
    }

    # Add repository-owned smoke or integration test commands here.
    & $docker.Source @composeArguments -p $projectName ps --all
    if ($LASTEXITCODE -ne 0) {
        throw "Compose status failed with exit code $LASTEXITCODE."
    }
}
finally {
    if ($started) {
        & $docker.Source @composeArguments -p $projectName down --volumes --remove-orphans
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Compose teardown failed with exit code $LASTEXITCODE for '$projectName'."
        }
    }
}
