# TurboWallpaper™

TurboWallpaper is a lightweight Windows live wallpaper script from **Turbowallpaper**. It runs in the background and can place an image, GIF, MP4, or WMV wallpaper behind the desktop icons.

Copyright © 2026 Turbowallpaper™. All rights reserved.

## Features

- Select wallpaper files from a local library or any folder.
- Supports `.jpg`, `.jpeg`, `.png`, `.bmp`, `.gif`, `.mp4`, and `.wmv`.
- Minimal UI with only wallpaper selection, resolution preset, scale/aspect ratio, and startup launch.
- Designed to stay lightweight by using built-in Windows PowerShell, .NET WinForms, and native Windows browser/media components instead of bundling a heavy runtime.
- Optional Windows startup shortcut launches the optimized background runner with a hidden PowerShell window.

> Memory use depends on the selected media file, decoder, resolution, and Windows version. Small images/GIFs are usually lightest; high-resolution video can exceed 30 MB because Windows media decoding allocates memory outside the script.

## Requirements

- Windows 10 or Windows 11.
- Windows PowerShell 5.1.
- Built-in Windows media/browser components enabled for MP4/WMV live wallpapers.

## Install

1. Download or clone this repository.
2. Double-click `setup\Setup-TurboWallpaper.cmd`, or run the PowerShell installer manually:

   ```powershell
   .\setup\Install-TurboWallpaper.ps1
   ```

3. Open **TurboWallpaper** from the desktop or Start Menu shortcut.
4. Click **Open library** to add wallpaper files to `%LOCALAPPDATA%\TurboWallpaper\Library`, or click **Select wallpaper** to choose any supported file.
5. Pick a scale/aspect mode:
   - **Fill**: optimized default that preserves aspect ratio and fills the screen.
   - **Fit**: preserves aspect ratio and shows the entire file.
   - **Stretch**: fills the screen without preserving aspect ratio.
   - **Center**: centers the file without scaling.
6. Choose a resolution preset if desired. **Auto** is recommended for best performance.
7. Enable **Launch optimized wallpaper at Windows startup** if you want TurboWallpaper to start automatically.
8. Click **Save and run**.

## Run manually

Configure the wallpaper:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\TurboWallpaper.ps1 -Configure
```

Run the wallpaper in the background:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File .\TurboWallpaper.ps1 -Run
```

Enable startup launch:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\TurboWallpaper.ps1 -InstallStartup
```

Disable startup launch:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\TurboWallpaper.ps1 -RemoveStartup
```

## Performance tips

- Prefer 1080p MP4 files encoded with hardware-friendly H.264 for best performance.
- Avoid very large GIF files; GIF playback can use more CPU than video.
- Use **Auto** resolution and **Fill** scaling for the best balance of quality and speed.
- Keep wallpaper files local rather than on a network drive.
- Close other wallpaper apps before starting TurboWallpaper.

## Uninstall

Run:

```powershell
.\setup\Uninstall-TurboWallpaper.ps1
```

This removes the installed app files, desktop shortcut, Start Menu shortcut, and startup shortcut.

## Files

- `TurboWallpaper.ps1` - main live wallpaper app and settings UI.
- `setup/Setup-TurboWallpaper.cmd` - one-click setup launcher.
- `setup/Install-TurboWallpaper.ps1` - setup script that installs the app and shortcuts.
- `setup/Uninstall-TurboWallpaper.ps1` - uninstall script.
