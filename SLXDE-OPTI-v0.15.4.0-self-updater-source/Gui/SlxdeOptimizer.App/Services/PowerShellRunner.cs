using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;

namespace SlxdeOptimizer.App.Services;

public sealed class PowerShellRunner
{
    private readonly string _repoRoot;

    public PowerShellRunner()
    {
        _repoRoot = FindRepoRoot();
    }

    public string RepoRoot => _repoRoot;

    public Task<string> RunFunctionAsync(string moduleName, string functionName)
    {
        return Task.Run(() =>
        {
            string? tempScript = null;

            try
            {
                string modulesDir = Path.Combine(_repoRoot, "Modules");

                if (!Directory.Exists(modulesDir))
                {
                    return $"Modules folder not found: {modulesDir}";
                }

                tempScript = Path.Combine(Path.GetTempPath(), $"SlxdeGuiRun_{Guid.NewGuid():N}.ps1");

                string script =
$@"
$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy -Scope Process Bypass -Force

$repoRoot = @'
{_repoRoot}
'@

$moduleDir = Join-Path -Path $repoRoot -ChildPath 'Modules'

Set-Location -LiteralPath $repoRoot

Get-ChildItem -LiteralPath $moduleDir -Filter '*.ps1' | Sort-Object Name | ForEach-Object {{
    . $_.FullName
}}

if (-not (Get-Command '{functionName}' -ErrorAction SilentlyContinue)) {{
    Write-Output 'Function not found: {functionName}'
    exit 0
}}

$result = {functionName}

if ($null -ne $result) {{
    Write-Output $result
}} else {{
    Write-Output 'Done'
}}
";

                File.WriteAllText(tempScript, script);

                var info = new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{tempScript}\"",
                    WorkingDirectory = _repoRoot,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };

                using var process = Process.Start(info);
                if (process == null)
                {
                    return "Failed to start PowerShell.";
                }

                bool exited = process.WaitForExit(60000);

                if (!exited)
                {
                    try { process.Kill(true); } catch { }
                    return "Timed out after 60 seconds. The action may not be supported on this system or may need to be run manually.";
                }

                string output = process.StandardOutput.ReadToEnd();
                string error = process.StandardError.ReadToEnd();

                if (!string.IsNullOrWhiteSpace(error))
                {
                    return error.Trim();
                }

                return string.IsNullOrWhiteSpace(output) ? "Done" : output.Trim();
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
            finally
            {
                try
                {
                    if (!string.IsNullOrWhiteSpace(tempScript) && File.Exists(tempScript))
                    {
                        File.Delete(tempScript);
                    }
                }
                catch
                {
                    // ignore cleanup failures
                }
            }
        });
    }

    private static string FindRepoRoot()
    {
        // The app can be launched from:
        // 1. bin\Debug\net8.0-windows while developing.
        // 2. bin\Release\...\publish after publishing.
        // 3. an extracted release zip on another PC.
        //
        // v 0.9.65 copies Modules into the output/publish folder, so check the executable
        // folder first, then walk parent folders for source-tree runs.

        var candidates = new List<string>();

        void AddCandidate(string? path)
        {
            if (!string.IsNullOrWhiteSpace(path))
            {
                try
                {
                    candidates.Add(Path.GetFullPath(path));
                }
                catch
                {
                    // ignore bad path
                }
            }
        }

        AddCandidate(AppContext.BaseDirectory);
        AddCandidate(Environment.CurrentDirectory);

        foreach (var start in candidates.ToArray())
        {
            var dir = new DirectoryInfo(start);

            while (dir != null)
            {
                if (Directory.Exists(Path.Combine(dir.FullName, "Modules")))
                {
                    return dir.FullName;
                }

                dir = dir.Parent;
            }
        }

        // Common source-tree location for the user's project.
        var docs = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
        AddCandidate(Path.Combine(docs, "Slxde's Gaming Opti"));
        AddCandidate(Path.Combine(docs, "Slxde's Gaming Opti", "Gui", "SlxdeOptimizer.App"));

        foreach (var candidate in candidates)
        {
            if (Directory.Exists(Path.Combine(candidate, "Modules")))
            {
                return candidate;
            }
        }

        // Final safe fallback: use the executable directory.
        // Do NOT return C:\ because that causes the bad C:\Modules error.
        return AppContext.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
    }
}
