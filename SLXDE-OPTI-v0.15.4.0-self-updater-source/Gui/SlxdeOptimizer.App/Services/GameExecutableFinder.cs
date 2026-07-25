using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace SlxdeOptimizer.App.Services;

public sealed record GameExecutableCandidate(string DisplayName, string ExecutablePath, string Source)
{
    public string Detail => $"{Source}  ·  {ExecutablePath}";
}

public static class GameExecutableFinder
{
    private static readonly HashSet<string> IgnoredExecutables = new(StringComparer.OrdinalIgnoreCase)
    {
        "steam.exe", "steamwebhelper.exe", "epicgameslauncher.exe", "battle.net.exe",
        "agent.exe", "eadesktop.exe", "ealauncher.exe", "ubisoftconnect.exe",
        "upc.exe", "riotclientservices.exe", "explorer.exe", "powershell.exe",
        "cmd.exe", "conhost.exe", "slxdeoptimizer.app.exe", "crashreporter.exe",
        "crashreportclient.exe", "unins000.exe", "uninstall.exe", "chrome.exe",
        "msedge.exe", "firefox.exe", "discord.exe", "spotify.exe", "code.exe",
        "devenv.exe", "notepad.exe", "taskmgr.exe", "obs64.exe",
        "battle.net.overlay.runtime.exe", "radeonsoftware.exe", "start_protected_game.exe",
        "easyanticheat.exe", "easyanticheat_eos.exe", "beservice.exe", "beservices.exe",
        "vgc.exe", "vgtray.exe", "riotclientux.exe", "riotclientuxrender.exe",
        "eaclauncher.exe", "gamelaunchhelper.exe", "gamingservices.exe",
        "gamingservicesnet.exe", "gamebar.exe", "gamebarftserver.exe"
    };

    private static readonly string[] IgnoredPathParts =
    {
        "\\_CommonRedist\\", "\\Redist\\", "\\Redistributable\\", "\\Installer\\",
        "\\EasyAntiCheat\\", "\\BattlEye\\", "\\CrashReportClient\\", "\\ThirdParty\\",
        "\\AMD\\CNext\\", "\\Battle.net\\", "\\Launcher\\", "\\Launchers\\",
        "\\Support\\", "\\Prerequisites\\", "\\Engine\\Extras\\"
    };

    private static readonly string[] IgnoredNameParts =
    {
        "launcher", "bootstrap", "updater", "update", "installer", "setup", "uninstall",
        "crash", "reporter", "telemetry", "overlay", "helper", "webview", "service",
        "anticheat", "easyanticheat", "battleye", "prerequisite", "redistributable"
    };

    public static Task<IReadOnlyList<GameExecutableCandidate>> FindAsync()
    {
        return Task.Run<IReadOnlyList<GameExecutableCandidate>>(() =>
        {
            var found = new Dictionary<string, GameExecutableCandidate>(StringComparer.OrdinalIgnoreCase);
            AddRunningGames(found);
            AddSteamGames(found);
            AddEpicGames(found);
            AddKnownPublisherGames(found);

            return found.Values
                .GroupBy(candidate => NormaliseGameIdentity(candidate.DisplayName), StringComparer.OrdinalIgnoreCase)
                .Select(group => group
                    .OrderByDescending(candidate => SourcePriority(candidate.Source))
                    .ThenByDescending(candidate => ScoreExecutable(
                        candidate.ExecutablePath,
                        Regex.Replace(candidate.DisplayName, "[^A-Za-z0-9]", string.Empty)))
                    .First())
                .OrderBy(candidate => candidate.DisplayName, StringComparer.CurrentCultureIgnoreCase)
                .ToList();
        });
    }

