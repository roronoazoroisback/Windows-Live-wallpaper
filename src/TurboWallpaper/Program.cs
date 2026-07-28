// Copyright (c) 2026 Turbowallpaper. All rights reserved.
// TurboWallpaper - native Windows background live wallpaper app.

using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Threading;
using System.Runtime.InteropServices;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Windows.Forms;
using Microsoft.Win32;

namespace TurboWallpaper
{
    internal static class Program
    {
        [STAThread]
        private static void Main(string[] args)
        {
            using (var single = new Mutex(true, "Turbowallpaper.TurboWallpaper.SingleInstance", out var isFirst))
            {
                if (!isFirst)
                {
                    MessageSender.NotifyExistingInstance(args);
                    return;
                }

                if (Array.Exists(args, a => a.Equals("--uninstall", StringComparison.OrdinalIgnoreCase)))
                {
                    Uninstaller.RunAndExit();
                    return;
                }

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                if (Array.Exists(args, a => a.Equals("--setup", StringComparison.OrdinalIgnoreCase)))
                {
                    Application.Run(new SetupWizardForm());
                    return;
                }

                Application.Run(new WallpaperApplicationContext(args));
            }
        }
    }

    internal sealed class WallpaperApplicationContext : ApplicationContext
    {
        private readonly NotifyIcon trayIcon;
        private readonly System.Windows.Forms.Timer memoryTrimTimer;
        private WallpaperForm wallpaperForm;
        private SettingsForm settingsForm;
        private readonly EventHandler settingsRequestedHandler;

        public WallpaperApplicationContext(string[] args)
        {
            AppPaths.EnsureFolders();
            trayIcon = new NotifyIcon
            {
                Text = "TurboWallpaper",
                Icon = SystemIcons.Application,
                Visible = true,
                ContextMenuStrip = CreateMenu()
            };
            trayIcon.DoubleClick += (_, __) => ShowSettings();
            settingsRequestedHandler = (_, __) => ShowSettings();
            MessageSender.SettingsRequested += settingsRequestedHandler;

            memoryTrimTimer = new System.Windows.Forms.Timer { Interval = 60000 };
            memoryTrimTimer.Tick += (_, __) => NativeMethods.TrimWorkingSet();
            memoryTrimTimer.Start();

            var config = WallpaperConfig.Load();
            var backgroundOnly = Array.Exists(args, a => a.Equals("--background", StringComparison.OrdinalIgnoreCase));
            if (!backgroundOnly && (args.Length == 0 || Array.Exists(args, a => a.Equals("--settings", StringComparison.OrdinalIgnoreCase))))
            {
                ShowSettings();
            }

            if (!string.IsNullOrWhiteSpace(config.WallpaperPath) && File.Exists(config.WallpaperPath))
            {
                StartWallpaper(config);
            }
        }

        private ContextMenuStrip CreateMenu()
        {
            var menu = new ContextMenuStrip();
            menu.Items.Add("Settings", null, (_, __) => ShowSettings());
            menu.Items.Add("Restart wallpaper", null, (_, __) => StartWallpaper(WallpaperConfig.Load()));
            menu.Items.Add("Open library", null, (_, __) => Process.Start("explorer.exe", AppPaths.LibraryDir));
            menu.Items.Add("Exit", null, (_, __) => ExitThread());
            return menu;
        }

        private void ShowSettings()
        {
            if (settingsForm != null && !settingsForm.IsDisposed)
            {
                settingsForm.Show();
                settingsForm.WindowState = FormWindowState.Normal;
                settingsForm.Activate();
                return;
            }

            settingsForm = new SettingsForm();
            settingsForm.FormClosed += (_, __) => settingsForm = null;
            if (settingsForm.ShowDialog() == DialogResult.OK)
            {
                var config = WallpaperConfig.Load();
                StartupManager.SetEnabled(config.StartWithWindows);
                StartWallpaper(config);
            }
        }

        private void StartWallpaper(WallpaperConfig config)
        {
            if (string.IsNullOrWhiteSpace(config.WallpaperPath) || !File.Exists(config.WallpaperPath))
            {
                return;
            }

            wallpaperForm?.Close();
            wallpaperForm?.Dispose();
            wallpaperForm = new WallpaperForm(config);
            wallpaperForm.Show();
            wallpaperForm.SendBehindDesktopIcons();
        }

