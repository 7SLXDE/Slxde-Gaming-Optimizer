using SlxdeOptimizer.App.Services;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Management;
using System.Security.Principal;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace SlxdeOptimizer.App;

public partial class MainWindow : Window
{

    private void UpdateStatus(string message)
    {
        try
        {
            if (!Dispatcher.CheckAccess())
            {
                Dispatcher.Invoke(() => UpdateStatus(message));
                return;
            }

            var text = message ?? string.Empty;

            if (FindName("StatusText") is TextBlock statusText)
            {
                statusText.Text = text;
                return;
            }

            if (FindName("TxtStatus") is TextBlock txtStatus)
            {
                txtStatus.Text = text;
                return;
            }

            if (FindName("StatusValue") is TextBlock statusValue)
            {
                statusValue.Text = text;
                return;
            }
        }
        catch
        {
            // ignore status rendering failures
        }
    }

    private bool _slxdePerformanceModeEnabled;
    private string _slxdePerformanceModeCpuMode = "Auto";
    private int _slxdeActiveGames = 0;

    private readonly PowerShellRunner _runner = new();
    private readonly List<Button> _sidebarButtons = new();
    private readonly Dictionary<string, CheckBox> _debloatChecks = new();
    private System.Windows.Controls.Primitives.UniformGrid? _debloatOptionsGrid;
    private string? _cachedCpuName;
    private string? _cachedGpuName;
    private string? _cachedInstalledRam;
    private string? _cachedWindowsSummary;
    private bool _updateInProgress;

    public MainWindow()
    {
        InitializeComponent();
        SetupSidebar();
        LoadDashboard();
        UpdateAdminStatus();
    }

