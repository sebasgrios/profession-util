# Compatibility entry point for the Profession Reagents data generator.
[CmdletBinding()]
param(
    [string]$Lua = 'lua',
    [switch]$Verify
)

$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $root 'addons/ProfessionReagents/scripts/update-data.ps1') @PSBoundParameters
