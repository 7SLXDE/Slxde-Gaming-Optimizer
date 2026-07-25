using System;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace SlxdeOptimizer.App.Services;

public sealed record SlxdeUpdate(
    Version Version,
    string DisplayVersion,
    string DownloadUrl,
    string? ChecksumUrl,
    string? Sha256,
    long ExpectedSize,
    string ReleaseNotes);

public static partial class UpdateService
{
    private const string LatestReleaseUrl =
        "https://api.github.com/repos/7SLXDE/Slxde-Gaming-Optimizer/releases/latest";
    private const string InstallerAssetName = "SLXDE-OPTI-Setup.exe";
    private const string ChecksumAssetName = InstallerAssetName + ".sha256";

    private static readonly HttpClient Client = CreateClient();

    public static async Task<SlxdeUpdate?> CheckForUpdateAsync(CancellationToken cancellationToken = default)
    {
        using var response = await Client.GetAsync(LatestReleaseUrl, cancellationToken);
        response.EnsureSuccessStatusCode();

        await using var responseStream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var document = await JsonDocument.ParseAsync(responseStream, cancellationToken: cancellationToken);
        var root = document.RootElement;

        var tag = root.GetProperty("tag_name").GetString()
            ?? throw new InvalidOperationException("The latest release has no version tag.");
        var versionText = tag.Trim().TrimStart('v', 'V').Split('-', 2)[0];
        if (!Version.TryParse(versionText, out var latestVersion))
        {
            throw new InvalidOperationException($"The release version '{tag}' is not valid.");
        }

        var currentVersion = Assembly.GetExecutingAssembly().GetName().Version ?? new Version(0, 0, 0);
        if (latestVersion <= currentVersion)
        {
            return null;
        }

        string? downloadUrl = null;
        string? checksumUrl = null;
        string? sha256 = null;
        long expectedSize = 0;

        foreach (var asset in root.GetProperty("assets").EnumerateArray())
        {
            var assetName = asset.GetProperty("name").GetString();
            var assetUrl = asset.GetProperty("browser_download_url").GetString();

            if (string.Equals(assetName, InstallerAssetName, StringComparison.OrdinalIgnoreCase))
            {
                downloadUrl = assetUrl;
                expectedSize = asset.TryGetProperty("size", out var sizeProperty)
                    ? sizeProperty.GetInt64()
                    : 0;

                var digest = asset.TryGetProperty("digest", out var digestProperty)
                    ? digestProperty.GetString()
                    : null;
                sha256 = digest?.StartsWith("sha256:", StringComparison.OrdinalIgnoreCase) == true
                    ? digest[7..]
                    : null;
            }
            else if (string.Equals(assetName, ChecksumAssetName, StringComparison.OrdinalIgnoreCase))
            {
                checksumUrl = assetUrl;
            }
        }

        if (string.IsNullOrWhiteSpace(downloadUrl))
        {
            throw new InvalidOperationException($"The release does not contain {InstallerAssetName}.");
        }

        ValidateGitHubDownloadUrl(downloadUrl);
        if (!string.IsNullOrWhiteSpace(checksumUrl))
        {
            ValidateGitHubDownloadUrl(checksumUrl);
        }

        var releaseNotes = root.TryGetProperty("body", out var bodyProperty)
            ? bodyProperty.GetString() ?? string.Empty
            : string.Empty;

        return new SlxdeUpdate(
            latestVersion,
            tag.TrimStart('v', 'V'),
            downloadUrl,
            checksumUrl,
            NormaliseSha256(sha256),
            expectedSize,
            releaseNotes.Trim());
    }

    public static async Task<string> DownloadInstallerAsync(
        SlxdeUpdate update,
        IProgress<int>? progress = null,
        CancellationToken cancellationToken = default)
    {
        var updateDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "SLXDE OPTI",
            "Updates",
            update.DisplayVersion);
        Directory.CreateDirectory(updateDirectory);

        var finalPath = Path.Combine(updateDirectory, InstallerAssetName);
        var partialPath = finalPath + ".download";