    private void SetupSidebar()
    {
        _sidebarButtons.AddRange(new[]
        {
            BtnDashboard, BtnWindows, BtnGpu, BtnNetwork, BtnController, BtnGameConfigs, BtnDebloat, BtnCleanup, BtnQuality, BtnBackup
        });

        SetSidebarButton(BtnDashboard, "nav_dashboard", "Dashboard");
        SetSidebarButton(BtnWindows, "nav_windows", "Windows");
        SetSidebarButton(BtnGpu, "nav_gpu", "GPU");
        SetSidebarButton(BtnNetwork, "nav_network", "Network");
        SetSidebarButton(BtnController, "nav_controller", "Controller / KBM");
        SetSidebarButton(BtnGameConfigs, "nav_gameconfigs", "Game Configs");
        SetSidebarButton(BtnDebloat, "nav_debloat", "Debloat");
        SetSidebarButton(BtnCleanup, "nav_cleanup", "Clean-up / Health");
        SetSidebarButton(BtnQuality, "nav_quality", "Quality of Life");
        SetSidebarButton(BtnBackup, "nav_backup", "Backup / Restore");
    }
    private static readonly IReadOnlyDictionary<string, string> IconPaths =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["nav_dashboard"] = "M3,11 L12,3 L21,11 M5,10 V21 H10 V15 H14 V21 H19 V10",
            ["nav_windows"] = "M4,4 H10 V10 H4 Z M14,4 H20 V10 H14 Z M4,14 H10 V20 H4 Z M14,14 H20 V20 H14 Z",
            ["nav_gpu"] = "M7,4 H17 C18.7,4 20,5.3 20,7 V17 C20,18.7 18.7,20 17,20 H7 C5.3,20 4,18.7 4,17 V7 C4,5.3 5.3,4 7,4 Z M9,9 H15 V15 H9 Z M2,8 H4 M2,12 H4 M2,16 H4 M20,8 H22 M20,12 H22 M20,16 H22 M8,2 V4 M12,2 V4 M16,2 V4 M8,20 V22 M12,20 V22 M16,20 V22",
            ["nav_network"] = "M4,20 V16 H7 V20 Z M10.5,20 V11 H13.5 V20 Z M17,20 V5 H20 V20 Z",
            ["nav_controller"] = "M2,8 H14 V16 H2 Z M4,11 H5 M7,11 H8 M10,11 H12 M4,14 H12 M18,7 C16.3,7 15,8.3 15,10 V15 C15,16.7 16.3,18 18,18 C19.7,18 21,16.7 21,15 V10 C21,8.3 19.7,7 18,7 Z M18,7 V11",
            ["nav_gameconfigs"] = "M4,6 H9 M13,6 H20 M11,4 V8 M4,12 H14 M18,12 H20 M16,10 V14 M4,18 H7 M11,18 H20 M9,16 V20",
            ["nav_debloat"] = "M12,3 L13.5,8.5 L19,10 L13.5,11.5 L12,17 L10.5,11.5 L5,10 L10.5,8.5 Z M19,3 V7 M17,5 H21 M5,16 V20 M3,18 H7",
            ["nav_cleanup"] = "M12,3 L20,6 V11 C20,16 16.8,19.5 12,21 C7.2,19.5 4,16 4,11 V6 Z M9,12 L11,14 L15,10",
            ["nav_quality"] = "M12,8 C9.8,8 8,9.8 8,12 C8,14.2 9.8,16 12,16 C14.2,16 16,14.2 16,12 C16,9.8 14.2,8 12,8 Z M12,2 V5 M12,19 V22 M2,12 H5 M19,12 H22 M4.9,4.9 L7,7 M17,17 L19.1,19.1 M19.1,4.9 L17,7 M7,17 L4.9,19.1",
            ["nav_backup"] = "M7,18 H18 C20.2,18 22,16.2 22,14 C22,11.8 20.2,10 18,10 C17.4,6.6 14.5,4 11,4 C7.6,4 4.7,6.5 4.1,9.8 C2.3,10.4 1,12 1,14 C1,16.2 2.8,18 5,18 H7",
            ["terminal"] = "M3,5 H21 V19 H3 Z M7,9 L10,12 L7,15 M12,15 H17",
            ["activity"] = "M3,12 H7 L9,7 L13,17 L16,11 H21",
            ["document"] = "M6,3 H15 L19,7 V21 H6 Z M15,3 V7 H19 M9,12 H16 M9,16 H16",
            ["balance"] = "M4,7 H20 M6,12 H18 M8,17 H16",
            ["bolt"] = "M13,2 L5,14 H11 L10,22 L19,9 H13 Z",
            ["videooff"] = "M12,3 V12 M6.5,6.5 C3.5,9.5 3.5,14.5 6.3,17.7 C9.5,21 14.5,21 17.7,17.7 C20.5,14.5 20.5,9.5 17.5,6.5",
            ["windowsrestore"] = "M9,4 L4,9 L9,14 M5,9 H14 C19,9 22,12 22,16 C22,20 19,22 14,22 H4",
            ["monitor"] = "M3,4 H21 V16 H3 Z M8,20 H16 M12,16 V20",
            ["memory"] = "M3,7 H21 V17 H3 Z M6,10 V14 M10,10 V14 M14,10 V14 M18,10 V14 M6,17 V20 M10,17 V20 M14,17 V20 M18,17 V20",
            ["pin"] = "M12,21 C12,21 6,15 6,10 C6,6.7 8.7,4 12,4 C15.3,4 18,6.7 18,10 C18,15 12,21 12,21 Z M12,8 C10.9,8 10,8.9 10,10 C10,11.1 10.9,12 12,12 C13.1,12 14,11.1 14,10 C14,8.9 13.1,8 12,8 Z",
            ["check"] = "M4,12 L9,17 L20,6",
            ["restore"] = "M9,4 L4,9 L9,14 M5,9 H14 C19,9 22,12 22,16 C22,20 19,22 14,22 H4",
            ["usb"] = "M2,6 H13 C16,6 18,8.3 18,12 C18,15.7 16,18 13,18 H2 Z M18,9 H22 V15 H18 Z M20,10 V12 M22,10 V12",
            ["mouse"] = "M12,3 C8.7,3 6,5.7 6,9 V15 C6,18.3 8.7,21 12,21 C15.3,21 18,18.3 18,15 V9 C18,5.7 15.3,3 12,3 Z M12,3 V10",
            ["info"] = "M12,3 C7,3 3,7 3,12 C3,17 7,21 12,21 C17,21 21,17 21,12 C21,7 17,3 12,3 Z M12,11 V17 M12,7 V8",
            ["folder"] = "M3,6 H10 L12,8 H21 V20 H3 Z",
            ["explorerrefresh"] = "M3,7 H10 L12,9 H21 V20 H3 Z M14,12 C17.5,10.5 20.5,13 20.5,16 M20.5,13 V16 H17.5 M18.5,19 C15,21 11.5,18.5 12,15 M12,18 V15 H15",
            ["trash"] = "M5,7 H19 M9,7 V4 H15 V7 M7,7 L8,21 H16 L17,7 M10,11 V17 M14,11 V17",
            ["disk"] = "M4,3 H17 L20,6 V21 H4 Z M8,3 V9 H16 V3 M8,16 H16 V21 H8 Z",
            ["repair"] = "M5,19 L11,13 M13,11 L19,5 M4,20 L7,21 L20,8 L16,4 L3,17 Z",
            ["endtask"] = "M6,6 L18,18 M18,6 L6,18",
            ["timer"] = "M12,5 C7.6,5 4,8.6 4,13 C4,17.4 7.6,21 12,21 C16.4,21 20,17.4 20,13 C20,8.6 16.4,5 12,5 Z M9,2 H15 M12,5 V13 L17,16",
            ["download"] = "M12,3 V15 M7,10 L12,15 L17,10 M4,20 H20",
            ["update"] = "M20,7 V12 H15 M4,17 V12 H9 M19,12 C19,8.1 15.9,5 12,5 C9.5,5 7.3,6.2 6,8 M5,12 C5,15.9 8.1,19 12,19 C14.5,19 16.7,17.8 18,16"
        };

    private static FrameworkElement CreateIconElement(string iconKey, double size, double fallbackFontSize)
    {
        var resolvedKey = iconKey == "WIN" ? "nav_windows" : iconKey;
        if (!IconPaths.TryGetValue(resolvedKey, out var pathData))
        {
            resolvedKey = "info";
            pathData = IconPaths[resolvedKey];
        }

        var geometry = Geometry.Parse(pathData);
        geometry.Freeze();

        var path = new System.Windows.Shapes.Path
        {
            Data = geometry,
            Stroke = Brushes.White,
            StrokeThickness = 1.6,
            StrokeStartLineCap = PenLineCap.Round,
            StrokeEndLineCap = PenLineCap.Round,
            StrokeLineJoin = PenLineJoin.Round,
            Fill = Brushes.Transparent,
            Stretch = Stretch.Uniform,
            Width = 24,
            Height = 24,
            SnapsToDevicePixels = true
        };

        return new Viewbox
        {
            Width = size,
            Height = size,
            Stretch = Stretch.Uniform,
            Child = path,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center
        };
    }




    private static void SetSidebarButton(Button button, string glyph, string label)
    {
        var grid = new Grid { VerticalAlignment = VerticalAlignment.Center };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(32) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var icon = CreateIconElement(glyph, 20, 17);
        icon.HorizontalAlignment = HorizontalAlignment.Center;
        icon.VerticalAlignment = VerticalAlignment.Center;
        Grid.SetColumn(icon, 0);
        grid.Children.Add(icon);

        var labelText = new TextBlock
        {
            Text = label,
            Foreground = new SolidColorBrush(Color.FromRgb(210, 220, 231)),
            FontWeight = FontWeights.SemiBold,
            FontSize = 14,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(6, 0, 0, 0),
            TextTrimming = TextTrimming.None,
            TextWrapping = TextWrapping.NoWrap
        };

        Grid.SetColumn(labelText, 1);
        grid.Children.Add(labelText);
        button.Content = grid;
    }

    private void HighlightSidebar(Button active)
    {
        foreach (var btn in _sidebarButtons)
        {
            btn.Background = Brushes.Transparent;
            btn.BorderBrush = Brushes.Transparent;
        }

        active.Background = new SolidColorBrush(Color.FromRgb(21, 42, 66));
        active.BorderBrush = new SolidColorBrush(Color.FromRgb(35, 139, 255));
    }

    private void UpdateAdminStatus()
    {
        bool admin = new WindowsPrincipal(WindowsIdentity.GetCurrent())
            .IsInRole(WindowsBuiltInRole.Administrator);

        StatusText.Text = admin
            ? "Ready"
            : "Run as Administrator";
    }



    private void SetPage(string iconGlyph, string title, string subtitle, Button activeButton)
    {
        PageIconHost.Content = CreateIconElement(iconGlyph, 36, 28);

        PageTitle.Text = FormatDisplayTitle(title);
        PageSubtitle.Text = subtitle;
        CardsHost.Children.Clear();
        HighlightSidebar(activeButton);
        UpdateAdminStatus();
    }

    private static string FormatDisplayTitle(string title)
    {
        if (string.IsNullOrWhiteSpace(title))
        {
            return title;
        }

        var formatted = CultureInfo.GetCultureInfo("en-GB")
            .TextInfo
            .ToTitleCase(title.ToLowerInvariant());

        var replacements = new (string From, string To)[]
        {
            ("Slxde", "SLXDE"),
            ("Nvidia", "NVIDIA"),
            ("Amd", "AMD"),
            ("Gpu", "GPU"),
            ("Cpu", "CPU"),
            ("Kbm", "KBM"),
            ("Msi", "MSI"),
            ("Hags", "HAGS"),
            ("Dvr", "DVR"),
            ("Cod", "COD"),
            ("Bo7", "BO7"),
            ("Fps", "FPS"),
            ("Dns", "DNS"),
            ("Usb", "USB"),
            ("Sfc", "SFC"),
            ("Dism", "DISM"),
            ("Smbv1", "SMBv1"),
            ("Xps", "XPS"),
            ("Wsl", "WSL"),
            ("Vms", "VMs"),
            ("Nas", "NAS"),
            ("Ipv4", "IPv4"),
            ("Ipv6", "IPv6"),
            (" Ip ", " IP "),
            (" Pc", " PC"),
            ("Ram", "RAM"),
            ("Onedrive", "OneDrive"),
            ("Right-Click", "right-click"),
            ("Right-click", "right-click"),
            ("Clean-Up", "Clean-up"),
            (" Of ", " of "),
            (" And ", " and "),
            (" For ", " for "),
            (" To ", " to ")
        };

        foreach (var replacement in replacements)
        {
            formatted = formatted.Replace(
                replacement.From,
                replacement.To,
                StringComparison.Ordinal);
        }

        return formatted;
    }



    private Border CreateCard(string iconGlyph, string title, string description, string warning, string buttonText, Action action)
    {
        var border = new Border { Style = (Style)FindResource("CardBorder") };

        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(54) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(145) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(150) });

        var iconBox = new Border
        {
            Width = 38,
            Height = 38,
            CornerRadius = new CornerRadius(8),
            Background = new SolidColorBrush(Color.FromRgb(21, 42, 66)),
            BorderBrush = new SolidColorBrush(Color.FromRgb(35, 139, 255)),
            BorderThickness = new Thickness(1),
            VerticalAlignment = VerticalAlignment.Center
        };

        if (iconGlyph == "AMD" || iconGlyph == "NVIDIA")
        {
            Brush cardIconBrush = iconGlyph == "AMD"
                ? new SolidColorBrush(Color.FromRgb(88, 205, 255))
                : new SolidColorBrush(Color.FromRgb(88, 205, 255));

            iconBox.Child = new TextBlock
            {
                Text = iconGlyph,
                FontFamily = new FontFamily("Arial Black, Segoe UI Black, Segoe UI"),
                Foreground = cardIconBrush,
                FontSize = iconGlyph == "AMD" ? 12 : 8,
                FontWeight = FontWeights.Black,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center
            };
        }
        else
        {
            var iconElement = CreateIconElement(iconGlyph, 20, 16);
            iconElement.HorizontalAlignment = HorizontalAlignment.Center;
            iconElement.VerticalAlignment = VerticalAlignment.Center;
            iconBox.Child = iconElement;
        }

        Grid.SetColumn(iconBox, 0);
        grid.Children.Add(iconBox);

        var textStack = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        textStack.Children.Add(new TextBlock
        {
            Text = FormatDisplayTitle(title),
            Foreground = new SolidColorBrush(Color.FromRgb(212, 225, 239)),
            FontFamily = new FontFamily("Segoe UI Variable Text, Segoe UI"),
            FontSize = 14,
            FontWeight = FontWeights.SemiBold
        });
        textStack.Children.Add(new TextBlock
        {
            Text = description,
            Foreground = (Brush)FindResource("MutedBrush"),
            FontSize = 12,
            Margin = new Thickness(0, 3, 12, 0),
            TextWrapping = TextWrapping.Wrap
        });

        Grid.SetColumn(textStack, 1);
        grid.Children.Add(textStack);

        var warningText = new TextBlock
        {
            Text = warning,
            Foreground = (Brush)FindResource("WarningBrush"),
            FontSize = 11,
            FontWeight = FontWeights.SemiBold,
            TextWrapping = TextWrapping.Wrap,
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Right,
            TextAlignment = TextAlignment.Right,
            Margin = new Thickness(0, 0, 18, 0),
            Visibility = string.IsNullOrWhiteSpace(warning) ? Visibility.Hidden : Visibility.Visible
        };

        Grid.SetColumn(warningText, 2);
        grid.Children.Add(warningText);

        var button = new Button
        {
            Style = (Style)FindResource("ApplyButton"),
            Content = buttonText,
            VerticalAlignment = VerticalAlignment.Center
        };
        button.Click += (_, _) => action();

        Grid.SetColumn(button, 3);
        grid.Children.Add(button);

        border.Child = grid;
        return border;
    }

    private async void RunPowerShell(string module, string function)
    {
        StatusText.Text = $"Running {function}...";
        string result = await _runner.RunFunctionAsync(module, function);
        StatusText.Text = result;
        SlxdeDialog.Show(this, result, "SLXDE OPTI", MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private async void AnalysePc()
    {
        UpdateStatus("Analysing PC...");
        var result = await _runner.RunFunctionAsync("ALL", "Get-GuiGamingAnalysis");

        if (result.StartsWith("Failed", StringComparison.OrdinalIgnoreCase))
        {
            UpdateStatus(result);
            SlxdeDialog.Show(this, result, "SLXDE OPTI", MessageBoxButton.OK, MessageBoxImage.Error);
            return;
        }

        UpdateStatus("PC analysis complete");
        var systemInfo = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["Windows"] = GetWindowsSummary(),
            ["CPU"] = GetCpuNameForGameMode(),
            ["GPU"] = GetGpuName(),
            ["RAM"] = GetInstalledRam()
        };

        var analysisWindow = new AnalysisWindow(result, systemInfo) { Owner = this };
        analysisWindow.ShowDialog();
    }

    private async void CheckForUpdates()
    {
        if (_updateInProgress)
        {
            return;
        }

        _updateInProgress = true;
        UpdateStatus("Checking for updates...");

        try
        {
            var update = await UpdateService.CheckForUpdateAsync();
            if (update is null)
            {
                UpdateStatus("SLXDE OPTI is up to date");
                SlxdeDialog.Show(this, "You already have the latest version of SLXDE OPTI.", "Check for Updates");
                return;
            }

            var releaseNotes = FormatReleaseNotes(update.ReleaseNotes);
            var message = $"SLXDE OPTI {update.DisplayVersion} is available.";
            if (!string.IsNullOrWhiteSpace(releaseNotes))
            {
                message += $"\n\nWhat's new:\n{releaseNotes}";
            }

            message += "\n\nDownload and install it now? The app will reopen automatically.";
            var confirmation = SlxdeDialog.Show(
                this,
                message,
                "Update Available",
                MessageBoxButton.YesNo,
                MessageBoxImage.Question);

            if (confirmation != MessageBoxResult.Yes)
            {
                UpdateStatus($"Update {update.DisplayVersion} available");
                return;
            }

            UpdateStatus($"Downloading SLXDE OPTI {update.DisplayVersion}...");
            var progress = new Progress<int>(percentage =>
            {
                UpdateStatus($"Downloading SLXDE OPTI {update.DisplayVersion}: {percentage}%");
            });
            var installerPath = await UpdateService.DownloadInstallerAsync(update, progress);

            UpdateStatus("Installing update...");
            UpdateService.LaunchInstallerAndRestart(installerPath);
            Application.Current.Shutdown();
        }
        catch (Exception ex)
        {
            UpdateStatus("Update check failed");
            SlxdeDialog.Show(
                this,
                $"SLXDE OPTI could not check for updates.\n\n{ex.Message}",
                "Update Failed",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
        finally
        {
            _updateInProgress = false;
        }
    }

    private static string FormatReleaseNotes(string releaseNotes)
    {
        if (string.IsNullOrWhiteSpace(releaseNotes))
        {
            return string.Empty;
        }

        var lines = releaseNotes
            .Split(new[] { "\r\n", "\n" }, StringSplitOptions.RemoveEmptyEntries)
            .Select(line => line.Trim().TrimStart('#').Trim())
            .Where(line => !string.IsNullOrWhiteSpace(line))
            .Take(6);
        var text = string.Join(Environment.NewLine, lines);
        return text.Length <= 520 ? text : text[..517] + "...";
    }

    private void LaunchSystemRepair(string title, string command, string details)
    {
        var confirmation = SlxdeDialog.Show(
            this,
            $"{details}\n\nA visible administrator Command Prompt will open and remain open when the repair finishes. Continue?",
            title,
            MessageBoxButton.YesNo,
            MessageBoxImage.Question);

        if (confirmation != MessageBoxResult.Yes)
        {
            UpdateAdminStatus();
            return;
        }

        try
        {
            var scriptPath = Path.Combine(Path.GetTempPath(), $"SlxdeRepair_{Guid.NewGuid():N}.cmd");
            var script = string.Join(Environment.NewLine, new[]
            {
                "@echo off",
                $"title {title}",
                "echo ============================================================",
                $"echo {title}",
                "echo ============================================================",
                "echo.",
                "echo This can take several minutes. Do not close this window.",
                "echo.",
                command,
                "echo.",
                "echo ============================================================",
                "echo Finished. If Windows repaired anything, restart your PC.",
                "echo ============================================================",
                "pause",
                "del \"%~f0\""
            });
            File.WriteAllText(scriptPath, script, System.Text.Encoding.ASCII);

            Process.Start(new ProcessStartInfo
            {
                FileName = "cmd.exe",
                Arguments = $"/c \"\"{scriptPath}\"\"",
                UseShellExecute = true,
                Verb = "runas",
                WindowStyle = ProcessWindowStyle.Normal
            });

            UpdateStatus($"Opened {title}");
        }
        catch (Exception ex)
        {
            UpdateStatus($"Failed to open {title}");
            SlxdeDialog.Show(
                this,
                ex.Message,
                title,
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void LaunchSystemFileCheck() => LaunchSystemRepair(
        "SLXDE OPTI - System File Check",
        "sfc /scannow",
        "System File Checker scans and repairs protected Windows files. It commonly takes 5–20 minutes and may pause before showing progress.");

    private void LaunchWindowsImageRepair() => LaunchSystemRepair(
        "SLXDE OPTI - Windows Image Repair",
        "DISM /Online /Cleanup-Image /RestoreHealth",
        "DISM checks and repairs the Windows component store. It can take over 30 minutes and may appear stuck at certain percentages.");

    private void ApplyNvidiaControlPanelProfile()
    {
        var confirmation = SlxdeDialog.Show(this,
            "Apply SLXDE's NVIDIA competitive profile?\n\n" +
            "This changes the NVIDIA global driver profile. Your current customised profiles will be backed up first. " +
            "Low Latency Mode and G-SYNC are left game-controlled.",
            "NVIDIA Control Panel Optimisation",
            MessageBoxButton.YesNo,
            MessageBoxImage.Question);

        if (confirmation == MessageBoxResult.Yes)
        {
            RunPowerShell("ALL", "Apply-GuiNvidiaControlPanelOptimisation");
        }
    }

    private async void ChooseGameHighPerformanceGpu()
    {
        UpdateStatus("Scanning genuine game executables...");
        IReadOnlyList<GameExecutableCandidate> detectedGames;
        try
        {
            detectedGames = await GameExecutableFinder.FindAsync();
            UpdateStatus(detectedGames.Count == 0
                ? "Scan complete · no games detected"
                : $"Scan complete · {detectedGames.Count} game{(detectedGames.Count == 1 ? string.Empty : "s")} found");
        }
        catch (Exception ex)
        {
            UpdateStatus("Automatic game detection failed");
            SlxdeDialog.Show(this,
                $"Automatic game detection failed, but you can still browse manually.\n\n{ex.Message}",
                "Game GPU Preference",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
            detectedGames = Array.Empty<GameExecutableCandidate>();
        }

        var gamePicker = new GamePickerWindow { Owner = this };
        gamePicker.SetGames(detectedGames);
        if (gamePicker.ShowDialog() != true || string.IsNullOrWhiteSpace(gamePicker.SelectedExecutablePath))
        {
            UpdateAdminStatus();
            return;
        }

        var executablePath = gamePicker.SelectedExecutablePath;

        try
        {
            using var key = Microsoft.Win32.Registry.CurrentUser.CreateSubKey(
                @"Software\Microsoft\DirectX\UserGpuPreferences",
                writable: true);

            if (key == null)
            {
                throw new InvalidOperationException("Windows would not open the graphics-preference settings.");
            }

            var selectedCandidate = detectedGames.FirstOrDefault(candidate =>
                string.Equals(candidate.ExecutablePath, executablePath, StringComparison.OrdinalIgnoreCase));
            var gameName = selectedCandidate?.DisplayName ?? Path.GetFileNameWithoutExtension(executablePath);

            if (gamePicker.RestoreDefaultRequested)
            {
                key.DeleteValue(executablePath, throwOnMissingValue: false);
                UpdateStatus($"Windows GPU default restored for {gameName}");
                SlxdeDialog.Show(this,
                    $"{gameName} now uses the Windows default GPU preference.",
                    "Game GPU Preference",
                    MessageBoxButton.OK,
                    MessageBoxImage.Information);
                return;
            }

            key.SetValue(executablePath, "GpuPreference=2;", Microsoft.Win32.RegistryValueKind.String);
            UpdateStatus($"High-performance GPU selected for {gameName}");
            SlxdeDialog.Show(this,
                $"{gameName} is now assigned to the High performance GPU.\n\nRestart the game if it is currently open.",
                "Game GPU Preference",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
        }
        catch (Exception ex)
        {
            UpdateStatus("Game GPU preference failed");
            SlxdeDialog.Show(this,
                $"Windows could not save the game GPU preference.\n\n{ex.Message}",
                "Game GPU Preference",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void ApplyMaximumRefreshRate()
    {
        try
        {
            var result = DisplayRefreshRateService.ApplyMaximumForPrimaryDisplay();
            if (!result.Success)
            {
                UpdateStatus("Maximum refresh rate was not applied");
                SlxdeDialog.Show(this,
                    result.Error,
                    "Maximum Refresh Rate",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
                return;
            }

            if (!result.Changed)
            {
                var currentLabel = result.CurrentHz > 0 ? $"{result.CurrentHz} Hz" : "the display's default rate";
                UpdateStatus($"Refresh rate already at maximum: {currentLabel}");
                SlxdeDialog.Show(this,
                    $"Your primary display is already using its highest supported refresh rate for {result.Width} × {result.Height}: {currentLabel}.",
                    "Maximum Refresh Rate",
                    MessageBoxButton.OK,
                    MessageBoxImage.Information);
                return;
            }

            UpdateStatus($"Refresh rate set to {result.CurrentHz} Hz");
            SlxdeDialog.Show(this,
                $"Primary display refresh rate changed from {result.PreviousHz} Hz to {result.CurrentHz} Hz.\n\nResolution remains {result.Width} × {result.Height}.",
                "Maximum Refresh Rate",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
        }
        catch (Exception ex)
        {
            UpdateStatus("Maximum refresh rate failed");
            SlxdeDialog.Show(this,
                $"Windows could not apply the maximum refresh rate.\n\n{ex.Message}",
                "Maximum Refresh Rate",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private async void ApplyCodConfigWithProgress()
    {
        var confirmation = SlxdeDialog.Show(this,
            "Apply SLXDE's COD config?\n\nClose Call of Duty before continuing. Your current config will be backed up automatically.",
            "SLXDE COD Config",
            MessageBoxButton.YesNo,
            MessageBoxImage.Question);

        if (confirmation != MessageBoxResult.Yes)
        {
            return;
        }

        var progressWindow = CreateCodConfigProgressWindow(out var progressText);
        StatusText.Text = "Applying COD config...";
        progressWindow.Show();

        try
        {
            progressText.Text = "Detecting your CPU, GPU and COD files...";
            await Task.Delay(250);

            progressText.Text = "Creating backups and applying the best matching profile...";
            string result = await _runner.RunFunctionAsync("ALL", "Apply-GuiCodBo7Config");

            bool success = result.StartsWith(
                "SLXDE COD config applied",
                StringComparison.OrdinalIgnoreCase);

            progressText.Text = success
                ? "SLXDE's COD config was applied successfully."
                : "The config needs your attention.";

            await Task.Delay(350);
            progressWindow.Close();

            StatusText.Text = success
                ? "COD config applied"
                : "COD config needs attention";

            SlxdeDialog.Show(this,
                result,
                "SLXDE COD Config",
                MessageBoxButton.OK,
                success ? MessageBoxImage.Information : MessageBoxImage.Warning);
        }
        catch (Exception ex)
        {
            progressWindow.Close();
            StatusText.Text = "COD config failed";
            SlxdeDialog.Show(this,
                $"The COD config could not be applied.\n\n{ex.Message}",
                "SLXDE COD Config",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private Window CreateCodConfigProgressWindow(out TextBlock progressText)
    {
        var window = new Window
        {
            Owner = this,
            Title = "SLXDE COD Config",
            Width = 500,
            Height = 235,
            WindowStartupLocation = WindowStartupLocation.CenterOwner,
            WindowStyle = WindowStyle.None,
            ResizeMode = ResizeMode.NoResize,
            ShowInTaskbar = false,
            Background = Brushes.Transparent,
            AllowsTransparency = true
        };

        var shell = new Border
        {
            Background = new SolidColorBrush(Color.FromRgb(13, 20, 31)),
            BorderBrush = new SolidColorBrush(Color.FromRgb(35, 139, 255)),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(14),
            Padding = new Thickness(28)
        };

        var stack = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        stack.Children.Add(new TextBlock
        {
            Text = "Applying SLXDE's COD config",
            Foreground = new SolidColorBrush(Color.FromRgb(220, 233, 247)),
            FontFamily = new FontFamily("Segoe UI Variable Display, Segoe UI"),
            FontSize = 22,
            FontWeight = FontWeights.SemiBold
        });
        stack.Children.Add(new TextBlock
        {
            Text = "Keep Call of Duty closed while your existing settings are backed up and the performance preset is applied.",
            Foreground = (Brush)FindResource("MutedBrush"),
            FontFamily = new FontFamily("Segoe UI Variable Text, Segoe UI"),
            FontSize = 12,
            TextWrapping = TextWrapping.Wrap,
            Margin = new Thickness(0, 8, 0, 18)
        });

        progressText = new TextBlock
        {
            Text = "Preparing...",
            Foreground = (Brush)FindResource("WarningBrush"),
            FontFamily = new FontFamily("Segoe UI Variable Text, Segoe UI"),
            FontSize = 13,
            FontWeight = FontWeights.SemiBold,
            Margin = new Thickness(0, 0, 0, 10)
        };
        stack.Children.Add(progressText);
        stack.Children.Add(new ProgressBar
        {
            Height = 5,
            IsIndeterminate = true,
            Foreground = (Brush)FindResource("GlowBrush"),
            Background = new SolidColorBrush(Color.FromRgb(24, 37, 53)),
            BorderThickness = new Thickness(0)
        });

        shell.Child = stack;
        window.Content = shell;
        return window;
    }

    private void AddSectionHeader(string title, string subtitle, string accent)
    {
        var border = new Border
        {
            BorderThickness = new Thickness(0, 1, 0, 1),
            BorderBrush = new SolidColorBrush(Color.FromRgb(38, 54, 73)),
            Background = Brushes.Transparent,
            Padding = new Thickness(14, 12, 14, 10),
            Margin = new Thickness(0, 8, 0, 8)
        };

        var stack = new StackPanel
        {
            HorizontalAlignment = HorizontalAlignment.Center
        };

        stack.Children.Add(new TextBlock
        {
            Text = FormatDisplayTitle(title),
            Foreground = new SolidColorBrush(Color.FromRgb(220, 233, 247)),
            FontSize = 18,
            FontWeight = FontWeights.SemiBold,
            FontFamily = new FontFamily("Segoe UI Variable Display, Segoe UI"),
            HorizontalAlignment = HorizontalAlignment.Center
        });

        stack.Children.Add(new TextBlock
        {
            Text = subtitle,
            Foreground = (Brush)FindResource("SubtleBrush"),
            FontSize = 12,
            Margin = new Thickness(0, 3, 0, 0),
            HorizontalAlignment = HorizontalAlignment.Center
        });

        border.Child = stack;
        CardsHost.Children.Add(border);
    }

    private void AddCard(string icon, string title, string description, string warning, string module, string function)
    {
        var buttonText = function.StartsWith("Open-", StringComparison.OrdinalIgnoreCase) ||
                         function.StartsWith("Start-", StringComparison.OrdinalIgnoreCase)
            ? "OPEN  >"
            : function.StartsWith("Get-", StringComparison.OrdinalIgnoreCase)
                ? "VIEW  >"
                : function.StartsWith("Restore-", StringComparison.OrdinalIgnoreCase)
                    ? "RESTORE  >"
                    : function.StartsWith("New-", StringComparison.OrdinalIgnoreCase)
                        ? "CREATE  >"
                        : "APPLY  >";

        CardsHost.Children.Add(CreateCard(icon, title, description, warning, buttonText, () => RunPowerShell(module, function)));
    }

    private void AddGuideCard(string icon, string title, string description, string warning, Action action)
    {
        CardsHost.Children.Add(CreateCard(icon, title, description, warning, "OPEN  >", action));
    }

    private void AddPreviewCard(string icon, string title, string description, string warning = "")
    {
        CardsHost.Children.Add(CreateCard(icon, title, description, warning, "PREVIEW",
            () => SlxdeDialog.Show(this, "This button is laid out for the GUI preview. Function wiring comes next.", "SLXDE OPTI")));
    }


    private string GetCpuNameForGameMode()
    {
        if (!string.IsNullOrWhiteSpace(_cachedCpuName))
        {
            return _cachedCpuName;
        }

        try
        {
            var value = Microsoft.Win32.Registry.GetValue(
                @"HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\CentralProcessor\0",
                "ProcessorNameString",
                null)?.ToString();

            if (!string.IsNullOrWhiteSpace(value))
            {
                _cachedCpuName = value.Trim();
                return _cachedCpuName;
            }
        }
        catch
        {
        }

        return _cachedCpuName = "Unknown CPU";
    }

    private string GetCpuPerformanceModeRecommendation()
    {
        var cpuName = GetCpuNameForGameMode();

        if (cpuName.Contains("AMD", StringComparison.OrdinalIgnoreCase) ||
            cpuName.Contains("Ryzen", StringComparison.OrdinalIgnoreCase))
        {
            return "AMD Balanced";
        }

        if (cpuName.Contains("Intel", StringComparison.OrdinalIgnoreCase) ||
            cpuName.Contains("Core", StringComparison.OrdinalIgnoreCase))
        {
            return "Intel Optimal";
        }

        return "Auto";
    }

    private async void ToggleSlxdePerformanceMode()
    {
        _slxdePerformanceModeEnabled = !_slxdePerformanceModeEnabled;
        _slxdePerformanceModeCpuMode = GetCpuPerformanceModeRecommendation();

        if (_slxdePerformanceModeEnabled)
        {
            UpdateStatus($"Performance Mode ON - {_slxdePerformanceModeCpuMode}");
            await RunPowerShellInlineAsync(BuildPerformanceModeScript(enable: true, _slxdePerformanceModeCpuMode));
        }
        else
        {
            UpdateStatus("Performance Mode OFF");
            await RunPowerShellInlineAsync(BuildPerformanceModeScript(enable: false, _slxdePerformanceModeCpuMode));
        }

        LoadDashboard();
        UpdateStatus(_slxdePerformanceModeEnabled
            ? $"Performance Mode ON - {_slxdePerformanceModeCpuMode}"
            : "Performance Mode OFF");
    }


    private static string BuildPerformanceModeScript(bool enable, string cpuMode)
    {
        if (enable)
        {
            var powerPlanCommand = cpuMode.StartsWith("AMD", StringComparison.OrdinalIgnoreCase)
                ? "powercfg /setactive SCHEME_BALANCED"
                : "powercfg /setactive SCHEME_MIN";

            return $@"
$ErrorActionPreference = 'SilentlyContinue'

{powerPlanCommand}

reg add 'HKCU\Software\Microsoft\GameBar' /v AutoGameModeEnabled /t REG_DWORD /d 1 /f | Out-Null
reg add 'HKCU\System\GameConfigStore' /v GameDVR_Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add 'HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR' /v AppCaptureEnabled /t REG_DWORD /d 0 /f | Out-Null
reg add 'HKCU\Software\Microsoft\GameBar' /v UseNexusForGameBarEnabled /t REG_DWORD /d 0 /f | Out-Null

Write-Output 'SLXDE'S Performance Mode enabled ({cpuMode})'
";
        }

        return @"
$ErrorActionPreference = 'SilentlyContinue'

Write-Output 'SLXDE'S Performance Mode disabled'
";
    }

    private Task<string> RunPowerShellInlineAsync(string script)
    {
        return Task.Run(() =>
        {
            string? tempScript = null;

            try
            {
                tempScript = System.IO.Path.Combine(System.IO.Path.GetTempPath(), $"SlxdePerformanceMode_{Guid.NewGuid():N}.ps1");
                System.IO.File.WriteAllText(tempScript, script);

                var info = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{tempScript}\"",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };

                using var process = System.Diagnostics.Process.Start(info);
                if (process == null)
                {
                    return "Failed to start PowerShell.";
                }

                process.WaitForExit(30000);
                var output = process.StandardOutput.ReadToEnd();
                var error = process.StandardError.ReadToEnd();

                if (!string.IsNullOrWhiteSpace(error))
                {
                    Dispatcher.Invoke(() => UpdateStatus(error.Trim()));
                    return error.Trim();
                }

                var result = string.IsNullOrWhiteSpace(output) ? "Done" : output.Trim();
                Dispatcher.Invoke(() => UpdateStatus(result));
                return result;
            }
            catch (Exception ex)
            {
                Dispatcher.Invoke(() => UpdateStatus(ex.Message));
                return ex.Message;
            }
            finally
            {
                try
                {
                    if (!string.IsNullOrWhiteSpace(tempScript) && System.IO.File.Exists(tempScript))
                    {
                        System.IO.File.Delete(tempScript);
                    }
                }
                catch
                {
                }
            }
        });
    }

    private void AddActionCard(string icon, string title, string description, string warning, string buttonText, Action action)
    {
        CardsHost.Children.Add(CreateCard(icon, title, description, warning, buttonText, action));
    }

    private void ShowLatestLogStatusOnly()
    {
        try
        {
            var logDir = System.IO.Path.Combine(AppContext.BaseDirectory, "Logs");

            if (!System.IO.Directory.Exists(logDir))
            {
                UpdateStatus("No log folder found yet.");
                return;
            }

            var latest = System.IO.Directory.GetFiles(logDir, "*.log")
                .Concat(System.IO.Directory.GetFiles(logDir, "*.txt"))
                .OrderByDescending(System.IO.File.GetLastWriteTime)
                .FirstOrDefault();

            if (string.IsNullOrWhiteSpace(latest))
            {
                UpdateStatus("No log file found yet.");
                return;
            }

            System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
            {
                FileName = latest,
                UseShellExecute = true
            });

            UpdateStatus("Opened latest log");
        }
        catch (Exception ex)
        {
            UpdateStatus(ex.Message);
        }
    }


    private string GetGpuName()
    {
        if (!string.IsNullOrWhiteSpace(_cachedGpuName))
        {
            return _cachedGpuName;
        }

        try
        {
            using var searcher = new ManagementObjectSearcher(
                "SELECT Name, AdapterRAM FROM Win32_VideoController");

            _cachedGpuName = searcher.Get()
                .Cast<ManagementObject>()
                .OrderByDescending(item => Convert.ToUInt64(item["AdapterRAM"] ?? 0UL))
                .Select(item => item["Name"]?.ToString()?.Trim())
                .FirstOrDefault(name => !string.IsNullOrWhiteSpace(name))
                ?? "Unknown GPU";
            return _cachedGpuName;
        }
        catch
        {
            return _cachedGpuName = "Unknown GPU";
        }
    }

    private string GetInstalledRam()
    {
        if (!string.IsNullOrWhiteSpace(_cachedInstalledRam))
        {
            return _cachedInstalledRam;
        }

        try
        {
            using var searcher = new ManagementObjectSearcher(
                "SELECT TotalPhysicalMemory FROM Win32_ComputerSystem");
            var bytes = searcher.Get()
                .Cast<ManagementObject>()
                .Select(item => Convert.ToUInt64(item["TotalPhysicalMemory"] ?? 0UL))
                .FirstOrDefault();

            if (bytes > 0)
            {
                _cachedInstalledRam = $"{Math.Round(bytes / 1024d / 1024d / 1024d):0} GB";
                return _cachedInstalledRam;
            }
        }
        catch
        {
        }

        return _cachedInstalledRam = "Unknown RAM";
    }

    private string GetWindowsSummary()
    {
        if (!string.IsNullOrWhiteSpace(_cachedWindowsSummary))
        {
            return _cachedWindowsSummary;
        }

        try
        {
            var product = Microsoft.Win32.Registry.GetValue(
                @"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion",
                "ProductName",
                "Windows")?.ToString() ?? "Windows";
            var displayVersion = Microsoft.Win32.Registry.GetValue(
                @"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion",
                "DisplayVersion",
                string.Empty)?.ToString();

            product = product.Replace("Windows 10", "Windows 11", StringComparison.OrdinalIgnoreCase);
            _cachedWindowsSummary = string.IsNullOrWhiteSpace(displayVersion)
                ? product
                : $"{product} {displayVersion}";
            return _cachedWindowsSummary;
        }
        catch
        {
            return _cachedWindowsSummary = "Windows";
        }
    }

    private void AddSystemSummary()
    {
        var container = new Border
        {
            Background = new SolidColorBrush(Color.FromRgb(13, 19, 29)),
            BorderBrush = new SolidColorBrush(Color.FromRgb(30, 43, 59)),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(10),
            Margin = new Thickness(0, 0, 0, 10)
        };

        var grid = new System.Windows.Controls.Primitives.UniformGrid
        {
            Columns = 4,
            Rows = 1
        };

        AddSummaryTile(grid, "CPU", GetCpuNameForGameMode(), "nav_gpu");
        AddSummaryTile(grid, "GPU", GetGpuName(), "monitor");
        AddSummaryTile(grid, "MEMORY", GetInstalledRam(), "memory");
        AddSummaryTile(grid, "WINDOWS", GetWindowsSummary(), "WIN");

        container.Child = grid;
        CardsHost.Children.Add(container);
    }

    private void AddSummaryTile(Panel parent, string label, string value, string icon)
    {
        var tile = new Border
        {
            Background = new SolidColorBrush(Color.FromRgb(17, 24, 36)),
            BorderBrush = new SolidColorBrush(Color.FromRgb(30, 43, 59)),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(8),
            Margin = new Thickness(4),
            Padding = new Thickness(12, 10, 12, 10),
            MinHeight = 74
        };

        var layout = new Grid();
        layout.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(34) });
        layout.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var iconElement = CreateIconElement(icon, 20, 16);
        iconElement.HorizontalAlignment = HorizontalAlignment.Left;
        iconElement.VerticalAlignment = VerticalAlignment.Center;
        layout.Children.Add(iconElement);

        var text = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        Grid.SetColumn(text, 1);
        text.Children.Add(new TextBlock
        {
            Text = label,
            Foreground = (Brush)FindResource("SubtleBrush"),
            FontSize = 9,
            FontWeight = FontWeights.Bold
        });
        var valueText = new TextBlock
        {
            Text = value,
            Foreground = Brushes.White,
            FontSize = 11,
            FontWeight = FontWeights.SemiBold,
            TextWrapping = TextWrapping.Wrap,
            TextTrimming = TextTrimming.CharacterEllipsis,
            MaxHeight = 32,
            Margin = new Thickness(0, 3, 0, 0),
            ToolTip = value
        };
        text.Children.Add(valueText);
        layout.Children.Add(text);

        tile.Child = layout;
        parent.Children.Add(tile);
    }



    private void AddInfoCard(string title, string body, string tips)
    {
        var border = new Border
        {
            Style = (Style)FindResource("CardBorder"),
            Padding = new Thickness(28)
        };

        var stack = new StackPanel();

        stack.Children.Add(new TextBlock
        {
            Text = FormatDisplayTitle(title),
            Foreground = new SolidColorBrush(Color.FromRgb(220, 233, 247)),
            FontSize = 18,
            FontWeight = FontWeights.SemiBold,
            Margin = new Thickness(0, 0, 0, 14)
        });

        stack.Children.Add(new TextBlock
        {
            Text = body,
            Foreground = (Brush)FindResource("MutedBrush"),
            FontSize = 13,
            FontWeight = FontWeights.Normal,
            TextWrapping = TextWrapping.Wrap,
            Margin = new Thickness(0, 0, 0, 14)
        });

        stack.Children.Add(new TextBlock
        {
            Text = "Tips",
            Foreground = (Brush)FindResource("WarningBrush"),
            FontSize = 13,
            FontWeight = FontWeights.SemiBold,
            Margin = new Thickness(0, 0, 0, 6)
        });

        stack.Children.Add(new TextBlock
        {
            Text = tips,
            Foreground = (Brush)FindResource("MutedBrush"),
            FontSize = 12,
            FontWeight = FontWeights.Normal,
            TextWrapping = TextWrapping.Wrap
        });

        border.Child = stack;
        CardsHost.Children.Add(border);
    }



    private void LoadDashboard()
    {
        SetPage("nav_dashboard", "DASHBOARD", "Your system overview and essential tools.", BtnDashboard);

        var cpuName = GetCpuNameForGameMode();
        var recommendedMode = GetCpuPerformanceModeRecommendation();
        var performanceModeDescription = $"{recommendedMode} mode for {cpuName}. Active games: {_slxdeActiveGames}.";

        AddSystemSummary();

        AddActionCard("bolt", "SLXDE'S PERFORMANCE MODE", performanceModeDescription, _slxdePerformanceModeEnabled ? "Active" : "Recommended", _slxdePerformanceModeEnabled ? "TURN OFF  >" : "TURN ON  >", ToggleSlxdePerformanceMode);

        AddActionCard("activity", "ANALYSE PC", "Check your hardware and current gaming-related Windows settings.", "", "ANALYSE  >", AnalysePc);
        AddActionCard("nav_backup", "CREATE BACKUP", "Create a restore point and export important optimiser settings.", "", "CREATE  >", () => RunPowerShell("ALL", "New-SlxdeBackup"));
        AddActionCard("document", "VIEW LATEST LOG", "Open the latest SLXDE OPTI activity log.", "", "OPEN  >", ShowLatestLogStatusOnly);
        AddActionCard("update", "CHECK FOR UPDATES", "Checks for and installs new versions.", "", "CHECK  >", CheckForUpdates);
    }


    private void LoadWindows()
    {
        SetPage("nav_windows", "WINDOWS", "Windows, gaming and performance settings in one place.", BtnWindows);

        AddCard("terminal", "ENABLE SCRIPTS", "Unblocks optimiser files and allows local scripts for easier use.", "Do this first", "ALL", "Enable-GuiOptimizerScripts");
        AddCard("windowsrestore", "REVERT WINDOWS OPTI", "Reverts the main Windows, gaming and power-plan optimiser changes.", "Restart recommended", "ALL", "Restore-GuiWindowsDefaults");
        AddCard("balance", "LOAD BALANCED POWER PLAN", "Activates a safer Balanced power plan for laptops or high temps.", "Safer cooling choice", "ALL", "Set-BalancedPowerPlan");
        AddCard("bolt", "LOAD OPTIMAL POWER PLAN", "Activates the desktop/performance-focused optimal power plan.", "May increase temperature", "ALL", "Set-GuiSlxdePowerPlan");

        AddCard("nav_controller", "ENABLE GAME MODE", "Enables Windows Performance Mode.", "", "ALL", "Enable-GameMode");
        AddCard("videooff", "DISABLE GAME DVR", "Disables Game DVR and Xbox capture background recording.", "", "ALL", "Disable-GameDVR");
        AddCard("nav_gpu", "ENABLE HAGS", "Enables Hardware Accelerated GPU Scheduling where supported.", "Restart recommended", "ALL", "Enable-HAGS");
        AddCard("monitor", "ENABLE WINDOWED OPTIMISATIONS", "Enables modern windowed game optimisations.", "", "ALL", "Enable-WindowedOptimizations");
        AddCard("nav_windows", "DISABLE BACKGROUND APPS", "Reduces background app activity where supported.", "", "ALL", "Disable-BackgroundApps");
        AddCard("pin", "DISABLE LOCATION TRACKING", "Turns off Windows location access setting.", "", "ALL", "Disable-LocationTracking");
    }




    private void LoadDebloat()
    {
        SetPage("nav_debloat", "DEBLOAT", "Choose a profile or tick individual Windows debloat options.", BtnDebloat);
        _debloatChecks.Clear();
        _debloatOptionsGrid = null;

        AddInfoCard(
            "DEBLOAT - SAFE APPLY",
            "Select a preset, then tick or untick individual options before applying.",
            "• Minimal is recommended for most users.\n• Gaming adds background/network reductions.\n• Advanced can disable Windows features and services, so read warnings first.\n• Create a backup before big changes.");

        AddSectionHeader("PROFILE PRESETS", "Choose a preset, then customise the tick boxes below.", "");
        AddActionCard("nav_debloat", "MINIMAL DEBLOAT", "Safe cleanup for most gaming PCs.", "Recommended", "SELECT  >", () => SetDebloatProfile("Minimal"));
        AddActionCard("nav_debloat", "GAMING DEBLOAT", "Minimal debloat plus gaming-focused background reductions.", "", "SELECT  >", () => SetDebloatProfile("Gaming"));
        AddActionCard("nav_debloat", "ADVANCED DEBLOAT", "Extra service and Windows feature removals with warnings.", "Advanced", "SELECT  >", () => SetDebloatProfile("Advanced"));

        AddSectionHeader("APPLY / RESTORE", "Apply your selected checkboxes or restore safe defaults.", "");
        AddActionCard("check", "APPLY SELECTED DEBLOAT", "Applies every ticked debloat option below.", "Backup recommended", "APPLY  >", ApplySelectedDebloat);
        AddActionCard("restore", "RESTORE DEBLOAT DEFAULTS", "Restores the main debloat changes where safely possible.", "Recovery option", "RESTORE  >", RestoreDebloatDefaults);

        AddSectionHeader("SAFE OPTIONS", "Good default options for most Windows gaming PCs.", "");
        StartDebloatOptionGrid();
        AddDebloatOption("CopilotOff", "Disable Copilot", "Turns off Windows Copilot where supported. Reduces AI/sidebar clutter and background integration.", "", true);
        AddDebloatOption("WidgetsOff", "Disable Widgets", "Removes Widgets and News panel activity. Helps reduce taskbar clutter and small background usage.", "", true);
        AddDebloatOption("TeamsChatOff", "Disable Chat / Teams Integration", "Removes the Windows Chat/Teams taskbar integration. Useful if you do not use built-in Teams.", "", true);
        AddDebloatOption("ConsumerExperiencesOff", "Disable Consumer Experiences", "Blocks suggested consumer app installs and promo content. Keeps Windows cleaner after updates.", "", true);
        AddDebloatOption("SuggestedAppsOff", "Disable Suggested Apps", "Reduces Start menu and Settings recommendations. Less advertising-style content in Windows.", "", true);
        AddDebloatOption("TipsOff", "Disable Tips & Tricks", "Disables Windows tips, welcome suggestions and pop-up hints. Keeps the desktop quieter.", "", true);
        AddDebloatOption("AdvertisingIdOff", "Disable Advertising ID", "Turns off the Windows advertising ID for the current user. Privacy-focused and safe.", "", true);
        AddDebloatOption("ActivityHistoryOff", "Disable Activity History Sync", "Stops Windows activity history publishing and upload. Reduces cross-device tracking features.", "", true);
        AddDebloatOption("ClipboardSyncOff", "Disable Clipboard Sync", "Disables cross-device clipboard sync. Local copy and paste still works normally.", "", true);
        AddDebloatOption("SpotlightOff", "Disable Windows Spotlight", "Turns off Spotlight lock-screen promo content. Keeps the lock screen simple.", "", true);
        AddDebloatOption("EdgeStartupBoostOff", "Disable Edge Startup Boost", "Stops Edge from preloading in the background. Edge may open slightly slower.", "", true);

        AddSectionHeader("GAMING OPTIONS", "Useful background reductions for gaming.", "");
        StartDebloatOptionGrid();
        AddDebloatOption("SearchCloudOff", "Search Cloud Off", "Keeps Start/Search more local and reduces Bing/cloud results. Can reduce search-related network usage.", "", false);
        AddDebloatOption("DOSoloMode", "Delivery Optimisation Solo Mode", "Stops Windows from sharing update files with other PCs. Can reduce background bandwidth usage.", "", false);
        AddDebloatOption("StoreAutoUpdatesOff", "Store Auto Updates Off", "Stops Microsoft Store apps auto-updating in the background. You may need to update apps manually.", "Manual app updates needed", false);
        AddDebloatOption("OfficeTasksOff", "Office Background Tasks Off", "Disables common Office update/telemetry scheduled tasks. Office may need manual update checks.", "Office updates may need manual checks", false);
        AddDebloatOption("StickyKeysGuard", "StickyKeys Guard", "Prevents Sticky Keys, Filter Keys and Toggle Keys popups mid-game. Safe quality-of-life tweak.", "", false);
        AddDebloatOption("USBPowerGuard", "USB Power Guard", "Disables USB selective suspend on the active power plan. Can help mice, keyboards, controllers and headsets stay responsive.", "", false);
        AddDebloatOption("GameBarBackgroundOff", "Game Bar Background Off", "Disables capture/background Game Bar pieces while keeping Windows Game Mode separate.", "", false);
        AddDebloatOption("OneDriveStartupOff", "OneDrive Startup Off", "Stops OneDrive from auto-starting. Only use this if you do not rely on OneDrive sync.", "Only if you do not use OneDrive sync", false);

        AddSectionHeader("ADVANCED OPTIONS", "Use only if you understand the trade-offs.", "");
        StartDebloatOptionGrid();
        AddDebloatOption("HibernationOff", "Hibernation Disable", "Disables hibernation and removes hiberfil.sys. Frees disk space but disables Hibernate/Fast Startup.", "Disables Hibernate/Fast Startup", false);
        AddDebloatOption("PrintSpoolerOff", "Print Spooler Off", "Disables Windows printing services. Only use this if you never print.", "Only if you never print", false);
        AddDebloatOption("FaxOff", "Fax Service Off", "Disables the legacy Fax service. Safe for most gaming PCs.", "", false);
        AddDebloatOption("RemoteRegistryOff", "Remote Registry Off", "Disables remote registry access. Usually safe and reduces unnecessary remote management exposure.", "", false);
        AddDebloatOption("RemoteAssistanceOff", "Remote Assistance Off", "Disables Remote Assistance invites. Use only if you never need built-in remote help.", "", false);
        AddDebloatOption("SMBv1Off", "SMBv1 Off", "Disables legacy SMBv1 networking. Safer, but may affect very old NAS or network devices.", "Can affect very old network devices", false);
        AddDebloatOption("XPSOff", "XPS Services Off", "Disables XPS printing services. Only use this if you do not use XPS documents or printers.", "Only if unused", false);
        AddDebloatOption("SandboxOff", "Windows Sandbox Off", "Disables Windows Sandbox optional feature. Only use this if you do not use Sandbox.", "Only if unused", false);
        AddDebloatOption("VirtualizationFeaturesOff", "Virtualization Features Off", "Disables Hyper-V, Virtual Machine Platform and WSL. Breaks VMs, WSL and some emulators.", "Breaks VMs, WSL, emulators", false);
        AddDebloatOption("SysMainOff", "SysMain Off", "Disables Windows app preloading/cache service. May reduce background disk activity, but can make apps load slower. Optional.", "Optional; can hurt some systems", false);

        SetDebloatProfile("Minimal");
    }

    private void AddDebloatOption(string key, string title, string description, string warning, bool defaultChecked)
    {
        var border = new Border
        {
            Style = (Style)FindResource("CardBorder"),
            MinHeight = 84,
            Padding = new Thickness(14, 11, 12, 11),
            Margin = new Thickness(5)
        };

        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(42) });

        var textStack = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        textStack.Children.Add(new TextBlock
        {
            Text = FormatDisplayTitle(title),
            Foreground = new SolidColorBrush(Color.FromRgb(212, 225, 239)),
            FontFamily = new FontFamily("Segoe UI Variable Text, Segoe UI"),
            FontSize = 14,
            FontWeight = FontWeights.SemiBold
        });
        textStack.Children.Add(new TextBlock
        {
            Text = description,
            Foreground = (Brush)FindResource("MutedBrush"),
            FontSize = 11,
            Margin = new Thickness(0, 3, 8, 0),
            TextWrapping = TextWrapping.Wrap,
            MaxHeight = 30
        });

        if (!string.IsNullOrWhiteSpace(warning))
        {
            textStack.Children.Add(new TextBlock
            {
                Text = warning,
                Foreground = (Brush)FindResource("WarningBrush"),
                FontSize = 10,
                FontWeight = FontWeights.SemiBold,
                Margin = new Thickness(0, 3, 8, 0),
                TextWrapping = TextWrapping.Wrap
            });
        }

        grid.Children.Add(textStack);

        var check = new CheckBox
        {
            IsChecked = defaultChecked,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Width = 20,
            Height = 20,
            ToolTip = "Tick to include this option when applying selected debloat."
        };

        Grid.SetColumn(check, 1);
        grid.Children.Add(check);

        _debloatChecks[key] = check;
        border.Child = grid;
        Panel optionHost = _debloatOptionsGrid is not null
            ? _debloatOptionsGrid
            : CardsHost;
        optionHost.Children.Add(border);
    }

    private void StartDebloatOptionGrid()
    {
        _debloatOptionsGrid = new System.Windows.Controls.Primitives.UniformGrid
        {
            Columns = 2,
            Margin = new Thickness(-5, -5, -5, 10)
        };
        CardsHost.Children.Add(_debloatOptionsGrid);
    }

    private void SetDebloatProfile(string profile)
    {
        foreach (var box in _debloatChecks.Values)
        {
            box.IsChecked = false;
        }

        string[] minimal =
        {
            "CopilotOff", "WidgetsOff", "TeamsChatOff", "ConsumerExperiencesOff", "SuggestedAppsOff",
            "TipsOff", "AdvertisingIdOff", "ActivityHistoryOff", "ClipboardSyncOff", "SpotlightOff",
            "EdgeStartupBoostOff"
        };

        string[] gaming =
        {
            "SearchCloudOff", "DOSoloMode", "StoreAutoUpdatesOff", "OfficeTasksOff", "StickyKeysGuard",
            "USBPowerGuard", "GameBarBackgroundOff", "OneDriveStartupOff"
        };

        string[] advanced =
        {
            "HibernationOff", "PrintSpoolerOff", "FaxOff", "RemoteRegistryOff", "RemoteAssistanceOff",
            "SMBv1Off", "XPSOff", "SandboxOff", "VirtualizationFeaturesOff", "SysMainOff"
        };

        foreach (var key in minimal)
        {
            if (_debloatChecks.TryGetValue(key, out var box)) box.IsChecked = true;
        }

        if (profile.Equals("Gaming", StringComparison.OrdinalIgnoreCase) ||
            profile.Equals("Advanced", StringComparison.OrdinalIgnoreCase))
        {
            foreach (var key in gaming)
            {
                if (_debloatChecks.TryGetValue(key, out var box)) box.IsChecked = true;
            }
        }

        if (profile.Equals("Advanced", StringComparison.OrdinalIgnoreCase))
        {
            foreach (var key in advanced)
            {
                if (_debloatChecks.TryGetValue(key, out var box)) box.IsChecked = true;
            }
        }

        UpdateStatus($"{profile} debloat selected");
    }

    private async void ApplySelectedDebloat()
    {
        var selected = _debloatChecks
            .Where(pair => pair.Value.IsChecked == true)
            .Select(pair => pair.Key)
            .ToList();

        if (selected.Count == 0)
        {
            SlxdeDialog.Show(this, "No debloat options are ticked.", "SLXDE OPTI", MessageBoxButton.OK, MessageBoxImage.Information);
            return;
        }

        var advancedKeys = new HashSet<string>
        {
            "HibernationOff", "PrintSpoolerOff", "FaxOff", "RemoteRegistryOff", "RemoteAssistanceOff",
            "SMBv1Off", "XPSOff", "SandboxOff", "VirtualizationFeaturesOff", "SysMainOff"
        };

        if (selected.Any(advancedKeys.Contains))
        {
            var confirm = SlxdeDialog.Show(this,
                "You selected advanced debloat options. Some can disable Windows features or services.\n\nContinue?",
                "SLXDE'S OPTI - Advanced Debloat",
                MessageBoxButton.YesNo,
                MessageBoxImage.Warning);

            if (confirm != MessageBoxResult.Yes)
            {
                return;
            }
        }

        UpdateStatus($"Applying {selected.Count} debloat option(s)...");
        var result = await RunPowerShellInlineAsync(BuildDebloatScript(selected));
        SlxdeDialog.Show(this, result, "SLXDE OPTI", MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private async void RestoreDebloatDefaults()
    {
        var confirm = SlxdeDialog.Show(this,
            "Restore the main debloat settings back to safe Windows defaults where possible?",
            "SLXDE'S OPTI",
            MessageBoxButton.YesNo,
            MessageBoxImage.Question);

        if (confirm != MessageBoxResult.Yes)
        {
            return;
        }

        UpdateStatus("Restoring debloat defaults...");
        var result = await RunPowerShellInlineAsync(BuildDebloatRestoreScript());
        SlxdeDialog.Show(this, result, "SLXDE OPTI", MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private static string BuildDebloatScript(List<string> optionKeys)
    {
        var lines = new List<string>();
        lines.Add("$options = @(" + string.Join(", ", optionKeys.Select(k => "'" + k.Replace("'", "''") + "'")) + ")");
        lines.Add(@"$ErrorActionPreference = 'SilentlyContinue'");
        lines.Add(@"function Set-RegDword { param([string]$Path,[string]$Name,[int]$Value) if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null } New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null }");
        lines.Add(@"function Set-RegString { param([string]$Path,[string]$Name,[string]$Value) if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null } New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force | Out-Null }");
        lines.Add(@"function Disable-TaskSafe { param([string]$Name) schtasks /Change /TN $Name /Disable 2>$null | Out-Null }");
        lines.Add(@"function Disable-ServiceSafe { param([string]$Name) Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue; Set-Service -Name $Name -StartupType Disabled -ErrorAction SilentlyContinue }");
        lines.Add(@"function Disable-FeatureSafe { param([string]$Name) dism /Online /Disable-Feature /FeatureName:$Name /NoRestart 2>$null | Out-Null }");
        lines.Add(@"foreach ($option in $options) {");
        lines.Add(@"switch ($option) {");
        lines.Add(@"'CopilotOff' { Set-RegDword 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1; Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1 }");
        lines.Add(@"'WidgetsOff' { Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0; Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarDa' 0 }");
        lines.Add(@"'TeamsChatOff' { Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarMn' 0 }");
        lines.Add(@"'ConsumerExperiencesOff' { Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1; Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled' 0; Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'ContentDeliveryAllowed' 0 }");
        lines.Add(@"'SuggestedAppsOff' { Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338388Enabled' 0; Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SystemPaneSuggestionsEnabled' 0 }");
        lines.Add(@"'TipsOff' { Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338389Enabled' 0; Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SoftLandingEnabled' 0 }");
        lines.Add(@"'AdvertisingIdOff' { Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0 }");
        lines.Add(@"'ActivityHistoryOff' { Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0; Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 0; Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities' 0 }");
        lines.Add(@"'ClipboardSyncOff' { Set-RegDword 'HKCU:\Software\Microsoft\Clipboard' 'EnableClipboardHistory' 0; Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'AllowCrossDeviceClipboard' 0 }");
        lines.Add(@"'SpotlightOff' { Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'RotatingLockScreenEnabled' 0; Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'RotatingLockScreenOverlayEnabled' 0; Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338387Enabled' 0 }");
        lines.Add(@"'EdgeStartupBoostOff' { Set-RegDword 'HKCU:\Software\Policies\Microsoft\Edge' 'StartupBoostEnabled' 0; Set-RegDword 'HKCU:\Software\Policies\Microsoft\Edge' 'BackgroundModeEnabled' 0 }");
        lines.Add(@"'SearchCloudOff' { Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0; Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' 0; Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCloudSearch' 0 }");
        lines.Add(@"'DOSoloMode' { Set-RegDword 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' 'DODownloadMode' 0; Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 0 }");
        lines.Add(@"'StoreAutoUpdatesOff' { Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore' 'AutoDownload' 2 }");
        lines.Add(@"'OfficeTasksOff' { Disable-TaskSafe '\Microsoft\Office\Office Automatic Updates 2.0'; Disable-TaskSafe '\Microsoft\Office\Office ClickToRun Service Monitor'; Disable-TaskSafe '\Microsoft\Office\OfficeTelemetryAgentFallBack2016'; Disable-TaskSafe '\Microsoft\Office\OfficeTelemetryAgentLogOn2016' }");
        lines.Add(@"'StickyKeysGuard' { Set-RegString 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '506'; Set-RegString 'HKCU:\Control Panel\Accessibility\Keyboard Response' 'Flags' '122'; Set-RegString 'HKCU:\Control Panel\Accessibility\ToggleKeys' 'Flags' '58' }");
        lines.Add(@"'USBPowerGuard' { powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 | Out-Null; powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 | Out-Null; powercfg /S SCHEME_CURRENT | Out-Null }");
        lines.Add(@"'GameBarBackgroundOff' { Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0; Set-RegDword 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0; Set-RegDword 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0 }");
        lines.Add(@"'OneDriveStartupOff' { reg delete 'HKCU\Software\Microsoft\Windows\CurrentVersion\Run' /v OneDrive /f 2>$null | Out-Null }");
        lines.Add(@"'HibernationOff' { powercfg /hibernate off | Out-Null }");
        lines.Add(@"'PrintSpoolerOff' { Disable-ServiceSafe 'Spooler' }");
        lines.Add(@"'FaxOff' { Disable-ServiceSafe 'Fax' }");
        lines.Add(@"'RemoteRegistryOff' { Disable-ServiceSafe 'RemoteRegistry' }");
        lines.Add(@"'RemoteAssistanceOff' { Set-RegDword 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' 'fAllowToGetHelp' 0 }");
        lines.Add(@"'SMBv1Off' { Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue | Out-Null }");
        lines.Add(@"'XPSOff' { Disable-FeatureSafe 'Printing-XPSServices-Features' }");
        lines.Add(@"'SandboxOff' { Disable-FeatureSafe 'Containers-DisposableClientVM' }");
        lines.Add(@"'VirtualizationFeaturesOff' { Disable-FeatureSafe 'Microsoft-Hyper-V-All'; Disable-FeatureSafe 'VirtualMachinePlatform'; Disable-FeatureSafe 'Microsoft-Windows-Subsystem-Linux' }");
        lines.Add(@"'SysMainOff' { Disable-ServiceSafe 'SysMain' }");
        lines.Add(@"}");
        lines.Add(@"}");
        lines.Add(@"Write-Output (""Applied "" + $options.Count + "" selected debloat option(s). Restart Explorer or reboot if a setting does not appear immediately."")");
        return string.Join(Environment.NewLine, lines);
    }

    private static string BuildDebloatRestoreScript()
    {
        var lines = new List<string>();
        lines.Add(@"$ErrorActionPreference = 'SilentlyContinue'");
        lines.Add(@"function Set-RegDword { param([string]$Path,[string]$Name,[int]$Value) if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null } New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null }");
        lines.Add(@"function Enable-ServiceSafe { param([string]$Name,[string]$Startup='Manual') Set-Service -Name $Name -StartupType $Startup -ErrorAction SilentlyContinue }");
        lines.Add(@"Set-RegDword 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 0");
        lines.Add(@"Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 0");
        lines.Add(@"Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 1");
        lines.Add(@"Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarDa' 1");
        lines.Add(@"Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarMn' 1");
        lines.Add(@"Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 0");
        lines.Add(@"Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 1");
        lines.Add(@"Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 1");
        lines.Add(@"Set-RegDword 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' 1");
        lines.Add(@"Set-RegDword 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 1");
        lines.Add(@"Set-RegDword 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' 'DODownloadMode' 1");
        lines.Add(@"Enable-ServiceSafe 'Spooler' 'Automatic'");
        lines.Add(@"Enable-ServiceSafe 'SysMain' 'Automatic'");
        lines.Add(@"Enable-ServiceSafe 'Fax' 'Manual'");
        lines.Add(@"Write-Output 'Debloat defaults restored where safely possible. Some optional Windows features may need to be re-enabled manually from Windows Features.'");
        return string.Join(Environment.NewLine, lines);
    }

    private void LoadGpu()
    {
        SetPage("nav_gpu", "GPU TOOLS", "Driver profiles and interrupt settings for your graphics card.", BtnGpu);

        AddCard("nav_gpu", "MSI MODE", "Enables Message Signalled Interrupt mode for the detected PCI GPU.", "Restart required", "ALL", "Enable-GuiGpuMsiMode");
        AddActionCard("monitor", "MAXIMUM REFRESH RATE", "Applies the highest supported refresh rate at the current primary-display resolution.", "Keeps current resolution", "APPLY  >", ApplyMaximumRefreshRate);
        AddActionCard("nav_gpu", "GAME HIGH-PERFORMANCE GPU", "Choose a game executable and assign it to Windows' High performance GPU.", "Per-game setting", "CHOOSE  >", ChooseGameHighPerformanceGpu);
        CardsHost.Children.Add(CreateCard(
            "NVIDIA",
            "NVIDIA CONTROL PANEL OPTIMISATION",
            "Backs up and applies a verified competitive NVIDIA driver profile in one click.",
            "NVIDIA only · backed up",
            "APPLY  >",
            ApplyNvidiaControlPanelProfile));
        AddGuideCard("AMD", "AMD SETTINGS", "Opens the AMD best settings screenshot guide.", "AMD only", OpenAmdSettingsGuide);
    }


    private void LoadNetwork()
    {
        SetPage("nav_network", "NETWORK TWEAKS", "Network helper tools and adapter options.", BtnNetwork);

        AddCard("nav_network", "NETWORK PACK", "Applies supported safe adapter options and flushes DNS.", "Adapter support varies", "ALL", "Invoke-GuiNetworkPack");
        AddCard("bolt", "OPTIMISE DNS", "Tests trusted DNS providers and applies the fastest reliable option.", "Backs up current DNS", "ALL", "Invoke-GuiOptimiseDns");
        AddCard("restore", "RESTORE DNS", "Restores the DNS settings saved before optimisation.", "", "ALL", "Restore-GuiDnsSettings");
        AddCard("bolt", "PREFER IPv4", "Keeps IPv6 enabled but gives IPv4 priority when both are available.", "Restart required", "ALL", "Set-GuiPreferIPv4");
        AddCard("restore", "RESTORE IP PREFERENCE", "Returns Windows IPv4/IPv6 selection to its default behaviour.", "Restart required", "ALL", "Restore-GuiIpPreference");
        AddCard("nav_network", "RESET NETWORK STACK", "Runs DNS flush, Winsock reset and IP reset.", "Restart required", "ALL", "Reset-GuiNetworkStack");
        AddCard("info", "SHOW ACTIVE ADAPTER INFO", "Displays adapter, link speed, IP, gateway and DNS details.", "", "ALL", "Get-GuiActiveAdapterInfo");
    }

    private void LoadController()
    {
        SetPage("nav_controller", "CONTROLLER / KBM", "Input, controller and keyboard/mouse related tweaks.", BtnController);

        AddCard("videooff", "DISABLE USB POWER SAVING", "Prevents USB selective suspend where supported.", "", "ALL", "Disable-USBPowerSaving");
        AddCard("mouse", "DISABLE MOUSE ACCELERATION", "Turns off enhanced pointer precision.", "", "ALL", "Disable-MouseAcceleration");
        AddCard("activity", "INPUT RESPONSIVENESS", "Applies safe input responsiveness tweaks.", "Restart recommended", "ALL", "Set-GuiInputResponsiveness");
        AddCard("mouse", "OPEN MOUSE SETTINGS", "Opens Windows mouse and pointer settings.", "", "ALL", "Open-GuiMouseSettings");
    }


    private void LoadGameConfigs()
    {
        SetPage("nav_gameconfigs", "GAME CONFIGS", "Esports-tuned config presets with automatic backups.", BtnGameConfigs);

        AddInfoCard(
            "GAME CONFIGS - SAFE APPLY",
            "Game Configs backs up the original config first, then applies safe esports-style settings where the game config file is found.",
            "• Close the game before applying a config.\n• Launch the game once first so its config files exist.\n• If anything feels wrong, use Restore Latest Game Config Backup.\n• These presets focus on visibility, latency and competitive settings, not ultra graphics.");

        AddActionCard("nav_gameconfigs", "BO7 CONFIG", "Applies best BO7 config for max FPS.", "Close BO7 first", "APPLY  >", ApplyCodConfigWithProgress);
        AddCard("nav_gameconfigs", "FORTNITE CONFIG", "Applies best Fortnite config for max FPS.", "Close Fortnite first", "ALL", "Apply-GuiFortniteConfig");
        AddCard("nav_gameconfigs", "ROCKET LEAGUE CONFIG", "Applies best Rocket League config for max FPS.", "Close Rocket League first", "ALL", "Apply-GuiRocketLeagueConfig");
        AddCard("restore", "RESTORE LATEST GAME CONFIG BACKUP", "Restores the most recent game config backup made by SLXDE.", "Use if a config feels wrong", "ALL", "Restore-GuiLatestGameConfigBackup");
        AddCard("folder", "OPEN GAME CONFIG BACKUPS", "Opens the SLXDE game config backup folder.", "", "ALL", "Open-GuiGameConfigBackups");
    }

    private void LoadCleanup()
    {
        SetPage("nav_cleanup", "CLEAN-UP / HEALTH", "Cleanup tools and Windows repair helpers.", BtnCleanup);

        AddCard("trash", "DELETE TEMP FILES", "Clears common Windows temp folders.", "", "ALL", "Clear-TempFiles");
        AddCard("trash", "CLEAR SHADER CACHES", "Clears common AMD/NVIDIA/DirectX shader cache folders.", "", "ALL", "Clear-ShaderCaches");
        AddCard("disk", "OPEN DISK CLEANUP", "Opens Windows Disk Cleanup.", "", "ALL", "Start-DiskCleanup");
        AddCard("folder", "OPEN AMD SHADER CACHE", "Opens the AMD shader cache folder.", "", "ALL", "Open-AMDShaderCacheFolder");
        AddCard("folder", "OPEN NVIDIA SHADER CACHE", "Opens the NVIDIA shader cache folder.", "", "ALL", "Open-NvidiaShaderCacheFolder");
        AddActionCard("activity", "SYSTEM FILE CHECK", "Runs SFC in a visible administrator Command Prompt.", "Can take 5–20 minutes", "APPLY  >", LaunchSystemFileCheck);
        AddActionCard("repair", "WINDOWS IMAGE REPAIR", "Runs DISM in a visible administrator Command Prompt.", "Can look stuck", "APPLY  >", LaunchWindowsImageRepair);
    }

    private void LoadQuality()
    {
        SetPage("nav_quality", "QUALITY OF LIFE", "Small Windows usability tweaks that make the system nicer to use.", BtnQuality);

        AddCard("endtask", "ENABLE RIGHT-CLICK END TASK", "Adds End Task to supported taskbar app right-click menus.", "Restart Explorer if needed", "ALL", "Enable-GuiRightClickEndTask");
        AddCard("folder", "EXPLORER OPENS THIS PC", "Makes File Explorer open to This PC instead of Home/Quick Access.", "", "ALL", "Set-GuiExplorerThisPC");
        AddCard("timer", "REDUCE MENU / HOVER DELAY", "Makes Windows menus and hover actions feel more responsive.", "Sign out/restart recommended", "ALL", "Set-GuiFastMenuDelay");
        AddCard("timer", "DISABLE STARTUP APPS DELAY", "Removes Windows startup app launch delay.", "", "ALL", "Disable-GuiStartupAppsDelay");
        AddCard("nav_quality", "OPEN STARTUP APPS SETTINGS", "Opens Windows Startup Apps so you can disable unnecessary apps.", "", "ALL", "Open-GuiStartupAppsSettings");
        AddCard("explorerrefresh", "RESTART EXPLORER", "Restarts Windows Explorer to apply shell/UI changes.", "", "ALL", "Restart-GuiExplorer");
    }

    private void LoadBackup()
    {
        SetPage("nav_backup", "BACKUP / RESTORE", "Create backups before applying bigger changes.", BtnBackup);

        AddCard("nav_backup", "CREATE BACKUP NOW", "Creates restore point attempt and exports key settings.", "", "ALL", "New-SlxdeBackup");
        AddCard("restore", "RESTORE LATEST BACKUP", "Restores the latest exported backup.", "Use carefully", "ALL", "Restore-GuiLatestBackup");
        AddCard("folder", "OPEN BACKUP FOLDER", "Opens the backup folder.", "", "ALL", "Open-GuiBackupFolder");
        AddCard("restore", "OPEN SYSTEM RESTORE", "Opens the Windows restore wizard to choose a restore point.", "", "ALL", "Open-GuiSystemRestore");
        AddCard("nav_quality", "RESTORE POINT SETTINGS", "Opens System Protection to manage restore points and disk usage.", "", "ALL", "Open-GuiSystemProtection");
    }

    private void OpenAmdSettingsGuide()
    {
        var guideFolder = Path.Combine(AppContext.BaseDirectory, "Assets", "Guides", "AMD");

        var captions = new List<string>
        {
            "Gaming graphics: global profile and the main Radeon performance features.",
            "Preferences: disable overlays, notifications and other unnecessary background features.",
            "Performance tuning: use the supplied GPU, VRAM, fan and power reference carefully.",
            "Advanced graphics: filtering, tessellation, shader cache and format options."
        };

        var window = new GuideWindow("AMD Driver Settings Guide", guideFolder, captions)
        {
            Owner = this
        };

        window.ShowDialog();
    }

    private void Dashboard_Click(object sender, RoutedEventArgs e) => LoadDashboard();
    private void Windows_Click(object sender, RoutedEventArgs e) => LoadWindows();
    private void Debloat_Click(object sender, RoutedEventArgs e) => LoadDebloat();
    private void Gpu_Click(object sender, RoutedEventArgs e) => LoadGpu();
    private void Network_Click(object sender, RoutedEventArgs e) => LoadNetwork();
    private void Controller_Click(object sender, RoutedEventArgs e) => LoadController();
    private void GameConfigs_Click(object sender, RoutedEventArgs e) => LoadGameConfigs();
    private void Cleanup_Click(object sender, RoutedEventArgs e) => LoadCleanup();
    private void Quality_Click(object sender, RoutedEventArgs e) => LoadQuality();
    private void Backup_Click(object sender, RoutedEventArgs e) => LoadBackup();
}
