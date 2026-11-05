$ErrorActionPreference = "Stop"

$AddonName = "BetterClickCasting"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$TocPath = Join-Path $RepoRoot "$AddonName.toc"

# Version aus der .toc auslesen
$Version = "0.3.0"
if (Test-Path $TocPath) {
    $VersionLine = Select-String -Path $TocPath -Pattern "^##\s*Version:\s*(.+)$" | Select-Object -First 1
    if ($VersionLine) {
        $Version = $VersionLine.Matches[0].Groups[1].Value.Trim()
    }
}

$DistDir = Join-Path $RepoRoot "dist"
$StagingRoot = Join-Path $DistDir "_staging"
$StagingAddonDir = Join-Path $StagingRoot $AddonName
$ZipFilePath = Join-Path $DistDir "$AddonName-$Version.zip"

if (Test-Path $StagingRoot) {
    Remove-Item -Recurse -Force $StagingRoot
}
if (Test-Path $ZipFilePath) {
    Remove-Item -Force $ZipFilePath
}

New-Item -ItemType Directory -Force -Path $StagingAddonDir | Out-Null

# Nur echte AddOn-Dateien ins CurseForge-ZIP kopieren (ohne Assets/CurseForgeLogo.png)
$IncludeItems = @(
    "$AddonName.toc",
    "$AddonName.lua",
    "LICENSE",
    "CHANGELOG.md",
    "Locales",
    "Core",
    "Modules"
)

foreach ($Item in $IncludeItems) {
    $SourcePath = Join-Path $RepoRoot $Item
    if (Test-Path $SourcePath) {
        Copy-Item -Recurse -Force -Path $SourcePath -Destination $StagingAddonDir
    }
}

Compress-Archive -Path $StagingAddonDir -DestinationPath $ZipFilePath -Force
Remove-Item -Recurse -Force $StagingRoot

Write-Host "CurseForge Release-ZIP erfolgreich erstellt: $ZipFilePath" -ForegroundColor Green