        try
        {
            using (var response = await Client.GetAsync(
                       update.DownloadUrl,
                       HttpCompletionOption.ResponseHeadersRead,
                       cancellationToken))
            {
                response.EnsureSuccessStatusCode();
                var totalBytes = update.ExpectedSize > 0
                    ? update.ExpectedSize
                    : response.Content.Headers.ContentLength ?? 0;

                await using var source = await response.Content.ReadAsStreamAsync(cancellationToken);
                await using var destination = new FileStream(
                    partialPath,
                    FileMode.Create,
                    FileAccess.Write,
                    FileShare.None,
                    81920,
                    FileOptions.Asynchronous | FileOptions.SequentialScan);

                var buffer = new byte[81920];
                long downloadedBytes = 0;
                int bytesRead;
                while ((bytesRead = await source.ReadAsync(buffer, cancellationToken)) > 0)
                {
                    await destination.WriteAsync(buffer.AsMemory(0, bytesRead), cancellationToken);
                    downloadedBytes += bytesRead;
                    if (totalBytes > 0)
                    {
                        progress?.Report((int)Math.Clamp(downloadedBytes * 100L / totalBytes, 0, 100));
                    }
                }
            }

            var downloadedSize = new FileInfo(partialPath).Length;
            if (update.ExpectedSize > 0 && downloadedSize != update.ExpectedSize)
            {
                throw new InvalidOperationException("The downloaded installer is incomplete.");
            }

            var expectedSha256 = update.Sha256;
            if (string.IsNullOrWhiteSpace(expectedSha256) && !string.IsNullOrWhiteSpace(update.ChecksumUrl))
            {
                expectedSha256 = await DownloadChecksumAsync(update.ChecksumUrl, cancellationToken);
            }

            if (string.IsNullOrWhiteSpace(expectedSha256))
            {
                throw new InvalidOperationException(
                    $"The release is missing {ChecksumAssetName}, so the update was not installed.");
            }

            await using (var installerStream = File.OpenRead(partialPath))
            {
                var hash = await SHA256.HashDataAsync(installerStream, cancellationToken);
                var actualDigest = Convert.ToHexString(hash);
                if (!actualDigest.Equals(expectedSha256, StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException("The downloaded installer failed its security check.");
                }
            }

            File.Move(partialPath, finalPath, overwrite: true);
            progress?.Report(100);
            return finalPath;
        }
        catch
        {
            File.Delete(partialPath);
            throw;
        }
    }

    public static void LaunchInstallerAndRestart(string installerPath)
    {
        if (!File.Exists(installerPath))
        {
            throw new FileNotFoundException("The downloaded installer could not be found.", installerPath);
        }

        var appPath = Environment.ProcessPath
            ?? throw new InvalidOperationException("SLXDE OPTI could not locate its installed application file.");
        var launcherPath = Path.Combine(
            Path.GetDirectoryName(installerPath) ?? Path.GetTempPath(),
            "Install-SLXDE-Update.cmd");

        var script = $"""
            @echo off
            setlocal
            ping 127.0.0.1 -n 3 >nul
            start /wait "" "{installerPath}" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /CLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /SP-
            if errorlevel 1 exit /b %errorlevel%
            start "" "{appPath}" /updated
            del "%~f0"
            """;
        File.WriteAllText(launcherPath, script, new UTF8Encoding(false));

        Process.Start(new ProcessStartInfo
        {
            FileName = "cmd.exe",
            Arguments = $"/d /s /c \"\"{launcherPath}\"\"",
            UseShellExecute = true,
            CreateNoWindow = true,
            WindowStyle = ProcessWindowStyle.Hidden
        });
    }

    private static async Task<string> DownloadChecksumAsync(
        string checksumUrl,
        CancellationToken cancellationToken)
    {
        var checksumText = await Client.GetStringAsync(checksumUrl, cancellationToken);
        var match = Sha256Regex().Match(checksumText);
        if (!match.Success)
        {
            throw new InvalidOperationException($"The {ChecksumAssetName} file is not valid.");
        }

        return match.Value.ToUpperInvariant();
    }

    private static string? NormaliseSha256(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var trimmed = value.Trim();
        return Sha256Regex().IsMatch(trimmed) ? trimmed.ToUpperInvariant() : null;
    }

    private static void ValidateGitHubDownloadUrl(string value)
    {
        if (!Uri.TryCreate(value, UriKind.Absolute, out var uri) ||
            uri.Scheme != Uri.UriSchemeHttps ||
            !uri.Host.Equals("github.com", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("The release contains an invalid download address.");
        }
    }

    private static HttpClient CreateClient()
    {
        var client = new HttpClient { Timeout = TimeSpan.FromMinutes(10) };
        var productVersion = Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "0.0.0";
        client.DefaultRequestHeaders.UserAgent.Add(new ProductInfoHeaderValue("SLXDE-OPTI", productVersion));
        client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.github+json"));
        client.DefaultRequestHeaders.Add("X-GitHub-Api-Version", "2022-11-28");
        return client;
    }

    [GeneratedRegex(@"(?i)\b[a-f0-9]{64}\b", RegexOptions.CultureInvariant)]
    private static partial Regex Sha256Regex();
}