        protected override void ExitThreadCore()
        {
            trayIcon.Visible = false;
            memoryTrimTimer.Stop();
            memoryTrimTimer.Dispose();
            trayIcon.Dispose();
            MessageSender.SettingsRequested -= settingsRequestedHandler;
            wallpaperForm?.Close();
            wallpaperForm?.Dispose();
            base.ExitThreadCore();
        }
    }

    internal sealed class SettingsForm : Form
    {
        private readonly TextBox wallpaperPath = new TextBox();
        private readonly ComboBox scaleMode = new ComboBox();
        private readonly ComboBox resolution = new ComboBox();
        private readonly CheckBox startWithWindows = new CheckBox();
        private readonly CheckBox upscaleLowResolutionVideo = new CheckBox();
        private readonly ComboBox effectMode = new ComboBox();

        public SettingsForm()
        {
            Text = "TurboWallpaper Settings";
            Width = 660;
            Height = 465;
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = true;

            var config = WallpaperConfig.Load();
            Controls.Add(new Label { Text = "TurboWallpaper™", Font = new Font("Segoe UI", 16, FontStyle.Bold), Left = 20, Top = 16, Width = 360 });
            Controls.Add(new Label { Text = "Wallpaper", Left = 20, Top = 70, Width = 120 });
            wallpaperPath.SetBounds(140, 68, 370, 24);
            wallpaperPath.Text = config.WallpaperPath;
            Controls.Add(wallpaperPath);

            var browse = new Button { Text = "Select", Left = 520, Top = 66, Width = 95, Height = 28 };
            browse.Click += (_, __) => SelectWallpaper();
            Controls.Add(browse);

            Controls.Add(new Label { Text = "Scale / aspect", Left = 20, Top = 112, Width = 120 });
            scaleMode.DropDownStyle = ComboBoxStyle.DropDownList;
            scaleMode.Items.AddRange(new object[] { "Fill", "Fit", "Stretch", "Center" });
            scaleMode.SelectedItem = string.IsNullOrWhiteSpace(config.ScaleMode) ? "Fill" : config.ScaleMode;
            scaleMode.SetBounds(140, 110, 160, 24);
            Controls.Add(scaleMode);

            Controls.Add(new Label { Text = "Resolution", Left = 20, Top = 150, Width = 120 });
            resolution.DropDownStyle = ComboBoxStyle.DropDownList;
            resolution.Items.AddRange(new object[] { "Auto", "1280x720", "1920x1080", "2560x1440", "3840x2160" });
            resolution.SelectedItem = string.IsNullOrWhiteSpace(config.Resolution) ? "Auto" : config.Resolution;
            resolution.SetBounds(140, 148, 160, 24);
            Controls.Add(resolution);

            Controls.Add(new Label { Text = "Effect", Left = 20, Top = 188, Width = 120 });
            effectMode.DropDownStyle = ComboBoxStyle.DropDownList;
            effectMode.Items.AddRange(new object[] { "None", "Vivid", "Cinema", "Glow" });
            effectMode.SelectedItem = string.IsNullOrWhiteSpace(config.EffectMode) ? "None" : config.EffectMode;
            effectMode.SetBounds(140, 186, 160, 24);
            Controls.Add(effectMode);

            upscaleLowResolutionVideo.Text = "Upscale low-resolution videos with browser smoothing";
            upscaleLowResolutionVideo.Checked = config.UpscaleLowResolutionVideo;
            upscaleLowResolutionVideo.SetBounds(20, 226, 420, 24);
            Controls.Add(upscaleLowResolutionVideo);

            startWithWindows.Text = "Start TurboWallpaper with Windows as a background app";
            startWithWindows.Checked = config.StartWithWindows;
            startWithWindows.SetBounds(20, 260, 420, 24);
            Controls.Add(startWithWindows);

            var library = new Button { Text = "Open library", Left = 285, Top = 302, Width = 105, Height = 32 };
            library.Click += (_, __) => Process.Start("explorer.exe", AppPaths.LibraryDir);
            Controls.Add(library);

            var copy = new Button { Text = "Copy to library", Left = 400, Top = 302, Width = 105, Height = 32 };
            copy.Click += (_, __) => CopyCurrentWallpaperToLibrary();
            Controls.Add(copy);

            var save = new Button { Text = "Save && run", Left = 510, Top = 302, Width = 105, Height = 32 };
            save.Click += (_, __) => SaveAndClose();
            Controls.Add(save);

            Controls.Add(new Label { Text = "Close or minimize this window any time; the wallpaper keeps running in the tray.", Left = 20, Top = 348, Width = 590 });
            Controls.Add(new Label { Text = "© 2026 Turbowallpaper™. All rights reserved.", Left = 20, Top = 382, Width = 360 });
        }

