@echo off
REM Copyright (c) 2026 Turbowallpaper. All rights reserved.
REM One-click setup launcher for the native TurboWallpaper background app.
set SCRIPT_DIR=%~dp0
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Install-TurboWallpaper.ps1"
pause
