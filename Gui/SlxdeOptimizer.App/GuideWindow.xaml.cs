using System;
using System.Collections.Generic;
using System.IO;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media.Imaging;

namespace SlxdeOptimizer.App;

public partial class GuideWindow : Window
{
    private readonly List<string> _images = new();
    private readonly List<string> _captions;
    private int _index;

    public GuideWindow(string title, string guideFolder, List<string>? captions = null)
    {
        InitializeComponent();
        Title = title;
        _captions = captions ?? new List<string>();

        MaxWidth = Math.Max(MinWidth, SystemParameters.WorkArea.Width - 48);
        MaxHeight = Math.Max(MinHeight, SystemParameters.WorkArea.Height - 48);
        Width = Math.Min(Width, MaxWidth);
        Height = Math.Min(Height, MaxHeight);

        if (Directory.Exists(guideFolder))
        {
            var preferredOrder = new[]
            {
                "amd_driver_settings_1.png",
                "amd_driver_settings_2.png",
                "amd_driver_settings_3.png",
                "amd_driver_settings_4.png"
            };

            foreach (var fileName in preferredOrder)
            {
                var path = Path.Combine(guideFolder, fileName);
                if (File.Exists(path))
                {
                    _images.Add(path);
                }
            }
        }

        ShowImage(0);
    }

    private void ShowImage(int index)
    {
        if (_images.Count == 0)
        {
            StepText.Text = "No images found";
            CaptionText.Text = "Guide folder missing or empty";
            return;
        }

        if (index < 0) index = _images.Count - 1;
        if (index >= _images.Count) index = 0;
        _index = index;

        var bitmap = new BitmapImage();
        bitmap.BeginInit();
        bitmap.CacheOption = BitmapCacheOption.OnLoad;
        bitmap.UriSource = new Uri(_images[_index], UriKind.Absolute);
        bitmap.EndInit();

        GuideImage.Source = bitmap;
        StepText.Text = $"Step {_index + 1} / {_images.Count}";
        CaptionText.Text = _index < _captions.Count ? _captions[_index] : Path.GetFileName(_images[_index]);
    }

    private void Previous_Click(object sender, RoutedEventArgs e) => ShowImage(_index - 1);
    private void Next_Click(object sender, RoutedEventArgs e) => ShowImage(_index + 1);
    private void Close_Click(object sender, RoutedEventArgs e) => Close();

    private void Header_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ButtonState == MouseButtonState.Pressed)
        {
            DragMove();
        }
    }
}
