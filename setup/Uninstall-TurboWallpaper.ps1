# Copyright (c) 2026 Turbowallpaper. All rights reserved.
# Uninstaller for TurboWallpaper.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$AppName = 'TurboWallpaper'
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
$StartupShortcut = Join-Path ([Environment]::GetFolderPath('Startup')) "$AppName.lnk"
$DesktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) "$AppName.lnk"
$StartMenuDir = Join-Path ([Environment]::GetFolderPath('Programs')) $AppName

Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' OR Name = 'pwsh.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like "*$AppName*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Remove-Item -Path $StartupShortcut, $DesktopShortcut -Force -ErrorAction SilentlyContinue
Remove-Item -Path $StartMenuDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'TurboWallpaper uninstalled successfully.'
