# TurboWallpaper™

TurboWallpaper is a native Windows background app from **Turbowallpaper** that places an image, GIF, MP4, or WMV wallpaper behind the desktop icons while keeping the taskbar and desktop apps usable.

Copyright © 2026 Turbowallpaper™. All rights reserved.

## What changed from a script runner

- TurboWallpaper now builds and installs as `TurboWallpaper.exe`, a real Windows Forms background application.
- The setup starts the installed executable directly, so closing the installer or command prompt does **not** close the wallpaper.
- The app stays available from the Windows system tray for settings, restart, library access, and exit.
- Startup launch uses the Windows `Run` registry key to start the installed executable as a background app.

## Features

- Select `.jpg`, `.jpeg`, `.png`, `.bmp`, `.gif`, `.mp4`, or `.wmv` files from the local library or any folder.
- Minimal settings UI for wallpaper selection, resolution preset, scale/aspect ratio, lightweight video upscaling, visual effect, and startup launch.
- Uses the Windows desktop `WorkerW` layer so desktop icons and normal application windows remain on top.
- Does not hide or cover the Windows taskbar.
- Single-instance tray app to prevent multiple wallpaper engines from stacking.
- Lightweight design using Windows Forms and native Windows browser/media components rather than a bundled browser runtime.
- Optional low-resolution video smoothing and CSS-based Vivid/Cinema/Glow effects that avoid extra decoding buffers or heavy image-processing libraries.

> Memory use depends on the chosen media, codec, resolution, GPU/driver, and Windows media stack. The enhancement controls are CSS/browser-compositor based, so they are much lighter than CPU frame processing, but very large GIFs and high-resolution videos can still exceed 20-30 MB because decoder buffers are controlled by Windows.

## Requirements

- Windows 10 or Windows 11.
- .NET Framework 4.8 runtime.
- To build from source during setup: .NET SDK or Visual Studio Build Tools/MSBuild.

## Setup and install

1. Download or clone this repository.
2. Double-click:

   ```text
   setup\Setup-TurboWallpaper.cmd
   ```

   Or run the installer manually:

   ```powershell
   .\setup\Install-TurboWallpaper.ps1
   ```

3. The installer builds `TurboWallpaper.exe` if needed, copies it to `%LOCALAPPDATA%\TurboWallpaper`, creates Start Menu/Desktop shortcuts, and launches the app.
4. Closing the setup command window after installation will not close TurboWallpaper because the installed executable is a separate background app.

## Using TurboWallpaper

1. Open **TurboWallpaper** from the desktop shortcut, Start Menu shortcut, or system tray icon.
2. Click **Open library** to add wallpaper files to `%LOCALAPPDATA%\TurboWallpaper\Library`, or click **Select** to choose any supported file.
3. Choose a scale/aspect mode:
   - **Fill**: fills the wallpaper area while preserving video aspect ratio.
   - **Fit**: shows the full video without cropping.
   - **Stretch**: fills the wallpaper area without preserving aspect ratio.
   - **Center**: centers images without scaling.
4. Choose a video effect:
   - **None**: lowest overhead.
   - **Vivid**: small contrast/saturation lift.
   - **Cinema**: slightly deeper contrast with a subtle vignette overlay.
   - **Glow**: brighter pop with a very light compositor drop shadow.
5. Enable **Upscale low-resolution videos with browser smoothing** if smaller videos look blocky on larger displays.
6. Choose a resolution preset. **Auto** is recommended because it uses the primary display bounds.
7. Enable **Start TurboWallpaper with Windows as a background app** to launch at sign-in.
8. Click **Save & run**.

## System tray

Right-click the tray icon to:

- Open **Settings**.
- **Restart wallpaper** after replacing a file.
- **Open library**.
- **Exit** the background app.

## Build manually

```powershell
.\setup\Build-TurboWallpaper.ps1
```

The output is written to:

```text
dist\TurboWallpaper\TurboWallpaper.exe
```

## Uninstall

Run:

```powershell
.\setup\Uninstall-TurboWallpaper.ps1
```

This stops the app, removes the startup registry entry, deletes shortcuts, and removes `%LOCALAPPDATA%\TurboWallpaper`.

## Files

- `src/TurboWallpaper/TurboWallpaper.csproj` - Windows Forms project for the native app.
- `src/TurboWallpaper/Program.cs` - tray app, settings UI, lightweight video upscaling/effects, desktop wallpaper host, startup registration, and config logic.
- `setup/Build-TurboWallpaper.ps1` - build script for `TurboWallpaper.exe`.
- `setup/Install-TurboWallpaper.ps1` - setup script that builds if needed, installs files, creates shortcuts, and launches the app.
- `setup/Setup-TurboWallpaper.cmd` - one-click setup launcher.
- `setup/Uninstall-TurboWallpaper.ps1` - uninstall script.
- `setup/TurboWallpaper.iss` - optional Inno Setup definition for producing `TurboWallpaperSetup.exe` after publishing.
