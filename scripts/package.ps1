# Requires PowerShell 7+.
[CmdletBinding()]
param(
    [switch]$Verify,
    [ValidatePattern('^[A-Za-z][A-Za-z0-9_]*$')]
    [string]$Addon = 'ProfessionReagents'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$name = $Addon
$sourceRoot = Join-Path $root "addons/$name/src"
$tocName = "$name.toc"
$tocPath = Join-Path $sourceRoot $tocName
$toc = Get-Content -LiteralPath $tocPath
$versionLine = @($toc | Where-Object { $_ -match '^## Version: \d+\.\d+\.\d+$' })
$interfaceLine = @($toc | Where-Object { $_ -match '^## Interface: \d+(?:,\s*\d+)*$' })
if ($versionLine.Count -ne 1 -or $interfaceLine.Count -ne 1) {
    throw "Expected a numeric Interface and a major.minor.patch Version in $tocPath"
}

$version = $versionLine[0].Substring('## Version: '.Length)
$files = [ordered]@{}
foreach ($file in (Get-ChildItem -LiteralPath $sourceRoot -File -Recurse | Sort-Object FullName)) {
    $relative = [IO.Path]::GetRelativePath($sourceRoot, $file.FullName).Replace('\', '/')
    $files.Add("$name/$relative", $file.FullName)
}
$licenseEntry = "$name/LICENSE.txt"
if (!$files.Contains($licenseEntry)) {
    $files.Add($licenseEntry, (Join-Path $root 'LICENSE'))
}

$loadFiles = 0
foreach ($line in $toc) {
    $relative = $line.Trim().Replace('\', '/')
    if (!$relative -or $relative.StartsWith('#')) { continue }
    if ($relative -cnotmatch '^(?:[A-Za-z0-9_][A-Za-z0-9_. -]*/)*[A-Za-z0-9_][A-Za-z0-9_. -]*\.(?:lua|xml)$') {
        throw "Invalid TOC file path $line"
    }
    if ("$name/$relative" -cnotin $files.Keys) { throw "Missing TOC file $relative in $sourceRoot" }
    $loadFiles++
}
if (!$loadFiles) { throw "No load files declared in $tocPath" }

function Test-Package([string]$Path) {
    $archive = [IO.Compression.ZipFile]::OpenRead($Path)
    try {
        if ($archive.Entries.Count -ne $files.Count) { throw 'Unexpected ZIP file count' }
        foreach ($entryName in $files.Keys) {
            $entry = $archive.GetEntry($entryName)
            if (!$entry) { throw "Missing ZIP entry $entryName" }
            $stream = $entry.Open()
            try {
                $actual = (Get-FileHash -InputStream $stream -Algorithm SHA256).Hash
            } finally {
                $stream.Dispose()
            }
            $expected = (Get-FileHash -LiteralPath $files[$entryName] -Algorithm SHA256).Hash
            if ($actual -ne $expected) { throw "ZIP contents differ for $entryName" }
        }
    } finally {
        $archive.Dispose()
    }
}

$dist = Join-Path $root 'dist'
$zip = Join-Path $dist "$name-$version.zip"
if ($Verify) {
    Test-Package $zip
} else {
    New-Item -ItemType Directory -Path $dist -Force | Out-Null
    $tempZip = Join-Path $dist ([Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        $archive = [IO.Compression.ZipFile]::Open($tempZip, [IO.Compression.ZipArchiveMode]::Create)
        try {
            foreach ($entryName in $files.Keys) {
                $entry = $archive.CreateEntry($entryName, [IO.Compression.CompressionLevel]::Optimal)
                $entry.LastWriteTime = [DateTimeOffset]::new(2000, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
                $inputFile = [IO.File]::OpenRead($files[$entryName])
                try {
                    $outputStream = $entry.Open()
                    try { $inputFile.CopyTo($outputStream) }
                    finally { $outputStream.Dispose() }
                } finally {
                    $inputFile.Dispose()
                }
            }
        } finally {
            $archive.Dispose()
        }
        Test-Package $tempZip
        [IO.File]::Move($tempZip, $zip, $true)
    } finally {
        if (Test-Path -LiteralPath $tempZip -PathType Leaf) { Remove-Item -LiteralPath $tempZip }
    }
}

Write-Output "Verified $($files.Count) files in $zip"
