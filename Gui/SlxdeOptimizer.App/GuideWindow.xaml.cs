using System;
using System.Collections.Generic;
using System.IO;
using System.Windows;
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

        if (Directory.Exists(guideFolder))
        {
            _images.AddRange(Directory.GetFiles(guideFolder, "*.png"));
            _images.Sort(StringComparer.OrdinalIgnoreCase);
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
}