        private void SelectWallpaper()
        {
            using (var dialog = new OpenFileDialog())
            {
                dialog.Title = "Select live wallpaper";
                dialog.Filter = "Wallpaper files|*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.mp4;*.wmv|All files|*.*";
                dialog.InitialDirectory = Directory.Exists(AppPaths.LibraryDir) ? AppPaths.LibraryDir : Environment.GetFolderPath(Environment.SpecialFolder.MyPictures);
                if (dialog.ShowDialog(this) == DialogResult.OK)
                {
                    wallpaperPath.Text = dialog.FileName;
                }
            }
        }

        private void CopyCurrentWallpaperToLibrary()
        {
            var source = wallpaperPath.Text.Trim();
            if (string.IsNullOrWhiteSpace(source) || !File.Exists(source))
            {
                MessageBox.Show(this, "Select a valid wallpaper file first.", "TurboWallpaper", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            AppPaths.EnsureFolders();
            var destination = Path.Combine(AppPaths.LibraryDir, Path.GetFileName(source));
            File.Copy(source, destination, true);
            wallpaperPath.Text = destination;
            MessageBox.Show(this, "Wallpaper copied to the local library.", "TurboWallpaper", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        protected override void OnResize(EventArgs e)
        {
            base.OnResize(e);
            if (WindowState == FormWindowState.Minimized)
            {
                Hide();
            }
        }

        private void SaveAndClose()
        {
            var config = new WallpaperConfig
            {
                WallpaperPath = wallpaperPath.Text.Trim(),
                ScaleMode = Convert.ToString(scaleMode.SelectedItem) ?? "Fill",
                Resolution = Convert.ToString(resolution.SelectedItem) ?? "Auto",
                EffectMode = Convert.ToString(effectMode.SelectedItem) ?? "None",
                UpscaleLowResolutionVideo = upscaleLowResolutionVideo.Checked,
                StartWithWindows = startWithWindows.Checked,
                LibraryDir = AppPaths.LibraryDir
            };
            config.Save();
            DialogResult = DialogResult.OK;
            Close();
        }
    }

    internal sealed class WallpaperForm : Form
    {
        private readonly WallpaperConfig config;

        public WallpaperForm(WallpaperConfig config)
        {
            this.config = config;
            ShowInTaskbar = false;
            FormBorderStyle = FormBorderStyle.None;
            StartPosition = FormStartPosition.Manual;
            BackColor = Color.Black;
            Bounds = DisplayBounds.For(config.Resolution);
            TopMost = false;
            LoadContent();
        }

        private void LoadContent()
        {
            var extension = Path.GetExtension(config.WallpaperPath).ToLowerInvariant();
            if (extension == ".mp4" || extension == ".wmv")
            {
                var browser = new WebBrowser
                {
                    Dock = DockStyle.Fill,
                    ScrollBarsEnabled = false,
                    IsWebBrowserContextMenuEnabled = false,
                    AllowWebBrowserDrop = false
                };
                Controls.Add(browser);
                Shown += (_, __) => browser.DocumentText = VideoHtml(config);
                FormClosed += (_, __) => browser.Dispose();
                return;
            }

            var picture = new PictureBox
            {
                Dock = DockStyle.Fill,
                BackColor = Color.Black,
                SizeMode = ImageSizeMode(config.ScaleMode),
                ImageLocation = config.WallpaperPath
            };
            FormClosed += (_, __) =>
            {
                var image = picture.Image;
                picture.ImageLocation = null;
                picture.Dispose();
                image?.Dispose();
            };
            Controls.Add(picture);
        }

        public void SendBehindDesktopIcons()
        {
            var desktop = NativeMethods.GetWorkerW();
            NativeMethods.SetParent(Handle, desktop);
            NativeMethods.SetWindowLong(Handle, NativeMethods.GWL_EXSTYLE, NativeMethods.GetWindowLong(Handle, NativeMethods.GWL_EXSTYLE) | NativeMethods.WS_EX_TOOLWINDOW | NativeMethods.WS_EX_NOACTIVATE);
            NativeMethods.SetWindowPos(Handle, NativeMethods.HWND_BOTTOM, Bounds.X, Bounds.Y, Bounds.Width, Bounds.Height, NativeMethods.SWP_NOACTIVATE | NativeMethods.SWP_SHOWWINDOW);
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == NativeMethods.WM_DISPLAYCHANGE)
            {
                Bounds = DisplayBounds.For(config.Resolution);
                SendBehindDesktopIcons();
            }

            base.WndProc(ref m);
        }

        private static PictureBoxSizeMode ImageSizeMode(string scaleMode)
        {
            switch (scaleMode)
            {
                case "Stretch": return PictureBoxSizeMode.StretchImage;
                case "Center": return PictureBoxSizeMode.CenterImage;
                default: return PictureBoxSizeMode.Zoom;
            }
        }

        private static string VideoHtml(WallpaperConfig config)
        {
            var uri = WebUtility.HtmlEncode(new Uri(config.WallpaperPath).AbsoluteUri);
            var fit = config.ScaleMode == "Fit" ? "contain" : config.ScaleMode == "Stretch" ? "fill" : "cover";
            var filter = VideoFilter(config.EffectMode);
            var overlay = config.EffectMode == "Glow" || config.EffectMode == "Cinema"
                ? "<div class='overlay'></div>"
                : string.Empty;
            var upscaleScript = config.UpscaleLowResolutionVideo
                ? "<script>var v=document.getElementById('wallpaper');v.onloadedmetadata=function(){if(v.videoWidth<screen.width||v.videoHeight<screen.height){v.className='upscale';}};</script>"
                : string.Empty;

            return "<!doctype html><html><head><meta http-equiv='X-UA-Compatible' content='IE=edge'>" +
                   "<style>html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#000}" +
                   "video{width:100%;height:100%;object-fit:" + fit + ";background:#000;filter:" + filter + ";}" +
                   "video.upscale{image-rendering:auto;transform:translateZ(0) scale(1.003);}" +
                   ".overlay{position:fixed;inset:0;pointer-events:none;background:radial-gradient(circle at center,rgba(255,255,255,.08),rgba(0,0,0,.18) 70%,rgba(0,0,0,.32));mix-blend-mode:screen}</style></head>" +
                   "<body><video id='wallpaper' autoplay loop muted playsinline src='" + uri + "'></video>" + overlay + upscaleScript + "</body></html>";
        }

        private static string VideoFilter(string effectMode)
        {
            switch (effectMode)
            {
                case "Vivid": return "contrast(1.08) saturate(1.22) brightness(1.03)";
                case "Cinema": return "contrast(1.12) saturate(1.08) brightness(.96)";
                case "Glow": return "contrast(1.06) saturate(1.18) brightness(1.06) drop-shadow(0 0 14px rgba(255,255,255,.20))";
                default: return "none";
            }
        }
    }


    internal static class MessageSender
    {
        public static event EventHandler SettingsRequested;

        public static void NotifyExistingInstance(string[] args)
        {
            if (Array.Exists(args, a => a.Equals("--settings", StringComparison.OrdinalIgnoreCase)) || args.Length == 0)
            {
                SettingsRequested?.Invoke(null, EventArgs.Empty);
            }
        }
    }

    internal sealed class SetupWizardForm : Form
    {
        public SetupWizardForm()
        {
            Text = "TurboWallpaper Setup";
            Width = 560;
            Height = 260;
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;

            Controls.Add(new Label { Text = "TurboWallpaper setup", Font = new Font("Segoe UI", 16, FontStyle.Bold), Left = 20, Top = 18, Width = 360 });
            Controls.Add(new Label { Text = "Install the executable app, create shortcuts, and choose where downloaded wallpaper files are stored.", Left = 20, Top = 60, Width = 500 });

            var install = new TextBox { Left = 20, Top = 100, Width = 390, Text = AppPaths.AppDir };
            var browse = new Button { Text = "Install folder...", Left = 420, Top = 98, Width = 100 };
            browse.Click += (_, __) => { using (var d = new FolderBrowserDialog()) { d.SelectedPath = install.Text; if (d.ShowDialog(this) == DialogResult.OK) install.Text = d.SelectedPath; } };
            Controls.Add(install);
            Controls.Add(browse);

            var run = new Button { Text = "Open installer script", Left = 340, Top = 150, Width = 180, Height = 32 };
            run.Click += (_, __) =>
            {
                AppPaths.EnsureFolders();
                Process.Start("explorer.exe", AppPaths.AppDir);
                MessageBox.Show(this, "Use setup\\TurboWallpaper-Setup-GUI.ps1 from the downloaded source to install to a custom folder. The app library is ready at " + AppPaths.LibraryDir, "TurboWallpaper Setup");
            };
            Controls.Add(run);
        }
    }

    [DataContract]
    internal sealed class WallpaperConfig
    {
        [DataMember] public string WallpaperPath { get; set; } = string.Empty;
        [DataMember] public string Resolution { get; set; } = "Auto";
        [DataMember] public string ScaleMode { get; set; } = "Fill";
        [DataMember] public string EffectMode { get; set; } = "None";
        [DataMember] public bool UpscaleLowResolutionVideo { get; set; } = true;
        [DataMember] public bool StartWithWindows { get; set; }
        [DataMember] public string LibraryDir { get; set; } = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "TurboWallpaper", "Library");

        public static WallpaperConfig Load()
        {
            try
            {
                if (File.Exists(AppPaths.ConfigPath))
                {
                    using (var stream = File.OpenRead(AppPaths.ConfigPath))
                    {
                        var serializer = new DataContractJsonSerializer(typeof(WallpaperConfig));
                        return serializer.ReadObject(stream) as WallpaperConfig ?? new WallpaperConfig();
                    }
                }
            }
            catch
            {
                return new WallpaperConfig();
            }

            return new WallpaperConfig();
        }

        public void Save()
        {
            AppPaths.EnsureFolders();
            using (var stream = File.Create(AppPaths.ConfigPath))
            {
                var serializer = new DataContractJsonSerializer(typeof(WallpaperConfig));
                serializer.WriteObject(stream, this);
            }
        }
    }

    internal static class AppPaths
    {
        public static readonly string AppDir = Path.GetDirectoryName(Application.ExecutablePath) ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "TurboWallpaper");
        public static string LibraryDir
        {
            get
            {
                try
                {
                    if (File.Exists(ConfigPath))
                    {
                        var json = File.ReadAllText(ConfigPath);
                        var marker = "\"LibraryDir\":\"";
                        var start = json.IndexOf(marker, StringComparison.OrdinalIgnoreCase);
                        if (start >= 0)
                        {
                            start += marker.Length;
                            var end = json.IndexOf("\"", start, StringComparison.Ordinal);
                            if (end > start)
                            {
                                return json.Substring(start, end - start).Replace("\\\\", "\\");
                            }
                        }
                    }
                }
                catch
                {
                    // Fall back to the default local library.
                }

                return Path.Combine(AppDir, "Library");
            }
        }
        public static readonly string ConfigPath = Path.Combine(AppDir, "config.json");
        public static readonly string ExePath = Application.ExecutablePath;
        public static readonly string StartupShortcut = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Startup), "TurboWallpaper.lnk");

