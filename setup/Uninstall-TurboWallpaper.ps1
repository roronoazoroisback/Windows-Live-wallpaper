# Copyright (c) 2026 Turbowallpaper. All rights reserved.
# Uninstaller for TurboWallpaper.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$AppName = 'TurboWallpaper'
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
$StartupShortcut = Join-Path ([Environment]::GetFolderPath('Startup')) "$AppName.lnk"
$DesktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) "$AppName.lnk"
$StartMenuDir = Join-Path ([Environment]::GetFolderPath('Programs')) $AppName

Get-CimInstance Win32_Process -Filter "Name = 'TurboWallpaper.exe'" -ErrorAction SilentlyContinue |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $AppName -Force -ErrorAction SilentlyContinue
Remove-Item -Path $StartupShortcut, $DesktopShortcut -Force -ErrorAction SilentlyContinue
Remove-Item -Path $StartMenuDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'TurboWallpaper uninstalled successfully.'
