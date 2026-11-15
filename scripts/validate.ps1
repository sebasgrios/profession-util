# Requires PowerShell 7+, Lua 5.1, Luacheck and StyLua.
[CmdletBinding()]
param(
    [string]$Lua = 'lua',
    [string]$Luacheck = 'luacheck',
    [string]$StyLua = 'stylua',
    [switch]$VerifyData,
    [ValidatePattern('^[A-Za-z][A-Za-z0-9_]*$')]
    [string]$Addon
)

$ErrorActionPreference = 'Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    $projects = if ($Addon) {
        @(Get-Item -LiteralPath "addons/$Addon")
    } else {
        @(Get-ChildItem -LiteralPath 'addons' -Directory | Sort-Object Name)
    }
    if (!$projects) { throw 'No addon projects found' }

    foreach ($project in $projects) {
        $name = $project.Name
        $projectPath = "addons/$name"
        $sourceRoot = Join-Path $projectPath 'src'
        if (!(Test-Path -LiteralPath (Join-Path $sourceRoot "$name.toc") -PathType Leaf)) {
            throw "Missing $name.toc in $sourceRoot"
        }
        $tests = Join-Path $projectPath 'tests/run.lua'
        if (Test-Path -LiteralPath $tests -PathType Leaf) {
            & $Lua $tests $sourceRoot
            if ($LASTEXITCODE -ne 0) { throw "Lua tests failed for $name" }
        }
        & $Luacheck $projectPath
        if ($LASTEXITCODE -ne 0) { throw "Luacheck failed for $name" }
        & $StyLua --check $projectPath
        if ($LASTEXITCODE -ne 0) { throw "StyLua check failed for $name" }

        $generateData = Join-Path $project.FullName 'scripts/update-data.ps1'
        if ($VerifyData -and (Test-Path -LiteralPath $generateData -PathType Leaf)) {
            & $generateData -Lua $Lua -Verify
        }
    }
} finally {
    Pop-Location
}
