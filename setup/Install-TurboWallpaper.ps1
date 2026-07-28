# Copyright (c) 2026 Turbowallpaper. All rights reserved.
# Installer for the native TurboWallpaper background app.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$AppName = 'TurboWallpaper'
$Root = Split-Path -Parent $PSScriptRoot
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
$LibraryDir = Join-Path $InstallDir 'Library'
$DistDir = Join-Path $Root 'dist\TurboWallpaper'
$Exe = Join-Path $DistDir 'TurboWallpaper.exe'
$DesktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) "$AppName.lnk"
$StartMenuDir = Join-Path ([Environment]::GetFolderPath('Programs')) $AppName
$StartMenuShortcut = Join-Path $StartMenuDir "$AppName.lnk"

if (-not (Test-Path $Exe)) {
    & (Join-Path $PSScriptRoot 'Build-TurboWallpaper.ps1')
}

if (-not (Test-Path $Exe)) {
    throw "Build completed but $Exe was not found."
}

Get-CimInstance Win32_Process -Filter "Name = 'TurboWallpaper.exe'" -ErrorAction SilentlyContinue |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

New-Item -ItemType Directory -Force -Path $InstallDir, $LibraryDir, $StartMenuDir | Out-Null
Copy-Item -Path (Join-Path $DistDir '*') -Destination $InstallDir -Recurse -Force
Copy-Item -Path (Join-Path $Root 'README.md') -Destination (Join-Path $InstallDir 'README.md') -Force
$InstalledExe = Join-Path $InstallDir 'TurboWallpaper.exe'

$shell = New-Object -ComObject WScript.Shell
foreach ($shortcutPath in @($DesktopShortcut, $StartMenuShortcut)) {
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $InstalledExe
    $shortcut.Arguments = '--settings'
    $shortcut.WorkingDirectory = $InstallDir
    $shortcut.IconLocation = $InstalledExe
    $shortcut.Description = 'Configure and run TurboWallpaper live wallpaper'
    $shortcut.Save()
}

Start-Process -FilePath $InstalledExe -ArgumentList '--settings' -WorkingDirectory $InstallDir
Write-Host 'TurboWallpaper installed and launched successfully.'
Write-Host "Install location: $InstallDir"
Write-Host 'The app keeps running from the system tray; closing this setup window will not close the wallpaper.'
