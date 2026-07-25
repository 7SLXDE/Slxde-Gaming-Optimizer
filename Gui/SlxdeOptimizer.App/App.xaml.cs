using System;
using System.Linq;
using System.Windows;

namespace SlxdeOptimizer.App;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        try
        {
            var window = new MainWindow();
            MainWindow = window;
            window.Show();

            if (e.Args.Any(argument =>
                    argument.Equals("/updated", StringComparison.OrdinalIgnoreCase)))
            {
                window.Dispatcher.BeginInvoke(new Action(() =>
                    SlxdeDialog.Show(
                        window,
                        "SLXDE OPTI was updated successfully.",
                        "Update Complete",
                        MessageBoxButton.OK,
                        MessageBoxImage.Information)));
            }
        }
        catch (Exception ex)
        {
            SlxdeDialog.Show(null,
                ex.ToString(),
                "SLXDE'S OPTI startup error",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
            Shutdown(1);
        }
    }
}
