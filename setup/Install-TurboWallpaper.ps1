# Copyright (c) 2026 Turbowallpaper. All rights reserved.
# Installer for TurboWallpaper.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$AppName = 'TurboWallpaper'
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
$SourceRoot = Split-Path -Parent $PSScriptRoot
$SourceApp = Join-Path $SourceRoot 'TurboWallpaper.ps1'
$TargetApp = Join-Path $InstallDir 'TurboWallpaper.ps1'
$LibraryDir = Join-Path $InstallDir 'Library'
$DesktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) "$AppName.lnk"
$StartMenuDir = Join-Path ([Environment]::GetFolderPath('Programs')) $AppName
$StartMenuShortcut = Join-Path $StartMenuDir "$AppName.lnk"

New-Item -ItemType Directory -Force -Path $InstallDir, $LibraryDir, $StartMenuDir | Out-Null
Copy-Item -Path $SourceApp -Destination $TargetApp -Force
Copy-Item -Path (Join-Path $SourceRoot 'README.md') -Destination (Join-Path $InstallDir 'README.md') -Force

$shell = New-Object -ComObject WScript.Shell
foreach ($shortcutPath in @($DesktopShortcut, $StartMenuShortcut)) {
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = 'powershell.exe'
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$TargetApp`" -Configure"
    $shortcut.WorkingDirectory = $InstallDir
    $shortcut.IconLocation = 'shell32.dll,13'
    $shortcut.Description = 'Configure and run TurboWallpaper live wallpaper'
    $shortcut.Save()
}

Write-Host 'TurboWallpaper installed successfully.'
Write-Host "Install location: $InstallDir"
Write-Host 'Use the desktop or Start Menu shortcut to select a wallpaper and enable startup launch.'
