# Copyright (c) 2026 Turbowallpaper. All rights reserved.
# Builds the TurboWallpaper Windows Forms executable for setup packaging.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$Project = Join-Path $Root 'src\TurboWallpaper\TurboWallpaper.csproj'
$Output = Join-Path $Root 'dist\TurboWallpaper'
New-Item -ItemType Directory -Force -Path $Output | Out-Null

if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    dotnet publish $Project -c Release -o $Output --nologo
    exit $LASTEXITCODE
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

& $msbuild.Source $Project /p:Configuration=Release /p:OutputPath=$Output\
exit $LASTEXITCODE