        public static void EnsureFolders()
        {
            Directory.CreateDirectory(AppDir);
            Directory.CreateDirectory(LibraryDir);
        }
    }

    internal static class StartupManager
    {
        private const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";

        public static void SetEnabled(bool enabled)
        {
            using (var key = Registry.CurrentUser.OpenSubKey(RunKey, true))
            {
                if (enabled)
                {
                    key?.SetValue("TurboWallpaper", "\"" + AppPaths.ExePath + "\" --background");
                }
                else
                {
                    key?.DeleteValue("TurboWallpaper", false);
                }
            }

            if (!enabled && File.Exists(AppPaths.StartupShortcut))
            {
                File.Delete(AppPaths.StartupShortcut);
            }
        }
    }

    internal static class DisplayBounds
    {
        public static Rectangle For(string resolution)
        {
            var screen = SystemInformation.VirtualScreen;
            if (string.IsNullOrWhiteSpace(resolution) || resolution == "Auto")
            {
                return screen;
            }

            var parts = resolution.Split('x');
            if (parts.Length == 2 && int.TryParse(parts[0], out var requestedWidth) && int.TryParse(parts[1], out var requestedHeight))
            {
                var width = Math.Min(requestedWidth, screen.Width);
                var height = Math.Min(requestedHeight, screen.Height);
                var x = screen.X + (screen.Width - width) / 2;
                var y = screen.Y + (screen.Height - height) / 2;
                return new Rectangle(x, y, width, height);
            }

            return screen;
        }
    }

    internal static class Uninstaller
    {
        public static void RunAndExit()
        {
            var script = Path.Combine(Path.GetTempPath(), "TurboWallpaper-Uninstall.cmd");
            var appDir = AppPaths.AppDir;
            var desktopShortcut = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Desktop), "TurboWallpaper.lnk");
            var startMenuDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), "TurboWallpaper");
            var commands = string.Join(Environment.NewLine, new[]
            {
                "@echo off",
                "timeout /t 1 /nobreak >nul",
                "taskkill /IM TurboWallpaper.exe /F >nul 2>nul",
                "reg delete HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run /v TurboWallpaper /f >nul 2>nul",
                "del /f /q \"" + desktopShortcut + "\" >nul 2>nul",
                "del /f /q \"" + AppPaths.StartupShortcut + "\" >nul 2>nul",
                "rmdir /s /q \"" + startMenuDir + "\" >nul 2>nul",
                "rmdir /s /q \"" + appDir + "\" >nul 2>nul",
                "del /f /q \"" + script + "\" >nul 2>nul"
            });
            File.WriteAllText(script, commands);
            Process.Start(new ProcessStartInfo("cmd.exe", "/c \"" + script + "\"") { CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden });
        }
    }

    internal static class NativeMethods
    {
        public const uint SWP_NOACTIVATE = 0x0010;
        public const uint SWP_SHOWWINDOW = 0x0040;
        public const int GWL_EXSTYLE = -20;
        public const int WS_EX_TOOLWINDOW = 0x00000080;
        public const int WS_EX_NOACTIVATE = 0x08000000;
        public static readonly IntPtr HWND_BOTTOM = new IntPtr(1);
        public const int WM_DISPLAYCHANGE = 0x007E;
        private static IntPtr workerW = IntPtr.Zero;

        public delegate bool EnumWindowsProc(IntPtr topHandle, IntPtr topParamHandle);

        [DllImport("user32.dll", SetLastError = true)] private static extern IntPtr FindWindow(string className, string windowName);
        [DllImport("user32.dll", SetLastError = true)] private static extern IntPtr FindWindowEx(IntPtr parentHandle, IntPtr childAfter, string className, string windowTitle);
        [DllImport("user32.dll")] private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);
        [DllImport("user32.dll", SetLastError = true)] private static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam, uint flags, uint timeout, out IntPtr result);
        [DllImport("user32.dll", SetLastError = true)] public static extern IntPtr SetParent(IntPtr child, IntPtr newParent);
        [DllImport("user32.dll", SetLastError = true)] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr insertAfter, int x, int y, int cx, int cy, uint flags);
        [DllImport("user32.dll", SetLastError = true)] public static extern int GetWindowLong(IntPtr hWnd, int index);
        [DllImport("user32.dll", SetLastError = true)] public static extern int SetWindowLong(IntPtr hWnd, int index, int newLong);
        [DllImport("psapi.dll")] private static extern int EmptyWorkingSet(IntPtr processHandle);

        public static IntPtr GetWorkerW()
        {
            var progman = FindWindow("Progman", null);
            SendMessageTimeout(progman, 0x052C, IntPtr.Zero, IntPtr.Zero, 0, 1000, out _);
            workerW = IntPtr.Zero;
            EnumWindows((topHandle, _) =>
            {
                var shellView = FindWindowEx(topHandle, IntPtr.Zero, "SHELLDLL_DefView", null);
                if (shellView != IntPtr.Zero)
                {
                    workerW = FindWindowEx(IntPtr.Zero, topHandle, "WorkerW", null);
                }
                return true;
            }, IntPtr.Zero);

            return workerW == IntPtr.Zero ? progman : workerW;
        }

        public static void TrimWorkingSet()
        {
            try
            {
                EmptyWorkingSet(Process.GetCurrentProcess().Handle);
            }
            catch
            {
                // Best-effort memory trimming only.
            }
        }
    }
}
