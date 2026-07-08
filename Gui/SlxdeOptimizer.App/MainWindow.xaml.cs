using SlxdeOptimizer.App.Services;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Security.Principal;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;

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
    private int _slxdeActiveGames;

    private readonly PowerShellRunner _runner = new();
    private readonly List<Button> _sidebarButtons = new();
    private readonly Dictionary<string, CheckBox> _debloatChecks = new();

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

        SetSidebarButton(BtnDashboard, "nav_dashboard", "DASHBOARD");
        SetSidebarButton(BtnWindows, "nav_windows", "WINDOWS");
        SetSidebarButton(BtnGpu, "nav_gpu", "GPU");
        SetSidebarButton(BtnNetwork, "nav_network", "NETWORK");
        SetSidebarButton(BtnController, "nav_controller", "CONTROLLER / KBM");
        SetSidebarButton(BtnGameConfigs, "nav_gameconfigs", "GAME CONFIGS");
        SetSidebarButton(BtnDebloat, "nav_debloat", "DEBLOAT");
        SetSidebarButton(BtnCleanup, "nav_cleanup", "CLEAN-UP / HEALTH");
        SetSidebarButton(BtnQuality, "nav_quality", "QUALITY OF LIFE");
        SetSidebarButton(BtnBackup, "nav_backup", "BACKUP / RESTORE");
    }



    private static bool TryLoadAssetImage(string folder, string name, out BitmapImage? image)
    {
        image = null;

        // First try WPF embedded Resource loading. This is the reliable path for
        // Visual Studio, dotnet run, and published single-file builds.
        try
        {
            var resourceUri = new Uri($"/Assets/{folder}/{name}.png", UriKind.Relative);
            var streamInfo = Application.GetResourceStream(resourceUri);

            if (streamInfo?.Stream != null)
            {
                using var stream = streamInfo.Stream;
                var bitmap = new BitmapImage();
                bitmap.BeginInit();
                bitmap.CacheOption = BitmapCacheOption.OnLoad;
                bitmap.StreamSource = stream;
                bitmap.EndInit();
                bitmap.Freeze();
                image = bitmap;
                return true;
            }
        }
        catch
        {
            // Fall back to output-folder file loading below.
        }

        // Fallback for copied Content folders.
        try
        {
            var path = Path.Combine(AppContext.BaseDirectory, "Assets", folder, $"{name}.png");
            if (!File.Exists(path)) return false;

            var bitmap = new BitmapImage();
            bitmap.BeginInit();
            bitmap.CacheOption = BitmapCacheOption.OnLoad;
            bitmap.UriSource = new Uri(path, UriKind.Absolute);
            bitmap.EndInit();
            bitmap.Freeze();
            image = bitmap;
            return true;
        }
        catch
        {
            image = null;
            return false;
        }
    }



    private static FrameworkElement CreateIconElement(string iconKey, double size, double fallbackFontSize)
    {
        if (iconKey.StartsWith("nav_", StringComparison.OrdinalIgnoreCase) &&
            TryLoadAssetImage("Nav", iconKey, out var navImage) &&
            navImage != null)
        {
            return new Image
            {
                Source = navImage,
                Width = size,
                Height = size,
                Stretch = Stretch.Uniform,
                SnapsToDevicePixels = true,
                UseLayoutRounding = true
            };
        }

        // Only use text fallbacks for missing sidebar PNGs.
        // Normal card icons are already real Segoe MDL2 glyph codes, so render them directly.
        var isNavKey = iconKey.StartsWith("nav_", StringComparison.OrdinalIgnoreCase);

        var fallback = isNavKey
            ? iconKey switch
            {
                "nav_dashboard" => "⌂",
                "nav_windows" => "⊞",
                "nav_debloat" => "✦",
                "nav_gpu" => "GPU",
                "nav_network" => "▂▅▇",
                "nav_controller" => "🎮",
                "nav_cleanup" => "✚",
                "nav_quality" => "⚙",
                "nav_backup" => "↺",
                _ => "?"
            }
            : iconKey == "WIN"
                ? "⊞"
                : iconKey;

        var fontFamily = isNavKey || iconKey == "WIN"
            ? "Segoe UI Symbol, Segoe UI"
            : "Segoe MDL2 Assets, Segoe UI Symbol, Segoe UI";

        return new TextBlock
        {
            Text = fallback,
            FontFamily = new FontFamily(fontFamily),
            Foreground = Brushes.White,
            FontSize = fallback == "GPU" ? fallbackFontSize * 0.55 : fallbackFontSize,
            FontWeight = FontWeights.Black,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            TextAlignment = TextAlignment.Center
        };
    }




    private static void SetSidebarButton(Button button, string glyph, string label)
    {
        var grid = new Grid { VerticalAlignment = VerticalAlignment.Center };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(50) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var icon = CreateIconElement(glyph, 42, 30);
        icon.HorizontalAlignment = HorizontalAlignment.Center;
        icon.VerticalAlignment = VerticalAlignment.Center;
        Grid.SetColumn(icon, 0);
        grid.Children.Add(icon);

        var labelText = new TextBlock
        {
            Text = label,
            Foreground = new SolidColorBrush(Color.FromRgb(240, 249, 255)),
            FontWeight = FontWeights.Black,
            FontSize = 15,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(8, 0, 0, 0),
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

        active.Background = new LinearGradientBrush(Color.FromRgb(15, 96, 178), Color.FromRgb(4, 26, 52), 0);
        active.BorderBrush = new SolidColorBrush(Color.FromRgb(47, 168, 255));
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
        if (iconGlyph.StartsWith("nav_", StringComparison.OrdinalIgnoreCase) &&
            TryLoadAssetImage("Nav", iconGlyph, out var navImage) &&
            navImage != null)
        {
            PageIconImage.Source = navImage;
            PageIconImage.Visibility = Visibility.Visible;
            PageIcon.Visibility = Visibility.Collapsed;
        }
        else
        {
            PageIconImage.Visibility = Visibility.Collapsed;
            PageIcon.Visibility = Visibility.Visible;
            PageIcon.Text = iconGlyph == "WIN" ? "⊞" : iconGlyph;
            PageIcon.FontFamily = new FontFamily(iconGlyph == "WIN" ? "Segoe UI Symbol" : "Segoe MDL2 Assets");
            PageIcon.FontSize = iconGlyph == "WIN" ? 46 : 44;
        }

        PageTitle.Text = title;
        PageSubtitle.Text = subtitle;
        CardsHost.Children.Clear();
        HighlightSidebar(activeButton);
    }



    private Border CreateCard(string iconGlyph, string title, string description, string warning, string buttonText, Action action)
    {
        var border = new Border { Style = (Style)FindResource("CardBorder") };

        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(92) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(205) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(185) });

        var iconBox = new Border
        {
            Width = 66,
            Height = 66,
            CornerRadius = new CornerRadius(14),
            Background = new LinearGradientBrush(Color.FromRgb(16, 116, 220), Color.FromRgb(5, 35, 77), 45),
            BorderBrush = new SolidColorBrush(Color.FromRgb(47, 168, 255)),
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
                FontSize = iconGlyph == "AMD" ? 17 : 11,
                FontWeight = FontWeights.Black,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center
            };
        }
        else
        {
            var iconElement = CreateIconElement(iconGlyph, 46, 30);
            iconElement.HorizontalAlignment = HorizontalAlignment.Center;
            iconElement.VerticalAlignment = VerticalAlignment.Center;
            iconBox.Child = iconElement;
        }

        Grid.SetColumn(iconBox, 0);
        grid.Children.Add(iconBox);

        var textStack = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        textStack.Children.Add(new TextBlock
        {
            Text = title,
            Foreground = Brushes.White,
            FontSize = 18,
            FontWeight = FontWeights.Black
        });
        textStack.Children.Add(new TextBlock
        {
            Text = description,
            Foreground = (Brush)FindResource("MutedBrush"),
            FontSize = 13,
            Margin = new Thickness(0, 4, 0, 0),
            TextWrapping = TextWrapping.Wrap
        });

        Grid.SetColumn(textStack, 1);
        grid.Children.Add(textStack);

        var warningText = new TextBlock
        {
            Text = warning,
            Foreground = (Brush)FindResource("WarningBrush"),
            FontSize = 12,
            FontWeight = FontWeights.Black,
            TextWrapping = TextWrapping.Wrap,
            VerticalAlignment = VerticalAlignment.Center,
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
        MessageBox.Show(result, "SLXDE'S OPTI", MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private void AddSectionHeader(string title, string subtitle, string accent)
    {
        var border = new Border
        {
            BorderThickness = new Thickness(0, 1, 0, 1),
            BorderBrush = new SolidColorBrush(Color.FromRgb(120, 112, 145)),
            Background = Brushes.Transparent,
            Padding = new Thickness(18, 18, 18, 14),
            Margin = new Thickness(0, 12, 0, 12)
        };

        var stack = new StackPanel
        {
            HorizontalAlignment = HorizontalAlignment.Center
        };

        stack.Children.Add(new TextBlock
        {
            Text = title,
            Foreground = Brushes.White,
            FontSize = 24,
            FontWeight = FontWeights.Black,
            FontFamily = new FontFamily("Arial Black, Segoe UI Black, Segoe UI"),
            HorizontalAlignment = HorizontalAlignment.Center
        });

        stack.Children.Add(new TextBlock
        {
            Text = subtitle,
            Foreground = (Brush)FindResource("SubtleBrush"),
            FontSize = 13,
            Margin = new Thickness(0, 4, 0, 0),
            HorizontalAlignment = HorizontalAlignment.Center
        });

        border.Child = stack;
        CardsHost.Children.Add(border);
    }

    private void AddCard(string icon, string title, string description, string warning, string module, string function)
    {
        CardsHost.Children.Add(CreateCard(icon, title, description, warning, "APPLY  >", () => RunPowerShell(module, function)));
    }

    private void AddGuideCard(string icon, string title, string description, string warning, Action action)
    {
        CardsHost.Children.Add(CreateCard(icon, title, description, warning, "OPEN  >", action));
    }

    private void AddPreviewCard(string icon, string title, string description, string warning = "")
    {
        CardsHost.Children.Add(CreateCard(icon, title, description, warning, "PREVIEW",
            () => MessageBox.Show("This button is laid out for the GUI preview. Function wiring comes next.", "SLXDE'S OPTI")));
    }


    private string GetCpuNameForGameMode()
    {
        try
        {
            var value = Microsoft.Win32.Registry.GetValue(
                @"HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\CentralProcessor\0",
                "ProcessorNameString",
                null)?.ToString();

            if (!string.IsNullOrWhiteSpace(value))
            {
                return value.Trim();
            }
        }
        catch
        {
        }

        return "Unknown CPU";
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
            Text = title,
            Foreground = Brushes.White,
            FontSize = 20,
            FontWeight = FontWeights.Black,
            Margin = new Thickness(0, 0, 0, 14)
        });

        stack.Children.Add(new TextBlock
        {
            Text = body,
            Foreground = new SolidColorBrush(Color.FromRgb(33, 246, 181)),
            FontSize = 13,
            FontWeight = FontWeights.Bold,
            TextWrapping = TextWrapping.Wrap,
            Margin = new Thickness(0, 0, 0, 14)
        });

        stack.Children.Add(new TextBlock
        {
            Text = "Tips",
            Foreground = new SolidColorBrush(Color.FromRgb(255, 211, 61)),
            FontSize = 13,
            FontWeight = FontWeights.Black,
            Margin = new Thickness(0, 0, 0, 6)
        });

        stack.Children.Add(new TextBlock
        {
            Text = tips,
            Foreground = new SolidColorBrush(Color.FromRgb(255, 172, 45)),
            FontSize = 12,
            FontWeight = FontWeights.Bold,
            TextWrapping = TextWrapping.Wrap
        });

        border.Child = stack;
        CardsHost.Children.Add(border);
    }



    private void LoadDashboard()
    {
        SetPage("nav_dashboard", "DASHBOARD", "Quick overview and common actions.", BtnDashboard);

        var cpuName = GetCpuNameForGameMode();
        var recommendedMode = GetCpuPerformanceModeRecommendation();
        var performanceModeDescription = $"CPU Mode: {recommendedMode} | Active Games: {_slxdeActiveGames} | {cpuName}";

        AddInfoCard(
            "HOW SLXDE'S PERFORMANCE MODE WORKS",
            "SLXDE'S Performance Mode detects your CPU and applies safe gaming-focused Windows settings. AMD/Ryzen systems use Balanced mode. Intel/Core systems use Optimal mode. Do Not Disturb is not changed.",
            "• Enable Performance Mode before launching your game for best results.\n• Performance Mode settings remain active after the app is closed until you turn Performance Mode off.\n• Live detected-game counters only update while the SLXDE app is open.\n• If performance feels worse, turn Performance Mode off and retest.\n• This does not disable Defender, HPET, security mitigations, or unsafe system services.");

        AddActionCard("nav_controller", "SLXDE'S PERFORMANCE MODE", performanceModeDescription, _slxdePerformanceModeEnabled ? "Active" : "Recommended", _slxdePerformanceModeEnabled ? "TURN OFF  >" : "TURN ON  >", ToggleSlxdePerformanceMode);

        AddCard("\uE9D9", "ANALYZE PC", "Runs the current console analyzer from the PowerShell engine.", "", "ALL", "Get-GuiGamingAnalysis");
        AddCard("\uE777", "CREATE BACKUP", "Creates a restore point attempt and exports key settings.", "", "ALL", "New-SlxdeBackup");
        AddActionCard("\uE8A5", "VIEW LATEST LOG", "Shows the latest optimizer log output.", "", "APPLY  >", ShowLatestLogStatusOnly);
    }


    private void LoadWindows()
    {
        SetPage("nav_windows", "WINDOWS", "Windows, gaming and performance settings in one place.", BtnWindows);

        AddCard("\uE756", "ENABLE SCRIPTS", "Unblocks optimizer files and allows local scripts for easier use.", "Do this first", "ALL", "Enable-GuiOptimizerScripts");
        AddCard("\uE72C", "REVERT WINDOWS OPTI", "Reverts the main Windows, gaming and power-plan optimizer changes.", "Restart recommended", "ALL", "Restore-GuiWindowsDefaults");
        AddCard("\uE9D5", "LOAD BALANCED POWER PLAN", "Activates a safer Balanced power plan for laptops or high temps.", "Safer cooling choice", "ALL", "Set-BalancedPowerPlan");
        AddCard("\uE945", "LOAD OPTIMAL POWER PLAN", "Activates the desktop/performance-focused optimal power plan.", "May increase temperature", "ALL", "Set-GuiSlxdePowerPlan");

        AddCard("\uE7FC", "ENABLE GAME MODE", "Enables Windows Performance Mode.", "", "ALL", "Enable-GameMode");
        AddCard("\uE722", "DISABLE GAME DVR", "Disables Game DVR and Xbox capture background recording.", "", "ALL", "Disable-GameDVR");
        AddCard("\uE950", "ENABLE HAGS", "Enables Hardware Accelerated GPU Scheduling where supported.", "Restart recommended", "ALL", "Enable-HAGS");
        AddCard("\uE7F4", "ENABLE WINDOWED OPTIMIZATIONS", "Enables modern windowed game optimizations.", "", "ALL", "Enable-WindowedOptimizations");
        AddCard("\uE771", "OPTIMISE WINDOWS APPEARANCE", "Tweaks visual effects and appearance for performance.", "", "ALL", "Optimize-WindowsAppearance");
        AddCard("\uE71D", "DISABLE BACKGROUND APPS", "Reduces background app activity where supported.", "", "ALL", "Disable-BackgroundApps");
        AddCard("\uE707", "DISABLE LOCATION TRACKING", "Turns off Windows location access setting.", "", "ALL", "Disable-LocationTracking");
    }




    private void LoadDebloat()
    {
        SetPage("nav_debloat", "DEBLOAT", "Choose a profile or tick individual Windows debloat options.", BtnDebloat);
        _debloatChecks.Clear();

        AddInfoCard(
            "DEBLOAT - SAFE APPLY",
            "Select a preset, then tick or untick individual options before applying.",
            "• Minimal is recommended for most users.\n• Gaming adds background/network reductions.\n• Advanced can disable Windows features and services, so read warnings first.\n• Create a backup before big changes.");

        AddSectionHeader("PROFILE PRESETS", "Choose a preset, then customise the tick boxes below.", "");
        AddActionCard("nav_debloat", "MINIMAL DEBLOAT", "Safe cleanup for most gaming PCs.", "Recommended", "SELECT  >", () => SetDebloatProfile("Minimal"));
        AddActionCard("nav_debloat", "GAMING DEBLOAT", "Minimal debloat plus gaming-focused background reductions.", "", "SELECT  >", () => SetDebloatProfile("Gaming"));
        AddActionCard("nav_debloat", "ADVANCED DEBLOAT", "Extra service and Windows feature removals with warnings.", "Advanced", "SELECT  >", () => SetDebloatProfile("Advanced"));

        AddSectionHeader("APPLY / RESTORE", "Apply your selected checkboxes or restore safe defaults.", "");
        AddActionCard("\uE8FB", "APPLY SELECTED DEBLOAT", "Applies every ticked debloat option below.", "Backup recommended", "APPLY  >", ApplySelectedDebloat);
        AddActionCard("\uE72C", "RESTORE DEBLOAT DEFAULTS", "Restores the main debloat changes where safely possible.", "Use if something feels wrong", "RESTORE  >", RestoreDebloatDefaults);

        AddSectionHeader("SAFE OPTIONS", "Good default options for most Windows gaming PCs.", "");
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
        AddDebloatOption("SearchCloudOff", "Search Cloud Off", "Keeps Start/Search more local and reduces Bing/cloud results. Can reduce search-related network usage.", "", false);
        AddDebloatOption("DOSoloMode", "Delivery Optimization Solo Mode", "Stops Windows from sharing update files with other PCs. Can reduce background bandwidth usage.", "", false);
        AddDebloatOption("StoreAutoUpdatesOff", "Store Auto Updates Off", "Stops Microsoft Store apps auto-updating in the background. You may need to update apps manually.", "Manual app updates needed", false);
        AddDebloatOption("OfficeTasksOff", "Office Background Tasks Off", "Disables common Office update/telemetry scheduled tasks. Office may need manual update checks.", "Office updates may need manual checks", false);
        AddDebloatOption("StickyKeysGuard", "StickyKeys Guard", "Prevents Sticky Keys, Filter Keys and Toggle Keys popups mid-game. Safe quality-of-life tweak.", "", false);
        AddDebloatOption("USBPowerGuard", "USB Power Guard", "Disables USB selective suspend on the active power plan. Can help mice, keyboards, controllers and headsets stay responsive.", "", false);
        AddDebloatOption("GameBarBackgroundOff", "Game Bar Background Off", "Disables capture/background Game Bar pieces while keeping Windows Game Mode separate.", "", false);
        AddDebloatOption("OneDriveStartupOff", "OneDrive Startup Off", "Stops OneDrive from auto-starting. Only use this if you do not rely on OneDrive sync.", "Only if you do not use OneDrive sync", false);

        AddSectionHeader("ADVANCED OPTIONS", "Use only if you understand the trade-offs.", "");
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
        var border = new Border { Style = (Style)FindResource("CardBorder"), MinHeight = 116 };

        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(92) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(205) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(120) });

        var iconBox = new Border
        {
            Width = 66,
            Height = 66,
            CornerRadius = new CornerRadius(14),
            Background = new LinearGradientBrush(Color.FromRgb(16, 116, 220), Color.FromRgb(5, 35, 77), 45),
            BorderBrush = new SolidColorBrush(Color.FromRgb(47, 168, 255)),
            BorderThickness = new Thickness(1),
            VerticalAlignment = VerticalAlignment.Center
        };

        var iconElement = CreateIconElement("nav_debloat", 46, 30);
        iconElement.HorizontalAlignment = HorizontalAlignment.Center;
        iconElement.VerticalAlignment = VerticalAlignment.Center;
        iconBox.Child = iconElement;
        Grid.SetColumn(iconBox, 0);
        grid.Children.Add(iconBox);

        var textStack = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        textStack.Children.Add(new TextBlock
        {
            Text = title,
            Foreground = Brushes.White,
            FontSize = 18,
            FontWeight = FontWeights.Black
        });
        textStack.Children.Add(new TextBlock
        {
            Text = description,
            Foreground = (Brush)FindResource("MutedBrush"),
            FontSize = 12,
            Margin = new Thickness(0, 6, 0, 0),
            TextWrapping = TextWrapping.Wrap
        });
        Grid.SetColumn(textStack, 1);
        grid.Children.Add(textStack);

        var warningText = new TextBlock
        {
            Text = warning,
            Foreground = (Brush)FindResource("WarningBrush"),
            FontSize = 12,
            FontWeight = FontWeights.Black,
            TextWrapping = TextWrapping.Wrap,
            VerticalAlignment = VerticalAlignment.Center,
            Visibility = string.IsNullOrWhiteSpace(warning) ? Visibility.Hidden : Visibility.Visible
        };
        Grid.SetColumn(warningText, 2);
        grid.Children.Add(warningText);

        var check = new CheckBox
        {
            IsChecked = defaultChecked,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Width = 28,
            Height = 28,
            ToolTip = "Tick to include this option when applying selected debloat."
        };

        Grid.SetColumn(check, 3);
        grid.Children.Add(check);

        _debloatChecks[key] = check;
        border.Child = grid;
        CardsHost.Children.Add(border);
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
            MessageBox.Show("No debloat options are ticked.", "SLXDE'S OPTI", MessageBoxButton.OK, MessageBoxImage.Information);
            return;
        }

        var advancedKeys = new HashSet<string>
        {
            "HibernationOff", "PrintSpoolerOff", "FaxOff", "RemoteRegistryOff", "RemoteAssistanceOff",
            "SMBv1Off", "XPSOff", "SandboxOff", "VirtualizationFeaturesOff", "SysMainOff"
        };

        if (selected.Any(advancedKeys.Contains))
        {
            var confirm = MessageBox.Show(
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
        MessageBox.Show(result, "SLXDE'S OPTI", MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private async void RestoreDebloatDefaults()
    {
        var confirm = MessageBox.Show(
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
        MessageBox.Show(result, "SLXDE'S OPTI", MessageBoxButton.OK, MessageBoxImage.Information);
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
        SetPage("nav_gpu", "GPU TOOLS", "GPU settings, driver helpers and latency tools.", BtnGpu);

        AddSectionHeader("ALL GPU SETTINGS", "This section is for all GPU users.", "");
        AddCard("nav_gpu", "MSI MODE", "Enables Message Signalled Interrupt mode for the detected PCI GPU.", "Restart required", "ALL", "Enable-GuiGpuMsiMode");

        AddSectionHeader("NVIDIA GPU SETTINGS", "This section is for NVIDIA GPU users.", "NVIDIA");
        AddCard("NVIDIA", "NVIDIA DRIVER SETTINGS", "Applies safe NVIDIA helpers and shows the recommended NVIDIA Control Panel settings.", "NVIDIA only", "ALL", "Apply-GuiNvidiaDriverSettings");

        AddSectionHeader("AMD GPU SETTINGS", "This section is for AMD GPU users.", "AMD");
        AddGuideCard("AMD", "AMD SETTINGS", "Opens the AMD best settings screenshot guide.", "AMD only", OpenAmdSettingsGuide);
    }


    private void LoadNetwork()
    {
        SetPage("nav_network", "NETWORK TWEAKS", "Network helper tools and adapter options.", BtnNetwork);

        AddCard("\uE968", "NETWORK PACK", "Applies supported safe adapter options and flushes DNS.", "Adapter support varies", "ALL", "Invoke-GuiNetworkPack");
        AddCard("\uE72C", "RESET NETWORK STACK", "Runs DNS flush, Winsock reset and IP reset.", "Restart required", "ALL", "Reset-GuiNetworkStack");
        AddCard("\uE946", "SHOW ACTIVE ADAPTER INFO", "Displays active network adapter information.", "", "ALL", "Get-GuiActiveAdapterInfo");
    }

    private void LoadController()
    {
        SetPage("nav_controller", "CONTROLLER / KBM", "Input, controller and keyboard/mouse related tweaks.", BtnController);

        AddCard("\uE88E", "DISABLE USB POWER SAVING", "Prevents USB selective suspend where supported.", "", "ALL", "Disable-USBPowerSaving");
        AddCard("\uE962", "DISABLE MOUSE ACCELERATION", "Turns off enhanced pointer precision.", "", "ALL", "Disable-MouseAcceleration");
        AddCard("\uE9D9", "INPUT RESPONSIVENESS", "Applies safe input responsiveness tweaks.", "Restart recommended", "ALL", "Set-GuiInputResponsiveness");
    }


    private void LoadGameConfigs()
    {
        SetPage("nav_gameconfigs", "GAME CONFIGS", "Esports-tuned config presets with automatic backups.", BtnGameConfigs);

        AddInfoCard(
            "GAME CONFIGS - SAFE APPLY",
            "Game Configs backs up the original config first, then applies safe esports-style settings where the game config file is found.",
            "• Close the game before applying a config.\n• Launch the game once first so its config files exist.\n• If anything feels wrong, use Restore Latest Game Config Backup.\n• These presets focus on visibility, latency and competitive settings, not ultra graphics.");

        AddCard("nav_gameconfigs", "COD BO7 GRAPHICS CONFIG", "Applies best BO7 config for max FPS.", "Close BO7 first", "ALL", "Apply-GuiCodBo7Config");
        AddCard("nav_gameconfigs", "FORTNITE CONFIG", "Applies best Fortnite config for max FPS.", "Close Fortnite first", "ALL", "Apply-GuiFortniteConfig");
        AddCard("nav_gameconfigs", "ROCKET LEAGUE CONFIG", "Applies best Rocket League config for max FPS.", "Close Rocket League first", "ALL", "Apply-GuiRocketLeagueConfig");
        AddCard("\uE72C", "RESTORE LATEST GAME CONFIG BACKUP", "Restores the most recent game config backup made by SLXDE.", "Use if a config feels wrong", "ALL", "Restore-GuiLatestGameConfigBackup");
        AddCard("\uE838", "OPEN GAME CONFIG BACKUPS", "Opens the SLXDE game config backup folder.", "", "ALL", "Open-GuiGameConfigBackups");
    }

    private void LoadCleanup()
    {
        SetPage("nav_cleanup", "CLEAN-UP / HEALTH", "Cleanup tools and Windows repair helpers.", BtnCleanup);

        AddCard("\uE74D", "DELETE TEMP FILES", "Clears common Windows temp folders.", "", "ALL", "Clear-TempFiles");
        AddCard("\uE8B7", "CLEAR SHADER CACHES", "Clears common AMD/NVIDIA/DirectX shader cache folders.", "", "ALL", "Clear-ShaderCaches");
        AddCard("\uE9F5", "OPEN DISK CLEANUP", "Opens Windows Disk Cleanup.", "", "ALL", "Start-DiskCleanup");
        AddCard("\uE8B7", "OPEN AMD SHADER CACHE", "Opens the AMD shader cache folder.", "", "ALL", "Open-AMDShaderCacheFolder");
        AddCard("\uE8B7", "OPEN NVIDIA SHADER CACHE", "Opens the NVIDIA shader cache folder.", "", "ALL", "Open-NvidiaShaderCacheFolder");
        AddCard("\uE9D9", "SYSTEM FILE CHECK", "Runs SFC with warning screen.", "Can take 5-20 minutes", "ALL", "Invoke-GuiSystemFileCheck");
        AddCard("\uE930", "WINDOWS IMAGE REPAIR", "Runs DISM with warning screen.", "Can look stuck", "ALL", "Invoke-GuiWindowsImageRepair");
    }

    private void LoadQuality()
    {
        SetPage("nav_quality", "QUALITY OF LIFE", "Small Windows usability tweaks that make the system nicer to use.", BtnQuality);

        AddCard("\uE8BB", "ENABLE RIGHT-CLICK END TASK", "Adds End Task to supported taskbar app right-click menus.", "Restart Explorer if needed", "ALL", "Enable-GuiRightClickEndTask");
        AddCard("\uE838", "EXPLORER OPENS THIS PC", "Makes File Explorer open to This PC instead of Home/Quick Access.", "", "ALL", "Set-GuiExplorerThisPC");
        AddCard("\uE7C1", "REDUCE MENU / HOVER DELAY", "Makes Windows menus and hover actions feel more responsive.", "Sign out/restart recommended", "ALL", "Set-GuiFastMenuDelay");
        AddCard("\uE7B3", "DISABLE STARTUP APPS DELAY", "Removes Windows startup app launch delay.", "", "ALL", "Disable-GuiStartupAppsDelay");
        AddCard("\uE713", "OPEN STARTUP APPS SETTINGS", "Opens Windows Startup Apps so you can disable unnecessary apps.", "", "ALL", "Open-GuiStartupAppsSettings");
        AddCard("\uE72C", "RESTART EXPLORER", "Restarts Windows Explorer to apply shell/UI changes.", "", "ALL", "Restart-GuiExplorer");
    }

    private void LoadBackup()
    {
        SetPage("nav_backup", "BACKUP / RESTORE", "Create backups before applying bigger changes.", BtnBackup);

        AddCard("\uE777", "CREATE BACKUP NOW", "Creates restore point attempt and exports key settings.", "", "ALL", "New-SlxdeBackup");
        AddCard("\uE72C", "RESTORE LATEST BACKUP", "Restores the latest exported backup.", "Use carefully", "ALL", "Restore-GuiLatestBackup");
        AddCard("\uE838", "OPEN BACKUP FOLDER", "Opens the backup folder.", "", "ALL", "Open-GuiBackupFolder");
    }

    private void OpenAmdSettingsGuide()
    {
        var guideFolder = Path.Combine(AppContext.BaseDirectory, "Assets", "Guides", "AMD");

        var captions = new List<string>
        {
            "Advanced graphics options: filtering, tessellation and shader cache.",
            "Performance → Tuning: overview and tuning controls.",
            "Performance tuning page: review GPU/VRAM/power settings carefully."
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
