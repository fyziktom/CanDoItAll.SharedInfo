[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$orchestrator = (Resolve-Path (Join-Path $PSScriptRoot '..\Invoke-CanDoItAllNuGetBuilds.ps1')).Path
$adapterTemplate = (Resolve-Path (
    Join-Path $PSScriptRoot '..\..\..\..\templates\repository\tools\deployment\nugets\Build-NuGets.ps1'
)).Path
$globalJsonTemplate = (Resolve-Path (
    Join-Path $PSScriptRoot '..\..\..\..\templates\repository\dotnet\global.json.template'
)).Path
$testRoot = Join-Path (
    [System.IO.Path]::GetTempPath()
) "candoitall-sharedinfo-nuget-tests-$([Guid]::NewGuid().ToString('N'))"
$assertionCount = 0

function Assert-True {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $script:assertionCount++
    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

function New-TestScenario {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$EntryPoint = 'custom\Invoke-Pack.ps1'
    )

    $scenarioRoot = Join-Path $testRoot $Name
    $repositoriesRoot = Join-Path $scenarioRoot 'repositories'
    $manifestPath = Join-Path $scenarioRoot 'repositories.json'
    New-Item -ItemType Directory -Path $repositoriesRoot -Force | Out-Null

    [ordered]@{
        schemaVersion = 1
        repositoryNamePattern = 'CanDoItAll*'
        contracts = [ordered]@{
            nugetBuildEntryPoint = $EntryPoint
        }
        repositories = @()
    } |
        ConvertTo-Json -Depth 5 |
        Set-Content -LiteralPath $manifestPath -Encoding UTF8

    [pscustomobject]@{
        Root = $scenarioRoot
        RepositoriesRoot = $repositoriesRoot
        ManifestPath = $manifestPath
        EntryPoint = $EntryPoint
        OutputRoot = Join-Path $scenarioRoot 'output'
    }
}

function Add-FakeRepository {
    param(
        [Parameter(Mandatory)]
        [psobject]$Scenario,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$AdapterSource
    )

    $repositoryRoot = Join-Path $Scenario.RepositoriesRoot $Name
    $entryPoint = Join-Path $repositoryRoot $Scenario.EntryPoint
    New-Item -ItemType Directory -Path (Split-Path $entryPoint -Parent) -Force | Out-Null
    Set-Content -LiteralPath $entryPoint -Value $AdapterSource -Encoding UTF8
    return $repositoryRoot
}

function Invoke-TestOrchestrator {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Parameters
    )

    $capturedResults = [System.Collections.Generic.List[object]]::new()
    $caughtError = $null
    try {
        & $orchestrator @Parameters |
            ForEach-Object { $capturedResults.Add($_) }
    }
    catch {
        $caughtError = $_
    }

    [pscustomobject]@{
        Results = @($capturedResults)
        Error = $caughtError
    }
}

$successAdapter = @'
[CmdletBinding()]
param(
    [string]$Configuration,
    [string]$OutputDirectory,
    [switch]$NoRestore,
    [string]$Version
)
Write-Output "success|$Configuration|$OutputDirectory|$($NoRestore.IsPresent)|$Version"
'@

$throwAdapter = @'
[CmdletBinding()]
param(
    [string]$Configuration,
    [string]$OutputDirectory,
    [switch]$NoRestore,
    [string]$Version
)
Write-Output 'before-throw'
throw 'fake terminating failure'
'@

$exitAdapter = @'
[CmdletBinding()]
param(
    [string]$Configuration,
    [string]$OutputDirectory,
    [switch]$NoRestore,
    [string]$Version
)
Write-Output 'before-exit'
exit 17
'@