    private static void AddRunningGames(IDictionary<string, GameExecutableCandidate> found)
    {
        foreach (var process in Process.GetProcesses())
        {
            try
            {
                if (process.MainWindowHandle == IntPtr.Zero || string.IsNullOrWhiteSpace(process.MainWindowTitle))
                {
                    continue;
                }

                var path = process.MainModule?.FileName;
                if (!IsUsableExecutable(path) || IsWindowsPath(path!) || IsHelperExecutable(path!))
                {
                    continue;
                }

                var name = FriendlyNameFromPath(path!);
                if (string.IsNullOrWhiteSpace(name)) name = process.MainWindowTitle.Trim();

                Add(found, new GameExecutableCandidate(name!, path!, "Running now"));
            }
            catch
            {
                // Protected and system processes are expected to reject MainModule access.
            }
            finally
            {
                process.Dispose();
            }
        }
    }

    private static void AddSteamGames(IDictionary<string, GameExecutableCandidate> found)
    {
        foreach (var steamApps in FindSteamAppsFolders())
        {
            if (!Directory.Exists(steamApps))
            {
                continue;
            }

            IEnumerable<string> manifests;
            try { manifests = Directory.EnumerateFiles(steamApps, "appmanifest_*.acf", SearchOption.TopDirectoryOnly); }
            catch { continue; }

            foreach (var manifest in manifests)
            {
                try
                {
                    var text = File.ReadAllText(manifest);
                    var name = ReadAcfValue(text, "name");
                    var installDir = ReadAcfValue(text, "installdir");
                    if (string.IsNullOrWhiteSpace(name) || string.IsNullOrWhiteSpace(installDir))
                    {
                        continue;
                    }

                    var gameFolder = Path.Combine(steamApps, "common", installDir);
                    var executable = FindBestExecutable(gameFolder, name);
                    if (executable != null)
                    {
                        Add(found, new GameExecutableCandidate(name, executable, "Steam"));
                    }
                }
                catch
                {
                    // Ignore malformed or inaccessible manifests.
                }
            }
        }
    }

    private static IEnumerable<string> FindSteamAppsFolders()
    {
        var folders = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var steamRoots = new[]
        {
            Registry.GetValue(@"HKEY_CURRENT_USER\Software\Valve\Steam", "SteamPath", null) as string,
            Registry.GetValue(@"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam", "InstallPath", null) as string,
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "Steam")
        };

        foreach (var root in steamRoots.Where(root => !string.IsNullOrWhiteSpace(root)))
        {
            try
            {
                var steamApps = Path.Combine(root!, "steamapps");
                if (Directory.Exists(steamApps))
                {
                    folders.Add(steamApps);
                }

                var libraryFile = Path.Combine(steamApps, "libraryfolders.vdf");
                if (!File.Exists(libraryFile))
                {
                    continue;
                }

                var text = File.ReadAllText(libraryFile);
                foreach (Match match in Regex.Matches(text, "\\\"path\\\"\\s+\\\"(?<path>[^\\\"]+)\\\"", RegexOptions.IgnoreCase))
                {
                    var libraryRoot = match.Groups["path"].Value.Replace("\\\\", "\\");
                    var librarySteamApps = Path.Combine(libraryRoot, "steamapps");
                    if (Directory.Exists(librarySteamApps))
                    {
                        folders.Add(librarySteamApps);
                    }
                }
            }
            catch
            {
                // Continue with any other detected Steam roots.
            }
        }

