# Requires PowerShell 7+ and Lua 5.1.
[CmdletBinding()]
param(
    [string]$Lua = 'lua',
    [switch]$Verify
)

$ErrorActionPreference = 'Stop'
$addonRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $addonRoot 'src'
$root = Split-Path -Parent (Split-Path -Parent $addonRoot)
$lock = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'data-source.json') -Raw | ConvertFrom-Json -AsHashtable
$cache = Join-Path $root '.cache/ProfessionReagents'
$work = Join-Path $cache ('data-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work -Force | Out-Null

function Get-SourceFile([string]$Name, [string]$Url, [string]$Sha256) {
    $path = Join-Path $cache $Name
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) {
        $download = Join-Path $work $Name
        Invoke-WebRequest -Uri $Url -OutFile $download
        if ((Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash -ne $Sha256) {
            throw "Source checksum mismatch for $Name"
        }
        Move-Item -LiteralPath $download -Destination $path
    }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $Sha256) {
        throw "Cached source checksum mismatch for $path"
    }
    return $path
}

function Read-ArchiveText($Archive, [string]$Path) {
    $entry = $Archive.GetEntry("ProfessionDB/$Path")
    if (!$entry) { throw "Missing upstream file $Path" }
    $reader = [IO.StreamReader]::new($entry.Open())
    try { return $reader.ReadToEnd().ReplaceLineEndings([string][char]10) }
    finally { $reader.Dispose() }
}

function Publish-Text([string]$RelativePath, [string]$Text) {
    $destination = Join-Path $sourceRoot $RelativePath
    if ($Verify) {
        if (!(Test-Path -LiteralPath $destination -PathType Leaf) -or [IO.File]::ReadAllText($destination) -cne $Text) {
            throw "Checked-in file differs from regenerated $RelativePath"
        }
    } else {
        [IO.File]::WriteAllText($destination, $Text)
    }
}

try {
    $lib = $lock.library
    $sourceZip = Get-SourceFile (Split-Path $lib.download -Leaf) $lib.download $lib.sha256
    $archive = [IO.Compression.ZipFile]::OpenRead($sourceZip)
    try {
        $license = Read-ArchiveText $archive 'LICENSE'
        if (!$license.StartsWith('MIT License')) { throw 'Unexpected upstream license' }
        $toc = Read-ArchiveText $archive 'ProfessionDB_Camelot.toc'
        if ($toc -notmatch "(?m)^## Interface: $($lock.interface)$" -or !$toc.Contains($lock.build)) {
            throw 'Unexpected Forever TOC or data build'
        }
        foreach ($path in 'libs/LibStub/LibStub.lua','LibProfessionDB-1.0.lua') {
            [IO.File]::WriteAllText((Join-Path $work (Split-Path $path -Leaf)), (Read-ArchiveText $archive $path))
        }
        $cores = foreach ($line in ($toc -split '\n')) {
            if ($line -match '^Data\\Forever\\_core\\([A-Za-z]+\.lua)$') {
                $name = $Matches[1]
                $core = Read-ArchiveText $archive ($line.Replace('\', '/'))
                if ($core.Contains('lib:LoadCore(')) {
                    if (!$core.Contains("-- build $($lock.build) -")) { throw "Unexpected data build for $name" }
                    [IO.File]::WriteAllText((Join-Path $work $name), $core)
                    $name
                }
            }
        }
    } finally {
        $archive.Dispose()
    }

    $professions = @{}
    foreach ($id in $lock.professionIDs) { $professions[[int]$id] = @{} }
    foreach ($locale in $lock.skillLineSha256.Keys) {
        $csvUrl = "https://wago.tools/db2/SkillLine/csv?build=$($lock.build)&locale=$locale"
        $csv = Get-SourceFile "SkillLine-$locale.csv" $csvUrl $lock.skillLineSha256[$locale]
        foreach ($row in Import-Csv -LiteralPath $csv) {
            $id = [int]$row.ID
            if ($professions.ContainsKey($id)) {
                $professions[$id][$locale] = $row.DisplayName_lang
                if ($locale -eq 'enUS') {
                    $professions[$id].icon = [int]$row.SpellIconFileID
                }
            }
        }
    }
    $localeCodes = @($lock.skillLineSha256.Keys) + @($lock.localizedNames.Keys)
    $catalog = foreach ($id in $lock.professionIDs) {
        $record = $professions[[int]$id]
        if ($null -eq $record.icon) {
            throw "Missing SkillLine data for $id"
        }
        foreach ($locale in $lock.localizedNames.Keys) {
            $record[$locale] = $lock.localizedNames[$locale].names[[string]$id]
        }
        $names = foreach ($locale in $localeCodes) {
            if (!$record[$locale] -or $record[$locale] -match '["\\\x00-\x1f]') {
                throw "Invalid or missing $locale profession name for $id"
            }
            ('{0} = "{1}"' -f $locale, $record[$locale])
        }
        ('    [{0}] = {{ icon = {1}, {2} }},' -f $id, $record.icon, ($names -join ', '))
    }
    [IO.File]::WriteAllLines((Join-Path $work 'professions.lua'), @('return {') + @($catalog) + @('}'))

    $generatorArgs = @(
        $work, $sourceRoot, $lib.version, $lib.release,
        $lock.clientVersion, $lock.build, $lock.interface, $lock.recipes
    ) + @($cores)
    & $Lua (Join-Path $PSScriptRoot 'generate-data.lua') @generatorArgs
    if ($LASTEXITCODE -ne 0) { throw "Data generation failed with exit code $LASTEXITCODE" }

    Publish-Text 'Database/Forever.lua' ([IO.File]::ReadAllText((Join-Path $work 'Forever.lua')))
    Publish-Text 'LICENSE-LibProfessionDB.txt' $license
} finally {
    # Remove only the ordinary files that this run put in its own work directory.
    Get-ChildItem -LiteralPath $work -File | Remove-Item
    Remove-Item -LiteralPath $work
}
