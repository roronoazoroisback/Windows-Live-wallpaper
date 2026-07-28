# Copyright (c) 2026 Turbowallpaper. All rights reserved.
# TurboWallpaper - lightweight live wallpaper runner for Windows.
# Supports image, GIF, and MP4/WMV wallpaper files selected from a local library.

param(
    [switch]$Configure,
    [switch]$Run,
    [switch]$InstallStartup,
    [switch]$RemoveStartup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$CompanyName = 'Turbowallpaper'
$AppName = 'TurboWallpaper'
$AppDir = Join-Path $env:LOCALAPPDATA $AppName
$LibraryDir = Join-Path $AppDir 'Library'
$ConfigPath = Join-Path $AppDir 'config.json'
$StartupPath = Join-Path ([Environment]::GetFolderPath('Startup')) "$AppName.lnk"

function Initialize-AppFolders {
    New-Item -ItemType Directory -Force -Path $AppDir, $LibraryDir | Out-Null
}

function Get-DefaultConfig {
    [pscustomobject]@{
        WallpaperPath = ''
        Resolution = 'Auto'
        ScaleMode = 'Fill'
        StartWithWindows = $false
        Muted = $true
    }
}

function Read-Config {
    Initialize-AppFolders
    if (Test-Path $ConfigPath) {
        try {
            return Get-Content $ConfigPath -Raw | ConvertFrom-Json
        } catch {
            return Get-DefaultConfig
        }
    }
    return Get-DefaultConfig
}

function Save-Config([object]$Config) {
    Initialize-AppFolders
    $Config | ConvertTo-Json -Depth 5 | Set-Content -Path $ConfigPath -Encoding UTF8
}

function Get-ScriptPath {
    if ($PSCommandPath) { return $PSCommandPath }
    return $MyInvocation.MyCommand.Path
}

function Set-StartupShortcut([bool]$Enabled) {
    Initialize-AppFolders
    if ($Enabled) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($StartupPath)
        $shortcut.TargetPath = 'powershell.exe'
        $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$(Get-ScriptPath)`" -Run"
        $shortcut.WorkingDirectory = Split-Path -Parent (Get-ScriptPath)
        $shortcut.IconLocation = 'shell32.dll,13'
        $shortcut.Save()
    } elseif (Test-Path $StartupPath) {
        Remove-Item $StartupPath -Force
    }
}

if ($InstallStartup) {
    $config = Read-Config
    $config.StartWithWindows = $true
    Save-Config $config
    Set-StartupShortcut $true
    return
}

if ($RemoveStartup) {
    $config = Read-Config
    $config.StartWithWindows = $false
    Save-Config $config
    Set-StartupShortcut $false
    return
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$nativeSource = @'
using System;
using System.Runtime.InteropServices;
public static class TurboWallpaperNative {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    [DllImport("user32.dll")] public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
    [DllImport("user32.dll")] public static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hWndNewParent);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
}
'@
Add-Type -TypeDefinition $nativeSource

function Get-DesktopWorkerW {
    $progman = [TurboWallpaperNative]::FindWindow('Progman', $null)
    $result = [IntPtr]::Zero
    [TurboWallpaperNative]::SendMessageTimeout($progman, 0x052C, [IntPtr]::Zero, [IntPtr]::Zero, 0, 1000, [ref]$result) | Out-Null

    $worker = [IntPtr]::Zero
    $callback = [TurboWallpaperNative+EnumWindowsProc]{
        param([IntPtr]$topHandle, [IntPtr]$param)
        $shellView = [TurboWallpaperNative]::FindWindowEx($topHandle, [IntPtr]::Zero, 'SHELLDLL_DefView', $null)
        if ($shellView -ne [IntPtr]::Zero) {
            $script:FoundWorkerW = [TurboWallpaperNative]::FindWindowEx([IntPtr]::Zero, $topHandle, 'WorkerW', $null)
        }
        return $true
    }
    $script:FoundWorkerW = [IntPtr]::Zero
    [TurboWallpaperNative]::EnumWindows($callback, [IntPtr]::Zero) | Out-Null
    if ($script:FoundWorkerW -ne [IntPtr]::Zero) { $worker = $script:FoundWorkerW }
    if ($worker -eq [IntPtr]::Zero) { $worker = $progman }
    return $worker
}

function Get-WallpaperFiles {
    Initialize-AppFolders
    Get-ChildItem -Path $LibraryDir -File -Include *.jpg,*.jpeg,*.png,*.bmp,*.gif,*.mp4,*.wmv -ErrorAction SilentlyContinue |
        Sort-Object Name
}

function Show-Configurator {
    $config = Read-Config
    $form = New-Object Windows.Forms.Form
    $form.Text = "$AppName - $CompanyName"
    $form.Width = 640
    $form.Height = 330
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false

    $title = New-Object Windows.Forms.Label
    $title.Text = 'TurboWallpaper Settings'
    $title.Font = New-Object Drawing.Font('Segoe UI', 14, [Drawing.FontStyle]::Bold)
    $title.SetBounds(18, 16, 400, 30)
    $form.Controls.Add($title)

    $pathBox = New-Object Windows.Forms.TextBox
    $pathBox.SetBounds(20, 70, 475, 24)
    $pathBox.Text = [string]$config.WallpaperPath
    $form.Controls.Add($pathBox)

    $browse = New-Object Windows.Forms.Button
    $browse.Text = 'Select wallpaper'
    $browse.SetBounds(505, 68, 105, 28)
    $browse.Add_Click({
        $dialog = New-Object Windows.Forms.OpenFileDialog
        $dialog.Title = 'Select image, GIF, or video wallpaper'
        $dialog.Filter = 'Wallpaper files|*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.mp4;*.wmv|All files|*.*'
        $dialog.InitialDirectory = $LibraryDir
        if ($dialog.ShowDialog() -eq 'OK') { $pathBox.Text = $dialog.FileName }
    })
    $form.Controls.Add($browse)

    $scaleLabel = New-Object Windows.Forms.Label
    $scaleLabel.Text = 'Scale / aspect ratio'
    $scaleLabel.SetBounds(20, 118, 150, 22)
    $form.Controls.Add($scaleLabel)

    $scale = New-Object Windows.Forms.ComboBox
    $scale.DropDownStyle = 'DropDownList'
    [void]$scale.Items.AddRange(@('Fill','Fit','Stretch','Center'))
    $scale.SelectedItem = if ($config.ScaleMode) { [string]$config.ScaleMode } else { 'Fill' }
    $scale.SetBounds(170, 116, 150, 24)
    $form.Controls.Add($scale)

    $resLabel = New-Object Windows.Forms.Label
    $resLabel.Text = 'Resolution'
    $resLabel.SetBounds(20, 154, 150, 22)
    $form.Controls.Add($resLabel)

    $resolution = New-Object Windows.Forms.ComboBox
    $resolution.DropDownStyle = 'DropDownList'
    [void]$resolution.Items.AddRange(@('Auto','1280x720','1920x1080','2560x1440','3840x2160'))
    $resolution.SelectedItem = if ($config.Resolution) { [string]$config.Resolution } else { 'Auto' }
    $resolution.SetBounds(170, 152, 150, 24)
    $form.Controls.Add($resolution)

    $startup = New-Object Windows.Forms.CheckBox
    $startup.Text = 'Launch optimized wallpaper at Windows startup'
    $startup.Checked = [bool]$config.StartWithWindows
    $startup.SetBounds(20, 190, 360, 24)
    $form.Controls.Add($startup)

    $save = New-Object Windows.Forms.Button
    $save.Text = 'Save and run'
    $save.SetBounds(390, 230, 105, 32)
    $save.Add_Click({
        $newConfig = [pscustomobject]@{
            WallpaperPath = $pathBox.Text
            Resolution = $resolution.SelectedItem
            ScaleMode = $scale.SelectedItem
            StartWithWindows = $startup.Checked
            Muted = $true
        }
        Save-Config $newConfig
        Set-StartupShortcut $startup.Checked
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$(Get-ScriptPath)`" -Run"
        $form.Close()
    })
    $form.Controls.Add($save)

    $openLibrary = New-Object Windows.Forms.Button
    $openLibrary.Text = 'Open library'
    $openLibrary.SetBounds(275, 230, 105, 32)
    $openLibrary.Add_Click({ Start-Process explorer.exe $LibraryDir })
    $form.Controls.Add($openLibrary)

    $copyright = New-Object Windows.Forms.Label
    $copyright.Text = '© 2026 Turbowallpaper™. All rights reserved.'
    $copyright.SetBounds(20, 252, 320, 22)
    $form.Controls.Add($copyright)

    [void]$form.ShowDialog()
}

