using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;

namespace SlxdeOptimizer.App;

public partial class AnalysisWindow : Window
{
    private static readonly string[] SystemKeys =
    {
        "Windows", "Release", "Version", "CPU", "GPU", "RAM", "Motherboard", "BIOS"
    };

    private static readonly string[] SettingKeys =
    {
        "Game Mode", "Game DVR", "Xbox Capture", "HAGS", "Windowed Optimisations",
        "Power Plan", "Ultimate Plan Available", "GPU MSI Mode"
    };

    public AnalysisWindow(string rawResult, IReadOnlyDictionary<string, string> fallbackSystemInfo)
    {
        InitializeComponent();

        var values = ParseValues(rawResult);
        foreach (var pair in fallbackSystemInfo)
        {
            if (!values.TryGetValue(pair.Key, out var existing) || string.IsNullOrWhiteSpace(existing))
            {
                values[pair.Key] = pair.Value;
            }
        }

        var score = ReadScore(values, rawResult);
        ScoreText.Text = score >= 0 ? $"{score} / 100" : "-- / 100";
        SummaryText.Text = score >= 90
            ? "Your main gaming settings are configured well."
            : "Review any settings that are not marked as optimised.";

        foreach (var key in SystemKeys)
        {
            if (values.TryGetValue(key, out var value) && !string.IsNullOrWhiteSpace(value))
            {
                SystemGrid.Children.Add(CreateInfoTile(key, value));
            }
        }

        foreach (var key in SettingKeys)
        {
            var value = values.TryGetValue(key, out var result) ? result : "Not detected";
            SettingsGrid.Children.Add(CreateSettingTile(key, value, IsPreferredState(key, value)));
        }
    }

    private static Dictionary<string, string> ParseValues(string raw)
    {
        var values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var line in raw.Replace("\r", string.Empty).Split('\n'))
        {
            var match = Regex.Match(line, @"^\s*(?<key>[^:]+):\s*(?<value>.+?)\s*$");
            if (!match.Success)
            {
                continue;
            }

            var key = match.Groups["key"].Value.Trim();
            var value = match.Groups["value"].Value.Trim();
            if (!values.ContainsKey(key))
            {
                values[key] = value;
            }
        }

        return values;
    }

    private static int ReadScore(IReadOnlyDictionary<string, string> values, string raw)
    {
        if (values.TryGetValue("Score", out var scoreValue))
        {
            var match = Regex.Match(scoreValue, @"\d+");
            if (match.Success && int.TryParse(match.Value, out var score))
            {
                return Math.Clamp(score, 0, 100);
            }
        }

        var rawMatch = Regex.Match(raw, @"Score\s*:\s*(?<score>\d+)", RegexOptions.IgnoreCase);
        return rawMatch.Success && int.TryParse(rawMatch.Groups["score"].Value, out var rawScore)
            ? Math.Clamp(rawScore, 0, 100)
            : -1;
    }

    private static Border CreateInfoTile(string label, string value)
    {
        var stack = new StackPanel();
        stack.Children.Add(new TextBlock
        {
            Text = label.ToUpperInvariant(),
            Foreground = new SolidColorBrush(Color.FromRgb(126, 159, 194)),
            FontSize = 9,
            FontWeight = FontWeights.SemiBold
        });
        stack.Children.Add(new TextBlock
        {
            Text = value,
            Margin = new Thickness(0, 5, 0, 0),
            Foreground = new SolidColorBrush(Color.FromRgb(220, 233, 247)),
            FontSize = 12,
            FontWeight = FontWeights.SemiBold,
            TextWrapping = TextWrapping.Wrap,
            ToolTip = value
        });

        return new Border
        {
            Background = new SolidColorBrush(Color.FromRgb(15, 23, 36)),
            BorderBrush = new SolidColorBrush(Color.FromRgb(30, 45, 64)),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(14, 11, 14, 11),
            Margin = new Thickness(4),
            MinHeight = 62,
            Child = stack
        };
    }

    private static Border CreateSettingTile(string label, string value, bool preferred)
    {
        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var dot = new Border
        {
            Width = 8,
            Height = 8,
            CornerRadius = new CornerRadius(4),
            Margin = new Thickness(0, 0, 11, 0),
            VerticalAlignment = VerticalAlignment.Center,
            Background = preferred
                ? new SolidColorBrush(Color.FromRgb(72, 211, 166))
                : new SolidColorBrush(Color.FromRgb(125, 160, 197))
        };
        grid.Children.Add(dot);

        var text = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        Grid.SetColumn(text, 1);
        text.Children.Add(new TextBlock
        {
            Text = label,
            Foreground = new SolidColorBrush(Color.FromRgb(220, 233, 247)),
            FontSize = 12,
            FontWeight = FontWeights.SemiBold
        });
        text.Children.Add(new TextBlock
        {
            Text = value,
            Margin = new Thickness(0, 3, 0, 0),
            Foreground = preferred
                ? new SolidColorBrush(Color.FromRgb(130, 205, 183))
                : new SolidColorBrush(Color.FromRgb(145, 171, 199)),
            FontSize = 11,
            TextTrimming = TextTrimming.CharacterEllipsis,
            ToolTip = value
        });
        grid.Children.Add(text);

        return new Border
        {
            Background = new SolidColorBrush(Color.FromRgb(15, 23, 36)),
            BorderBrush = new SolidColorBrush(Color.FromRgb(30, 45, 64)),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(8),
            Padding = new Thickness(14, 11, 14, 11),
            Margin = new Thickness(4),
            MinHeight = 62,
            Child = grid
        };
    }

    private static bool IsPreferredState(string key, string value)
    {
        if (key.Equals("Game DVR", StringComparison.OrdinalIgnoreCase) ||
            key.Equals("Xbox Capture", StringComparison.OrdinalIgnoreCase))
        {
            return value.Contains("Disabled", StringComparison.OrdinalIgnoreCase);
        }

        if (key.Equals("Power Plan", StringComparison.OrdinalIgnoreCase))
        {
            return value.Contains("Optimal", StringComparison.OrdinalIgnoreCase) ||
                   value.Contains("Ultimate", StringComparison.OrdinalIgnoreCase) ||
                   value.Contains("High performance", StringComparison.OrdinalIgnoreCase);
        }

        if (key.Equals("Ultimate Plan Available", StringComparison.OrdinalIgnoreCase))
        {
            return value.Contains("True", StringComparison.OrdinalIgnoreCase) ||
                   value.Contains("Available", StringComparison.OrdinalIgnoreCase);
        }

        return value.Contains("Enabled", StringComparison.OrdinalIgnoreCase);
    }

    private void Header_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ButtonState == MouseButtonState.Pressed)
        {
            DragMove();
        }
    }

    private void Close_Click(object sender, RoutedEventArgs e) => Close();
}