try {
    New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

    $aggregate = New-TestScenario -Name 'aggregate'
    Add-FakeRepository $aggregate 'CanDoItAll.01-Success' $successAdapter | Out-Null
    Add-FakeRepository $aggregate 'CanDoItAll.02-Throw' $throwAdapter | Out-Null
    Add-FakeRepository $aggregate 'CanDoItAll.03-Exit' $exitAdapter | Out-Null

    $aggregateRun = Invoke-TestOrchestrator @{
        RepositoriesRoot = $aggregate.RepositoriesRoot
        ManifestPath = $aggregate.ManifestPath
        OutputRoot = $aggregate.OutputRoot
        NoRestore = $true
        Version = '1.2.3-preview.4'
    }

    Assert-True ($null -ne $aggregateRun.Error) 'aggregate failures should terminate after emitting results'
    Assert-True ($aggregateRun.Results.Count -eq 3) 'all three adapters should be evaluated'
    Assert-True (
        $aggregateRun.Error.Exception.Message -match '2 repository NuGet build\(s\) failed'
    ) 'the final error should aggregate both failures'

    $success = @($aggregateRun.Results | Where-Object Repository -eq 'CanDoItAll.01-Success')
    $throw = @($aggregateRun.Results | Where-Object Repository -eq 'CanDoItAll.02-Throw')
    $exit = @($aggregateRun.Results | Where-Object Repository -eq 'CanDoItAll.03-Exit')
    Assert-True ($success.Count -eq 1 -and $success[0].Status -eq 'Succeeded') 'success should be reported'
    Assert-True ($success[0].ExitCode -eq 0) 'success should have exit code zero'
    Assert-True (
        $success[0].AdapterOutput -match 'success\|Release\|.*\|True\|1\.2\.3-preview\.4'
    ) 'adapter output and the version override should be captured'
    Assert-True (
        $success[0].PackageVersion -eq '1.2.3-preview.4'
    ) 'the orchestrator result should report the requested package version'
    Assert-True (
        $success[0].OutputDirectory -match
            '[\\/]1\.2\.3-preview\.4_\d{8}-\d{9}[\\/]CanDoItAll\.01-Success$'
    ) 'the orchestrator should isolate the run below a versioned, timestamped folder'
    Assert-True ($throw.Count -eq 1 -and $throw[0].Status -eq 'Failed') 'a terminating error should be reported'
    Assert-True ($throw[0].ExitCode -eq 1) 'a terminating error should produce exit code one'
    Assert-True ($throw[0].AdapterOutput -match 'before-throw') 'output before a terminating error should be retained'
    Assert-True ($throw[0].AdapterError -match 'fake terminating failure') 'terminating error text should be retained'
    Assert-True ($exit.Count -eq 1 -and $exit[0].Status -eq 'Failed') 'exit N should be reported'
    Assert-True ($exit[0].ExitCode -eq 17) 'exit N should preserve its exact exit code'
    Assert-True ($exit[0].AdapterOutput -match 'before-exit') 'output before exit N should be retained'

    $stop = New-TestScenario -Name 'stop-on-failure'
    Add-FakeRepository $stop 'CanDoItAll.01-Success' $successAdapter | Out-Null
    Add-FakeRepository $stop 'CanDoItAll.02-Exit' $exitAdapter | Out-Null
    Add-FakeRepository $stop 'CanDoItAll.03-After' $successAdapter | Out-Null

    $stopRun = Invoke-TestOrchestrator @{
        RepositoriesRoot = $stop.RepositoriesRoot
        ManifestPath = $stop.ManifestPath
        OutputRoot = $stop.OutputRoot
        StopOnFailure = $true
    }

    Assert-True ($null -ne $stopRun.Error) 'StopOnFailure should still return a failing run'
    Assert-True ($stopRun.Results.Count -eq 2) 'StopOnFailure should stop after the first failed adapter'
    Assert-True (
        @($stopRun.Results | Where-Object Repository -eq 'CanDoItAll.03-After').Count -eq 0
    ) 'repositories after the first failure should not be invoked'

    $missing = New-TestScenario -Name 'fail-on-missing'
    New-Item -ItemType Directory -Path (
        Join-Path $missing.RepositoriesRoot 'CanDoItAll.Missing'
    ) -Force | Out-Null

    $missingRun = Invoke-TestOrchestrator @{
        RepositoriesRoot = $missing.RepositoriesRoot
        ManifestPath = $missing.ManifestPath
        OutputRoot = $missing.OutputRoot
        FailOnMissing = $true
    }

    Assert-True ($null -ne $missingRun.Error) 'FailOnMissing should terminate the run'
    Assert-True ($missingRun.Results.Count -eq 1) 'the missing repository should have one result'
    Assert-True ($missingRun.Results[0].Status -eq 'NotCompatible') 'a missing adapter should be explicit'
    Assert-True (
        $missingRun.Error.Exception.Message -match '1 selected repository entry point\(s\) missing'
    ) 'the final error should aggregate missing adapters'

    $preview = New-TestScenario -Name 'what-if'
    Add-FakeRepository $preview 'CanDoItAll.Preview' "throw 'WhatIf launched the adapter.'" | Out-Null
    $previewRun = Invoke-TestOrchestrator @{
        RepositoriesRoot = $preview.RepositoriesRoot
        ManifestPath = $preview.ManifestPath
        OutputRoot = $preview.OutputRoot
        WhatIf = $true
    }

    Assert-True ($null -eq $previewRun.Error) 'WhatIf should not launch a throwing adapter'
    Assert-True ($previewRun.Results.Count -eq 1) 'WhatIf should emit one preview result'
    Assert-True ($previewRun.Results[0].Status -eq 'Preview') 'WhatIf should mark the result as Preview'
    Assert-True (-not (Test-Path -LiteralPath $preview.OutputRoot)) 'WhatIf should not create output'

    $templateRepository = Join-Path $testRoot 'template\CanDoItAll.Template'
    $templateEntryPoint = Join-Path $templateRepository 'tools\deployment\nugets\Build-NuGets.ps1'
    $templateOutput = Join-Path $templateRepository 'artifacts\packages'
    New-Item -ItemType Directory -Path (Split-Path $templateEntryPoint -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $adapterTemplate -Destination $templateEntryPoint
    Copy-Item `
        -LiteralPath $globalJsonTemplate `
        -Destination (Join-Path $templateRepository 'global.json')
    Set-Content -LiteralPath (Join-Path $templateRepository 'CanDoItAll.Template.sln') -Value '' -Encoding UTF8

    $templateResult = @(
        & $templateEntryPoint `
            -OutputDirectory $templateOutput `
            -Version '2.3.4-preview.5' `
            -WhatIf
    )
    Assert-True ($templateResult.Count -eq 1) 'the template should emit one preview result'
    Assert-True ($templateResult[0].Status -eq 'Preview') 'the template should honor SupportsShouldProcess'
    Assert-True (
        $templateResult[0].PackageVersion -eq '2.3.4-preview.5'
    ) 'the template preview should report the requested package version'
    Assert-True (-not (Test-Path -LiteralPath $templateOutput)) 'the template WhatIf should not create output'

    $templateDefaultResult = @(
        & $templateEntryPoint `
            -Version '2.3.4-preview.5' `
            -WhatIf
    )
    Assert-True (
        $templateDefaultResult[0].OutputDirectory -match
            '[\\/]artifacts[\\/]packages[\\/]2\.3\.4-preview\.5_\d{8}-\d{9}$'
    ) 'the template default should use a versioned, timestamped run directory'

    [pscustomobject]@{
        Test = 'Invoke-CanDoItAllNuGetBuilds'
        AssertionCount = $assertionCount
        Status = 'Passed'
    }
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        $resolvedTestRoot = [System.IO.Path]::GetFullPath($testRoot)
        $temporaryPrefix = [System.IO.Path]::GetFullPath(
            [System.IO.Path]::GetTempPath()
        ).TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar
        ) + [System.IO.Path]::DirectorySeparatorChar
        $isExpectedTestDirectory = (
            $resolvedTestRoot.StartsWith($temporaryPrefix, [StringComparison]::OrdinalIgnoreCase) -and
            (Split-Path $resolvedTestRoot -Leaf) -like 'candoitall-sharedinfo-nuget-tests-*'
        )
        if (-not $isExpectedTestDirectory) {
            throw "Refusing to remove unexpected test directory: $resolvedTestRoot"
        }

        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