        return folders;
    }

    private static string ReadAcfValue(string text, string key)
    {
        var match = Regex.Match(text, $"\\\"{Regex.Escape(key)}\\\"\\s+\\\"(?<value>[^\\\"]*)\\\"", RegexOptions.IgnoreCase);
        return match.Success ? match.Groups["value"].Value : string.Empty;
    }

    private static void AddEpicGames(IDictionary<string, GameExecutableCandidate> found)
    {
        var manifestFolder = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData),
            "Epic", "EpicGamesLauncher", "Data", "Manifests");

        if (!Directory.Exists(manifestFolder))
        {
            return;
        }

        IEnumerable<string> manifests;
        try { manifests = Directory.EnumerateFiles(manifestFolder, "*.item", SearchOption.TopDirectoryOnly); }
        catch { return; }

        foreach (var manifest in manifests)
        {
            try
            {
                using var document = JsonDocument.Parse(File.ReadAllText(manifest));
                var root = document.RootElement;
                var name = GetJsonString(root, "DisplayName");
                var installLocation = GetJsonString(root, "InstallLocation");
                var launchExecutable = GetJsonString(root, "LaunchExecutable");
                if (string.IsNullOrWhiteSpace(name) || string.IsNullOrWhiteSpace(installLocation))
                {
                    continue;
                }

                var executable = string.IsNullOrWhiteSpace(launchExecutable)
                    ? null
                    : Path.Combine(installLocation, launchExecutable.Replace('/', Path.DirectorySeparatorChar));

                if (!IsUsableExecutable(executable))
                {
                    executable = FindBestExecutable(installLocation, name);
                }

                if (executable != null)
                {
                    Add(found, new GameExecutableCandidate(name, executable, "Epic Games"));
                }
            }
            catch
            {
                // Ignore malformed or incomplete Epic manifests.
            }
        }
    }

    private static string GetJsonString(JsonElement root, string propertyName) =>
        root.TryGetProperty(propertyName, out var property) && property.ValueKind == JsonValueKind.String
            ? property.GetString() ?? string.Empty
            : string.Empty;

    private static void AddKnownPublisherGames(IDictionary<string, GameExecutableCandidate> found)
    {
        var uninstallRoots = new[]
        {
            (RegistryHive.LocalMachine, RegistryView.Registry64, @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"),
            (RegistryHive.LocalMachine, RegistryView.Registry32, @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"),
            (RegistryHive.CurrentUser, RegistryView.Registry64, @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
        };

        foreach (var (hive, view, path) in uninstallRoots)
        {
            try
            {
                using var baseKey = RegistryKey.OpenBaseKey(hive, view);
                using var uninstall = baseKey.OpenSubKey(path);
                if (uninstall == null) continue;

                foreach (var subKeyName in uninstall.GetSubKeyNames())
                {
                    using var item = uninstall.OpenSubKey(subKeyName);
                    var name = item?.GetValue("DisplayName") as string;
                    var publisher = item?.GetValue("Publisher") as string ?? string.Empty;
                    var installLocation = item?.GetValue("InstallLocation") as string;
                    if (string.IsNullOrWhiteSpace(name) || string.IsNullOrWhiteSpace(installLocation) || !LooksLikeGamePublisher(name, publisher))
                    {
                        continue;
                    }

                    var executable = FindBestExecutable(installLocation, name);
                    if (executable != null)
                    {
                        Add(found, new GameExecutableCandidate(name, executable, "Installed game"));
                    }
                }
            }
            catch
            {
                // Registry views vary across Windows installations.
            }
        }
    }

    private static bool LooksLikeGamePublisher(string name, string publisher)
    {
        var combined = $"{name} {publisher}";
        if (name.Equals("Battle.net", StringComparison.OrdinalIgnoreCase) ||
            name.Contains("Launcher", StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        return new[] { "Activision", "Blizzard", "Call of Duty", "Electronic Arts", "EA ", "Ubisoft", "Riot Games" }
            .Any(marker => combined.Contains(marker, StringComparison.OrdinalIgnoreCase));
    }

    private static string? FindBestExecutable(string folder, string gameName)
    {
        if (!Directory.Exists(folder))
        {
            return null;
        }

        var candidates = new List<string>();
        EnumerateExecutables(folder, 0, 5, candidates);
        var nameToken = Regex.Replace(gameName, "[^A-Za-z0-9]", string.Empty);

        return candidates
            .Where(IsUsableExecutable)
            .Where(path => !IsHelperExecutable(path))
            .Where(path => !IgnoredPathParts.Any(part => path.Contains(part, StringComparison.OrdinalIgnoreCase)))
            .OrderByDescending(path => ScoreExecutable(path, nameToken))
            .FirstOrDefault();
    }

    private static void EnumerateExecutables(string folder, int depth, int maxDepth, ICollection<string> output)
    {
        if (depth > maxDepth || output.Count >= 250)
        {
            return;
        }

        try
        {
            foreach (var executable in Directory.EnumerateFiles(folder, "*.exe", SearchOption.TopDirectoryOnly).Take(100))
            {
                output.Add(executable);
                if (output.Count >= 250) return;
            }

            foreach (var child in Directory.EnumerateDirectories(folder))
            {
                if (IgnoredPathParts.Any(part => (child + "\\").Contains(part, StringComparison.OrdinalIgnoreCase)))
                {
                    continue;
                }

                EnumerateExecutables(child, depth + 1, maxDepth, output);
                if (output.Count >= 250) return;
            }
        }
        catch
        {
            // Skip inaccessible game subfolders.
        }
    }

    private static long ScoreExecutable(string path, string nameToken)
    {
        var fileName = Path.GetFileNameWithoutExtension(path);
        var normalisedFileName = Regex.Replace(fileName, "[^A-Za-z0-9]", string.Empty);
        long score = 0;

        if (!string.IsNullOrWhiteSpace(nameToken) && normalisedFileName.Contains(nameToken, StringComparison.OrdinalIgnoreCase)) score += 5_000_000_000;
        if (path.Contains("\\Binaries\\Win64\\", StringComparison.OrdinalIgnoreCase)) score += 2_000_000_000;
        if (path.Contains("\\x64\\", StringComparison.OrdinalIgnoreCase)) score += 1_000_000_000;
        if (fileName.Contains("launcher", StringComparison.OrdinalIgnoreCase)) score -= 3_000_000_000;
        if (fileName.Contains("crash", StringComparison.OrdinalIgnoreCase)) score -= 3_000_000_000;
        if (fileName.Contains("setup", StringComparison.OrdinalIgnoreCase)) score -= 3_000_000_000;

        try { score += Math.Min(new FileInfo(path).Length, 900_000_000); } catch { }
        return score;
    }

    private static bool IsUsableExecutable(string? path) =>
        !string.IsNullOrWhiteSpace(path) &&
        path.EndsWith(".exe", StringComparison.OrdinalIgnoreCase) &&
        File.Exists(path);

    private static bool IsHelperExecutable(string path)
    {
        var fileName = Path.GetFileName(path);
        if (IgnoredExecutables.Contains(fileName) || IgnoredPathParts.Any(part => path.Contains(part, StringComparison.OrdinalIgnoreCase)))
        {
            return true;
        }

        var stem = Path.GetFileNameWithoutExtension(path);
        return IgnoredNameParts.Any(part => stem.Contains(part, StringComparison.OrdinalIgnoreCase));
    }

    private static bool IsWindowsPath(string path)
    {
        var windows = Environment.GetFolderPath(Environment.SpecialFolder.Windows).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
        return path.StartsWith(windows, StringComparison.OrdinalIgnoreCase);
    }

    private static string FriendlyNameFromPath(string path)
    {
        try
        {
            var description = FileVersionInfo.GetVersionInfo(path).FileDescription;
            return string.IsNullOrWhiteSpace(description) ? Path.GetFileNameWithoutExtension(path) : description;
        }
        catch
        {
            return Path.GetFileNameWithoutExtension(path);
        }
    }

    private static string NormaliseGameIdentity(string name)
    {
        var safeName = name ?? string.Empty;
        var normalised = Regex.Replace(safeName, "[^A-Za-z0-9]", string.Empty);
        return string.IsNullOrWhiteSpace(normalised) ? safeName : normalised;
    }

    private static int SourcePriority(string source) => source switch
    {
        "Running now" => 4,
        "Steam" => 3,
        "Epic Games" => 3,
        "Installed game" => 2,
        _ => 1
    };

    private static void Add(IDictionary<string, GameExecutableCandidate> found, GameExecutableCandidate candidate)
    {
        if (!found.ContainsKey(candidate.ExecutablePath))
        {
            found[candidate.ExecutablePath] = candidate;
        }
    }
}
