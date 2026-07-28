# Copyright (c) 2026 Turbowallpaper. All rights reserved.
# Graphical installer for the TurboWallpaper native Windows executable.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Root = Split-Path -Parent $PSScriptRoot
$DefaultInstallDir = Join-Path $env:LOCALAPPDATA 'TurboWallpaper'
$DefaultLibraryDir = Join-Path $DefaultInstallDir 'Library'

$form = New-Object Windows.Forms.Form
$form.Text = 'TurboWallpaper Setup'
$form.Width = 680
$form.Height = 390
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$title = New-Object Windows.Forms.Label
$title.Text = 'TurboWallpaper Setup'
$title.Font = New-Object Drawing.Font('Segoe UI', 16, [Drawing.FontStyle]::Bold)
$title.SetBounds(20, 18, 430, 34)
$form.Controls.Add($title)

$intro = New-Object Windows.Forms.Label
$intro.Text = 'Install the executable wallpaper app, choose where app files go, and optionally copy downloaded wallpapers into a local library.'
$intro.SetBounds(20, 58, 620, 38)
$form.Controls.Add($intro)

$installLabel = New-Object Windows.Forms.Label
$installLabel.Text = 'Install folder'
$installLabel.SetBounds(20, 112, 120, 22)
$form.Controls.Add($installLabel)

$installBox = New-Object Windows.Forms.TextBox
$installBox.Text = $DefaultInstallDir
$installBox.SetBounds(145, 110, 390, 24)
$form.Controls.Add($installBox)

$installBrowse = New-Object Windows.Forms.Button
$installBrowse.Text = 'Browse...'
$installBrowse.SetBounds(545, 108, 90, 28)
$installBrowse.Add_Click({
    $dialog = New-Object Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Choose where TurboWallpaper executable files should be installed.'
    $dialog.SelectedPath = $installBox.Text
    if ($dialog.ShowDialog($form) -eq [Windows.Forms.DialogResult]::OK) { $installBox.Text = $dialog.SelectedPath }
})
$form.Controls.Add($installBrowse)

$libraryLabel = New-Object Windows.Forms.Label
$libraryLabel.Text = 'Wallpaper library'
$libraryLabel.SetBounds(20, 152, 120, 22)
$form.Controls.Add($libraryLabel)

$libraryBox = New-Object Windows.Forms.TextBox
$libraryBox.Text = $DefaultLibraryDir
$libraryBox.SetBounds(145, 150, 390, 24)
$form.Controls.Add($libraryBox)

$libraryBrowse = New-Object Windows.Forms.Button
$libraryBrowse.Text = 'Browse...'
$libraryBrowse.SetBounds(545, 148, 90, 28)
$libraryBrowse.Add_Click({
    $dialog = New-Object Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Choose where downloaded wallpaper files should be stored.'
    $dialog.SelectedPath = $libraryBox.Text
    if ($dialog.ShowDialog($form) -eq [Windows.Forms.DialogResult]::OK) { $libraryBox.Text = $dialog.SelectedPath }
})
$form.Controls.Add($libraryBrowse)

$startup = New-Object Windows.Forms.CheckBox
$startup.Text = 'Start TurboWallpaper with Windows minimized in the tray'
$startup.Checked = $true
$startup.SetBounds(145, 192, 390, 24)
$form.Controls.Add($startup)

$status = New-Object Windows.Forms.Label
$status.Text = 'Ready to install.'
$status.SetBounds(20, 245, 620, 22)
$form.Controls.Add($status)

$installButton = New-Object Windows.Forms.Button
$installButton.Text = 'Install'
$installButton.SetBounds(435, 292, 95, 32)
$installButton.Add_Click({
    try {
        $status.Text = 'Installing...'
        $form.Refresh()
        & (Join-Path $PSScriptRoot 'Install-TurboWallpaper.ps1') -InstallDir $installBox.Text -LibraryDir $libraryBox.Text -StartWithWindows:$startup.Checked
        if ($LASTEXITCODE -ne 0) { throw 'Installer returned an error.' }
        [Windows.Forms.MessageBox]::Show($form, 'TurboWallpaper was installed successfully.', 'TurboWallpaper Setup', 'OK', 'Information') | Out-Null
        $form.Close()
    } catch {
        $status.Text = 'Install failed.'
        [Windows.Forms.MessageBox]::Show($form, $_.Exception.Message, 'TurboWallpaper Setup', 'OK', 'Error') | Out-Null
    }
})
$form.Controls.Add($installButton)

$cancelButton = New-Object Windows.Forms.Button
$cancelButton.Text = 'Cancel'
$cancelButton.SetBounds(540, 292, 95, 32)
$cancelButton.Add_Click({ $form.Close() })
$form.Controls.Add($cancelButton)

[void]$form.ShowDialog()
