# TurboWallpaper™

TurboWallpaper is a lightweight native Windows live wallpaper app from **Turbowallpaper**. It installs as `TurboWallpaper.exe`, stays resident in the notification tray, and renders an image, GIF, MP4, or WMV wallpaper behind the desktop icons, taskbar, Start menu, and normal desktop apps.

Copyright © 2026 Turbowallpaper™. All rights reserved.

## Features

- Native Windows executable instead of a command-line PowerShell runner.
- Tray-first behavior: startup can run directly in the background, and closing or minimizing the settings window keeps the wallpaper alive in the notification tray; use the tray menu to open settings, restart the wallpaper, open the library, or exit.
- Places the wallpaper on the Windows WorkerW desktop layer with a no-activate, bottom-positioned window so desktop icons, the taskbar, Start menu, and application windows stay above it without changing taskbar auto-hide settings.
- Select wallpaper files from a local library or any folder.
- Supports `.jpg`, `.jpeg`, `.png`, `.bmp`, `.gif`, `.mp4`, and `.wmv`.
- Keeps the existing upscaling/effect features for low-resolution video: browser smoothing, vivid/cinema/glow modes, resolution presets, and scale/aspect controls.
- Uses built-in .NET WinForms and Windows media/browser components to avoid bundling a heavy runtime.
- Starts with Windows through the current-user Run registry key as a minimized background tray app when enabled.
- Installer and uninstaller clean up files from the older PowerShell architecture if they are present.

> Performance depends on the selected media file, decoder, resolution, and Windows version. Static images are the lightest. Well-encoded 1080p H.264 MP4 files usually provide the best live-video balance. Very large GIFs or 4K videos can exceed the 30 MB / 1-2% CPU target because Windows decoders allocate memory and GPU resources outside the app process.

## Requirements

- Windows 10 or Windows 11.
- .NET Framework 4.8 runtime, which is built into current Windows 10/11 installs or available through Windows Update.
- .NET SDK or Visual Studio Build Tools only if you build from source.
- Built-in Windows media/browser components enabled for MP4/WMV live wallpapers.

## Install

1. Download or clone this repository.
2. Double-click `setup\Setup-TurboWallpaper.cmd` for the graphical setup wizard. The wizard lets you choose the app install folder, the local wallpaper library/download folder, and whether TurboWallpaper should start with Windows. You can also run the PowerShell installer manually:

   ```powershell
   .\setup\Install-TurboWallpaper.ps1 -InstallDir "$env:LOCALAPPDATA\TurboWallpaper" -LibraryDir "$env:LOCALAPPDATA\TurboWallpaper\Library"
   ```

   The installer publishes `src\TurboWallpaper\TurboWallpaper.csproj` if `dist\TurboWallpaper\TurboWallpaper.exe` does not already exist.

3. Open **TurboWallpaper** from the desktop or Start Menu shortcut.
4. Click **Open library** to add wallpaper files to the configured library folder, click **Copy to library** to keep a selected file local, or click **Select** to choose any supported file.
5. Pick a scale/aspect mode:
   - **Fill**: optimized default that preserves aspect ratio and fills the screen.
   - **Fit**: preserves aspect ratio and shows the entire file.
   - **Stretch**: fills the screen without preserving aspect ratio.
   - **Center**: centers the file without scaling.
6. Choose a resolution preset if desired. **Auto** is recommended for best performance.
7. Enable **Start TurboWallpaper with Windows as a background app** if you want tray startup.
8. Click **Save and run**.

## Run manually

Open settings:

```powershell
%LOCALAPPDATA%\TurboWallpaper\TurboWallpaper.exe --settings
```

Run directly as the tray/background wallpaper app:

```powershell
%LOCALAPPDATA%\TurboWallpaper\TurboWallpaper.exe --background
```

Uninstall from the executable:

```powershell
%LOCALAPPDATA%\TurboWallpaper\TurboWallpaper.exe --uninstall
```

## Performance tips

- Prefer static images or 1080p MP4 files encoded with hardware-friendly H.264 for best performance.
- Avoid very large GIF files; GIF playback can use more CPU than video.
- Use **Auto** resolution and **Fill** scaling for the best balance of quality and speed.
- Disable visual effects if you need the lowest CPU/GPU usage.
- Keep wallpaper files local rather than on a network drive.
- Close other wallpaper apps before starting TurboWallpaper.

## Uninstall

Run:

```powershell
.\setup\Uninstall-TurboWallpaper.ps1
```

You can also run `TurboWallpaper.exe --uninstall` from the install directory. The uninstaller stops the tray app, removes the installed executable files, the desktop shortcut, the Start Menu shortcut, the startup Run entry, old startup shortcuts, and legacy `TurboWallpaper.ps1` files if present.

## Files

- `src/TurboWallpaper/Program.cs` - native tray app, settings UI, live wallpaper host, startup manager, and executable uninstaller entry point.
- `src/TurboWallpaper/TurboWallpaper.csproj` - Windows executable project.
- `setup/Setup-TurboWallpaper.cmd` - one-click graphical setup launcher.
- `setup/TurboWallpaper-Setup-GUI.ps1` - Windows Forms setup wizard for choosing install and wallpaper library folders.
- `setup/Install-TurboWallpaper.ps1` - setup script that builds/copies the executable and shortcuts while removing legacy script artifacts.
- `setup/Uninstall-TurboWallpaper.ps1` - uninstaller that removes executable and legacy installs.
- `setup/TurboWallpaper.iss` - optional Inno Setup definition for a packaged installer.