function Get-ImageSizeMode([string]$ScaleMode) {
    switch ($ScaleMode) {
        'Fit' { return [Windows.Forms.PictureBoxSizeMode]::Zoom }
        'Stretch' { return [Windows.Forms.PictureBoxSizeMode]::StretchImage }
        'Center' { return [Windows.Forms.PictureBoxSizeMode]::CenterImage }
        default { return [Windows.Forms.PictureBoxSizeMode]::Zoom }
    }
}


function Get-TargetBounds([object]$Config) {
    $screen = [Windows.Forms.Screen]::PrimaryScreen.Bounds
    if (-not $Config.Resolution -or [string]$Config.Resolution -eq 'Auto') { return $screen }
    if ([string]$Config.Resolution -match '^(\d+)x(\d+)$') {
        $width = [Math]::Min([int]$Matches[1], $screen.Width)
        $height = [Math]::Min([int]$Matches[2], $screen.Height)
        $x = $screen.X + [int](($screen.Width - $width) / 2)
        $y = $screen.Y + [int](($screen.Height - $height) / 2)
        return New-Object Drawing.Rectangle($x, $y, $width, $height)
    }
    return $screen
}

function Start-Wallpaper {
    $config = Read-Config
    if (-not $config.WallpaperPath -or -not (Test-Path ([string]$config.WallpaperPath))) {
        Show-Configurator
        return
    }

    $bounds = Get-TargetBounds $config
    $form = New-Object Windows.Forms.Form
    $form.Text = $AppName
    $form.FormBorderStyle = 'None'
    $form.ShowInTaskbar = $false
    $form.StartPosition = 'Manual'
    $form.Bounds = $bounds
    $form.BackColor = [Drawing.Color]::Black

    $ext = [IO.Path]::GetExtension([string]$config.WallpaperPath).ToLowerInvariant()
    if ($ext -in @('.mp4','.wmv')) {
        $browser = New-Object Windows.Forms.WebBrowser
        $browser.Dock = 'Fill'
        $browser.ScrollBarsEnabled = $false
        $browser.IsWebBrowserContextMenuEnabled = $false
        $browser.AllowWebBrowserDrop = $false
        $form.Controls.Add($browser)

        $videoPath = ([Uri]([string]$config.WallpaperPath)).AbsoluteUri
        $fit = if ([string]$config.ScaleMode -eq 'Fit') { 'contain' } elseif ([string]$config.ScaleMode -eq 'Stretch') { 'fill' } else { 'cover' }
        $html = @"
<!doctype html><html><head><meta http-equiv='X-UA-Compatible' content='IE=edge'>
<style>html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#000}video{width:100%;height:100%;object-fit:$fit;background:#000}</style>
</head><body><video autoplay loop muted playsinline src='$videoPath'></video></body></html>
"@
        $form.Add_Shown({ $browser.DocumentText = $html })
        $form.Add_FormClosed({ $browser.Dispose() })
    } else {
        $picture = New-Object Windows.Forms.PictureBox
        $picture.Dock = 'Fill'
        $picture.BackColor = [Drawing.Color]::Black
        $picture.SizeMode = Get-ImageSizeMode ([string]$config.ScaleMode)
        $picture.ImageLocation = [string]$config.WallpaperPath
        $form.Controls.Add($picture)
    }

    $form.Add_Shown({
        $desktop = Get-DesktopWorkerW
        [TurboWallpaperNative]::SetParent($form.Handle, $desktop) | Out-Null
        [TurboWallpaperNative]::SetWindowPos($form.Handle, [IntPtr]::Zero, $bounds.X, $bounds.Y, $bounds.Width, $bounds.Height, 0x0040) | Out-Null
    })

    [Windows.Forms.Application]::EnableVisualStyles()
    [Windows.Forms.Application]::Run($form)
}

if ($Configure -or -not $Run) { Show-Configurator } else { Start-Wallpaper }
