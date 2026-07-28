# Copyright (c) 2026 Turbowallpaper. All rights reserved.
# Installer for the TurboWallpaper native Windows executable.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$AppName = 'TurboWallpaper'
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
$LibraryDir = Join-Path $InstallDir 'Library'
$SourceRoot = Split-Path -Parent $PSScriptRoot
$Project = Join-Path $SourceRoot 'src\TurboWallpaper\TurboWallpaper.csproj'
$PublishedDir = Join-Path $SourceRoot 'dist\TurboWallpaper'
$SourceExe = Join-Path $PublishedDir 'TurboWallpaper.exe'
$TargetExe = Join-Path $InstallDir 'TurboWallpaper.exe'
$DesktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) "$AppName.lnk"
$StartMenuDir = Join-Path ([Environment]::GetFolderPath('Programs')) $AppName
$StartMenuShortcut = Join-Path $StartMenuDir "$AppName.lnk"
$StartupShortcut = Join-Path ([Environment]::GetFolderPath('Startup')) "$AppName.lnk"

function Stop-TurboWallpaper {
    Get-Process -Name $AppName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' OR Name = 'pwsh.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*$AppName*" } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Publish-AppIfNeeded {
    if (Test-Path $SourceExe) { return }

    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        & dotnet publish $Project -c Release -o $PublishedDir --nologo
        if ($LASTEXITCODE -ne 0) { throw 'dotnet publish failed.' }
        return
    }

    $msbuild = Get-Command msbuild.exe -ErrorAction SilentlyContinue
    if (-not $msbuild) {
        $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
        if (Test-Path $vswhere) {
            $install = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
            $candidate = Join-Path $install 'MSBuild\Current\Bin\MSBuild.exe'
            if (Test-Path $candidate) { $msbuild = Get-Command $candidate }
        }
    }

    if (-not $msbuild) {
        throw 'Install .NET SDK or Visual Studio Build Tools with MSBuild to build TurboWallpaper.exe.'
    }

    & $msbuild.Source $Project /p:Configuration=Release /p:OutputPath=$PublishedDir\
    if ($LASTEXITCODE -ne 0) { throw 'MSBuild failed.' }
}

Stop-TurboWallpaper
Publish-AppIfNeeded

New-Item -ItemType Directory -Force -Path $InstallDir, $LibraryDir, $StartMenuDir | Out-Null
Copy-Item -Path (Join-Path $PublishedDir '*') -Destination $InstallDir -Recurse -Force
Copy-Item -Path (Join-Path $SourceRoot 'README.md') -Destination (Join-Path $InstallDir 'README.md') -Force

# Remove files/shortcuts from the legacy PowerShell architecture without deleting the user's library or config.
Remove-Item -Path (Join-Path $InstallDir 'TurboWallpaper.ps1'), $StartupShortcut -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $AppName -ErrorAction SilentlyContinue

$shell = New-Object -ComObject WScript.Shell
foreach ($shortcutPath in @($DesktopShortcut, $StartMenuShortcut)) {
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $TargetExe
    $shortcut.Arguments = '--settings'
    $shortcut.WorkingDirectory = $InstallDir
    $shortcut.IconLocation = $TargetExe
    $shortcut.Description = 'Configure and run TurboWallpaper live wallpaper'
    $shortcut.Save()
}

Write-Host 'TurboWallpaper executable installed successfully.'
Write-Host "Install location: $InstallDir"
Write-Host 'Use the desktop or Start Menu shortcut to select a wallpaper and enable tray startup.'
