[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$RepositoriesRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path,

    [string[]]$Repository,

    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [string]$OutputRoot = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path 'artifacts\packages'),

    [string]$ManifestPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path 'config\repositories.json'),

    [switch]$NoRestore,

    [string]$Version = '',

    [switch]$FailOnMissing,

    [switch]$StopOnFailure
)

$ErrorActionPreference = 'Stop'

function ConvertTo-PowerShellLiteral {
    param(
        [AllowEmptyString()]
        [string]$Value
    )

    return "'$($Value.Replace("'", "''"))'"
}

function Invoke-IsolatedNuGetAdapter {
    param(
        [Parameter(Mandatory)]
        [string]$EntryPoint,

        [Parameter(Mandatory)]
        [string]$BuildConfiguration,

        [Parameter(Mandatory)]
        [string]$BuildOutputDirectory,

        [string]$PackageVersion,

        [switch]$SkipRestore
    )

    $entryPointLiteral = ConvertTo-PowerShellLiteral $EntryPoint
    $configurationLiteral = ConvertTo-PowerShellLiteral $BuildConfiguration
    $outputDirectoryLiteral = ConvertTo-PowerShellLiteral $BuildOutputDirectory
    $adapterInvocation = "& $entryPointLiteral -Configuration $configurationLiteral -OutputDirectory $outputDirectoryLiteral"
    if ($SkipRestore) {
        $adapterInvocation += ' -NoRestore'
    }
    if (-not [string]::IsNullOrWhiteSpace($PackageVersion)) {
        $versionLiteral = ConvertTo-PowerShellLiteral $PackageVersion
        $adapterInvocation += " -Version $versionLiteral"
    }

    # A repository adapter is intentionally run in another PowerShell process. In
    # particular, an adapter that uses `exit N` must not terminate this orchestrator.
    $childCommand = @"
`$ErrorActionPreference = 'Stop'
try {
    $adapterInvocation
    if (`$LASTEXITCODE -is [int] -and `$LASTEXITCODE -ne 0) {
        exit `$LASTEXITCODE
    }
}
catch {
    [Console]::Error.WriteLine(`$_.Exception.ToString())
    exit 1
}
"@

    $encodedCommand = [Convert]::ToBase64String(
        [Text.Encoding]::Unicode.GetBytes($childCommand)
    )
    $powerShellExecutable = (Get-Process -Id $PID).Path
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $powerShellExecutable
    $startInfo.Arguments = "-NoLogo -NoProfile -NonInteractive -EncodedCommand $encodedCommand"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo

    try {
        if (-not $process.Start()) {
            throw "PowerShell did not start for adapter '$EntryPoint'."
        }

        $standardOutputTask = $process.StandardOutput.ReadToEndAsync()
        $standardErrorTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()

        [pscustomobject]@{
            ExitCode = $process.ExitCode
            StandardOutput = $standardOutputTask.GetAwaiter().GetResult().Trim()
            StandardError = $standardErrorTask.GetAwaiter().GetResult().Trim()
        }
    }
    finally {
        $process.Dispose()
    }
}

$RepositoriesRoot = [System.IO.Path]::GetFullPath($RepositoriesRoot)
$OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$ManifestPath = [System.IO.Path]::GetFullPath($ManifestPath)

if (-not (Test-Path -LiteralPath $RepositoriesRoot -PathType Container)) {
    throw "Repositories root does not exist: $RepositoriesRoot"
}
if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Repository manifest does not exist: $ManifestPath"
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$entryPointRelativePath = [string]$manifest.contracts.nugetBuildEntryPoint
if ([string]::IsNullOrWhiteSpace($entryPointRelativePath)) {
    throw "Manifest '$ManifestPath' does not define contracts.nugetBuildEntryPoint."
}
if ([System.IO.Path]::IsPathRooted($entryPointRelativePath) -or
    @($entryPointRelativePath -split '[\\/]' | Where-Object { $_ -eq '..' }).Count -gt 0) {
    throw "Manifest contracts.nugetBuildEntryPoint must be a repository-relative path without '..' segments."
}

$repositoryNamePattern = [string]$manifest.repositoryNamePattern
if ([string]::IsNullOrWhiteSpace($repositoryNamePattern)) {
    $repositoryNamePattern = 'CanDoItAll*'
}
if (-not $Repository -or $Repository.Count -eq 0) {
    $Repository = @($repositoryNamePattern)
}

$directories = @(
    Get-ChildItem -LiteralPath $RepositoriesRoot -Directory |
        Where-Object { $_.Name -like $repositoryNamePattern } |
        Sort-Object Name
)

$results = [System.Collections.Generic.List[object]]::new()
$failedRepositories = [System.Collections.Generic.List[string]]::new()
$missingRepositories = [System.Collections.Generic.List[string]]::new()
$pathComparison = if ([System.IO.Path]::DirectorySeparatorChar -eq '\') {
    [StringComparison]::OrdinalIgnoreCase
}
else {
    [StringComparison]::Ordinal
}

foreach ($directory in $directories) {
    $selected = $false
    foreach ($pattern in $Repository) {
        if ($directory.Name -like $pattern) {
            $selected = $true
            break
        }
    }

    if (-not $selected) {
        continue
    }

    $repositoryPrefix = $directory.FullName.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar
    $entryPoint = [System.IO.Path]::GetFullPath(
        (Join-Path $directory.FullName $entryPointRelativePath)
    )
    if (-not $entryPoint.StartsWith($repositoryPrefix, $pathComparison)) {
        throw "Resolved NuGet entry point escapes repository '$($directory.FullName)': $entryPoint"
    }

    if (-not (Test-Path -LiteralPath $entryPoint -PathType Leaf)) {
        $missingRepositories.Add($directory.Name)
        $results.Add([pscustomobject]@{
            Repository = $directory.Name
            Status = 'NotCompatible'
            ExitCode = $null
            OutputDirectory = $null
            PackageVersion = $Version
            Message = "Missing $entryPointRelativePath"
            AdapterOutput = ''
            AdapterError = ''
        })
        continue
    }

    $repositoryOutput = Join-Path $OutputRoot $directory.Name
    if (-not $PSCmdlet.ShouldProcess($directory.FullName, "Build NuGet packages into '$repositoryOutput'")) {
        $results.Add([pscustomobject]@{
            Repository = $directory.Name
            Status = 'Preview'
            ExitCode = $null
            OutputDirectory = $repositoryOutput
            PackageVersion = $Version
            Message = $entryPoint
            AdapterOutput = ''
            AdapterError = ''
        })
        continue
    }

    try {
        $adapterResult = Invoke-IsolatedNuGetAdapter `
            -EntryPoint $entryPoint `
            -BuildConfiguration $Configuration `
            -BuildOutputDirectory $repositoryOutput `
            -PackageVersion $Version `
            -SkipRestore:$NoRestore

        if ($adapterResult.ExitCode -ne 0) {
            $failedRepositories.Add("$($directory.Name) (exit $($adapterResult.ExitCode))")
            $message = "Adapter exited with code $($adapterResult.ExitCode)."
            if ($adapterResult.StandardError) {
                $message += " $($adapterResult.StandardError)"
            }

            $results.Add([pscustomobject]@{
                Repository = $directory.Name
                Status = 'Failed'
                ExitCode = $adapterResult.ExitCode
                OutputDirectory = $repositoryOutput
                PackageVersion = $Version
                Message = $message
                AdapterOutput = $adapterResult.StandardOutput
                AdapterError = $adapterResult.StandardError
            })

            if ($StopOnFailure) {
                break
            }
            continue
        }

        $results.Add([pscustomobject]@{
            Repository = $directory.Name
            Status = 'Succeeded'
            ExitCode = 0
            OutputDirectory = $repositoryOutput
            PackageVersion = $Version
            Message = $entryPoint
            AdapterOutput = $adapterResult.StandardOutput
            AdapterError = $adapterResult.StandardError
        })
    }
    catch {
        $failedRepositories.Add("$($directory.Name) (orchestrator error)")
        $results.Add([pscustomobject]@{
            Repository = $directory.Name
            Status = 'Failed'
            ExitCode = $null
            OutputDirectory = $repositoryOutput
            PackageVersion = $Version
            Message = $_.Exception.Message
            AdapterOutput = ''
            AdapterError = $_.Exception.ToString()
        })

        if ($StopOnFailure) {
            break
        }
    }
}

$results

$terminalIssues = [System.Collections.Generic.List[string]]::new()
if ($failedRepositories.Count -gt 0) {
    $terminalIssues.Add(
        "$($failedRepositories.Count) repository NuGet build(s) failed: $($failedRepositories -join ', ')"
    )
}
if ($FailOnMissing -and $missingRepositories.Count -gt 0) {
    $terminalIssues.Add(
        "$($missingRepositories.Count) selected repository entry point(s) missing: $($missingRepositories -join ', ')"
    )
}
if ($terminalIssues.Count -gt 0) {
    throw "NuGet build orchestration failed. $($terminalIssues -join '; ')"
}
