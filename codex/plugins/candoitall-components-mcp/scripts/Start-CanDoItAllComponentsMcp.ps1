[CmdletBinding()]
param(
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw 'dotnet is required to start CanDoItAll.Mcp.Components.'
}

$pluginRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sharedInfoRoot = (Resolve-Path (Join-Path $pluginRoot '..\..\..')).Path
$repositoriesRoot = if ($env:CANDOITALL_REPOSITORIES_ROOT) {
    [System.IO.Path]::GetFullPath($env:CANDOITALL_REPOSITORIES_ROOT)
}
else {
    Split-Path $sharedInfoRoot -Parent
}

$mcpProject = Join-Path $repositoriesRoot 'CanDoItAll.Mcp\src\CanDoItAll.Mcp.Components\CanDoItAll.Mcp.Components.csproj'
$componentsRoot = Join-Path $repositoriesRoot 'CanDoItAll.Components'
$settingsPath = Join-Path $pluginRoot 'CanDoItAll.Mcp.Components.settings.json'

if (-not (Test-Path -LiteralPath $mcpProject -PathType Leaf)) {
    throw "Missing Components MCP project: $mcpProject. Clone CanDoItAll.Mcp beside CanDoItAll.SharedInfo or set CANDOITALL_REPOSITORIES_ROOT."
}
if (-not (Test-Path -LiteralPath $componentsRoot -PathType Container)) {
    throw "Missing Components repository: $componentsRoot. Clone CanDoItAll.Components beside CanDoItAll.SharedInfo or set CANDOITALL_REPOSITORIES_ROOT."
}

if ($ValidateOnly) {
    [pscustomobject]@{
        RepositoriesRoot = $repositoriesRoot
        McpProject = $mcpProject
        ComponentsRoot = $componentsRoot
        SettingsPath = $settingsPath
    }
    return
}

$mcpExitCode = 1
Push-Location $repositoriesRoot
try {
    & dotnet run `
        --project $mcpProject `
        -- `
        --settings $settingsPath
    $mcpExitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}

exit $mcpExitCode
