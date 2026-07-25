using SlxdeOptimizer.App.Services;
using System.Collections.Generic;
using System.IO;
using System.Windows;
using System.Windows.Input;

namespace SlxdeOptimizer.App;

public partial class GamePickerWindow : Window
{
    public string? SelectedExecutablePath { get; private set; }
    public bool RestoreDefaultRequested { get; private set; }

    public GamePickerWindow()
    {
        InitializeComponent();
    }

    public void SetGames(IReadOnlyList<GameExecutableCandidate> games)
    {
        if (games.Count == 0)
        {
            EmptyText.Text = "No games were detected. Launch the game and try again, or use Browse manually.";
            GamesList.Visibility = Visibility.Collapsed;
            return;
        }

        GamesList.ItemsSource = games;
        GamesList.SelectedIndex = 0;
        GamesList.Visibility = Visibility.Visible;
        EmptyText.Visibility = Visibility.Collapsed;
    }

    private void UseSelected_Click(object sender, RoutedEventArgs e)
    {
        if (GamesList.SelectedItem is not GameExecutableCandidate selected)
        {
            SlxdeDialog.Show(this, "Choose a game first.", "Choose Game", MessageBoxButton.OK, MessageBoxImage.Information);
            return;
        }

        SelectedExecutablePath = selected.ExecutablePath;
        DialogResult = true;
    }

    private void GamesList_MouseDoubleClick(object sender, MouseButtonEventArgs e) => UseSelected_Click(sender, e);

    private void RestoreDefault_Click(object sender, RoutedEventArgs e)
    {
        if (GamesList.SelectedItem is not GameExecutableCandidate selected)
        {
            SlxdeDialog.Show(this, "Choose a detected game first.", "Restore GPU Preference", MessageBoxButton.OK, MessageBoxImage.Information);
            return;
        }

        SelectedExecutablePath = selected.ExecutablePath;
        RestoreDefaultRequested = true;
        DialogResult = true;
    }

    private void Browse_Click(object sender, RoutedEventArgs e)
    {
        var picker = new Microsoft.Win32.OpenFileDialog
        {
            Title = "Choose a game executable",
            Filter = "Game executable (*.exe)|*.exe",
            CheckFileExists = true,
            Multiselect = false
        };

        if (picker.ShowDialog(this) == true && File.Exists(picker.FileName))
        {
            SelectedExecutablePath = picker.FileName;
            DialogResult = true;
        }
    }

    private void Cancel_Click(object sender, RoutedEventArgs e) => DialogResult = false;

    private void Header_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ButtonState == MouseButtonState.Pressed)
        {
            DragMove();
        }
    }
}
