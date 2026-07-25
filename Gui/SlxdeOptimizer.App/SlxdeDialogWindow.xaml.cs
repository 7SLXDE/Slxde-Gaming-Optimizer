using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;

namespace SlxdeOptimizer.App;

public partial class SlxdeDialogWindow : Window
{
    private readonly MessageBoxButton _buttons;

    public MessageBoxResult SelectedResult { get; private set; } = MessageBoxResult.None;

    public SlxdeDialogWindow(string message, string title, MessageBoxButton buttons, MessageBoxImage image)
    {
        InitializeComponent();
        _buttons = buttons;
        WindowTitleText.Text = string.IsNullOrWhiteSpace(title) ? "SLXDE OPTI" : title;
        MessageText.Text = message;
        Width = message.Length switch
        {
            <= 160 => 460,
            <= 500 => 540,
            _ => 640
        };
        ConfigureIcon(image);
        AddButtons(buttons);
    }

    private void ConfigureIcon(MessageBoxImage image)
    {
        var blue = Color.FromRgb(44, 143, 255);
        var softBlue = Color.FromRgb(149, 190, 229);
        var red = Color.FromRgb(232, 103, 117);

        IconText.Visibility = Visibility.Visible;
        SuccessTick.Visibility = Visibility.Collapsed;

        switch (image)
        {
            case MessageBoxImage.Error:
                IconText.Text = "!";
                IconShell.BorderBrush = new SolidColorBrush(red);
                IconText.Foreground = new SolidColorBrush(Color.FromRgb(255, 205, 211));
                break;
            case MessageBoxImage.Warning:
                IconText.Text = "!";
                IconShell.BorderBrush = new SolidColorBrush(softBlue);
                IconText.Foreground = new SolidColorBrush(Color.FromRgb(220, 233, 247));
                break;
            case MessageBoxImage.Question:
                IconText.Text = "?";
                IconShell.BorderBrush = new SolidColorBrush(blue);
                break;
            default:
                IconText.Visibility = Visibility.Collapsed;
                SuccessTick.Visibility = Visibility.Visible;
                IconShell.BorderBrush = new SolidColorBrush(blue);
                break;
        }
    }

    private void AddButtons(MessageBoxButton buttons)
    {
        switch (buttons)
        {
            case MessageBoxButton.OKCancel:
                AddButton("CANCEL", MessageBoxResult.Cancel, false);
                AddButton("OK  >", MessageBoxResult.OK, true);
                break;
            case MessageBoxButton.YesNo:
                AddButton("NO", MessageBoxResult.No, false);
                AddButton("YES  >", MessageBoxResult.Yes, true);
                break;
            case MessageBoxButton.YesNoCancel:
                AddButton("CANCEL", MessageBoxResult.Cancel, false);
                AddButton("NO", MessageBoxResult.No, false);
                AddButton("YES  >", MessageBoxResult.Yes, true);
                break;
            default:
                AddButton("DONE  >", MessageBoxResult.OK, true);
                break;
        }
    }

    private void AddButton(string label, MessageBoxResult result, bool primary)
    {
        var button = new Button
        {
            Content = label,
            MinWidth = primary ? 128 : 96,
            Padding = new Thickness(18, 10, 18, 10),
            Margin = new Thickness(10, 0, 0, 0),
            Foreground = Brushes.White,
            Background = new SolidColorBrush(primary ? Color.FromRgb(37, 137, 237) : Color.FromRgb(17, 28, 43)),
            BorderBrush = new SolidColorBrush(primary ? Color.FromRgb(53, 161, 255) : Color.FromRgb(32, 49, 71)),
            BorderThickness = new Thickness(1),
            FontWeight = FontWeights.SemiBold,
            Cursor = Cursors.Hand,
            IsDefault = primary,
            IsCancel = result == MessageBoxResult.Cancel || (result == MessageBoxResult.No && _buttons == MessageBoxButton.YesNo)
        };

        button.Click += (_, _) =>
        {
            SelectedResult = result;
            Close();
        };
        ButtonsHost.Children.Add(button);
    }

    private void Header_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ButtonState == MouseButtonState.Pressed)
        {
            DragMove();
        }
    }

    private void Close_Click(object sender, RoutedEventArgs e)
    {
        if (SelectedResult == MessageBoxResult.None)
        {
            SelectedResult = _buttons switch
            {
                MessageBoxButton.OK => MessageBoxResult.OK,
                MessageBoxButton.OKCancel => MessageBoxResult.Cancel,
                MessageBoxButton.YesNo => MessageBoxResult.No,
                MessageBoxButton.YesNoCancel => MessageBoxResult.Cancel,
                _ => MessageBoxResult.None
            };
        }

        Close();
    }
}

public static class SlxdeDialog
{
    public static MessageBoxResult Show(
        Window? owner,
        string message,
        string title = "SLXDE OPTI",
        MessageBoxButton buttons = MessageBoxButton.OK,
        MessageBoxImage image = MessageBoxImage.Information)
    {
        var dialog = new SlxdeDialogWindow(message, title, buttons, image);
        if (owner != null && owner.IsLoaded)
        {
            dialog.Owner = owner;
        }
        else
        {
            dialog.WindowStartupLocation = WindowStartupLocation.CenterScreen;
        }

        dialog.ShowDialog();
        return dialog.SelectedResult;
    }
}
