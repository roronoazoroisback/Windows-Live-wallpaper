; Copyright (c) 2026 Turbowallpaper. All rights reserved.
; Optional Inno Setup definition for building a Windows installer after publishing.

#define MyAppName "TurboWallpaper"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Turbowallpaper"
#define MyAppExeName "TurboWallpaper.exe"

[Setup]
AppId={{E29379A4-3A44-4C18-9F71-6AF96D3917A2}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\dist\installer
OutputBaseFilename=TurboWallpaperSetup
Compression=lzma
SolidCompression=yes
PrivilegesRequired=lowest
WizardStyle=modern

[Files]
Source: "..\dist\TurboWallpaper\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--settings"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--settings"

[Run]
Filename: "{app}\{#MyAppExeName}"; Parameters: "--settings"; Description: "Launch TurboWallpaper"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "taskkill"; Parameters: "/IM TurboWallpaper.exe /F"; Flags: runhidden

[Registry]
Root: HKCU; Subkey: "Software\Turbowallpaper\TurboWallpaper"; ValueType: string; ValueName: "InstallDir"; ValueData: "{app}"; Flags: uninsdeletekey

[UninstallDelete]
Type: files; Name: "{userstartup}\{#MyAppName}.lnk"
Type: files; Name: "{app}\TurboWallpaper.ps1"
Type: filesandordirs; Name: "{app}"
