using System;
using System.Runtime.InteropServices;

namespace SlxdeOptimizer.App.Services;

public static class DisplayRefreshRateService
{
    private const int EnumCurrentSettings = -1;
    private const int DmDisplayFrequency = 0x00400000;
    private const int CdsUpdateRegistry = 0x00000001;
    private const int CdsTest = 0x00000002;
    private const int DispChangeSuccessful = 0;

    public static RefreshRateResult ApplyMaximumForPrimaryDisplay()
    {
        var current = CreateDevMode();
        if (!EnumDisplaySettings(null, EnumCurrentSettings, ref current))
        {
            return RefreshRateResult.Failed("Windows could not read the current primary-display mode.");
        }

        var best = current;
        var highestFrequency = NormaliseFrequency(current.dmDisplayFrequency);

        for (var modeIndex = 0; ; modeIndex++)
        {
            var candidate = CreateDevMode();
            if (!EnumDisplaySettings(null, modeIndex, ref candidate))
            {
                break;
            }

            var candidateFrequency = NormaliseFrequency(candidate.dmDisplayFrequency);
            var matchesCurrentMode =
                candidate.dmPelsWidth == current.dmPelsWidth &&
                candidate.dmPelsHeight == current.dmPelsHeight &&
                candidate.dmBitsPerPel == current.dmBitsPerPel &&
                candidate.dmDisplayFlags == current.dmDisplayFlags;

            if (matchesCurrentMode && candidateFrequency > highestFrequency)
            {
                highestFrequency = candidateFrequency;
                best = candidate;
            }
        }

        var currentFrequency = NormaliseFrequency(current.dmDisplayFrequency);
        if (highestFrequency <= currentFrequency)
        {
            return RefreshRateResult.AlreadyMaximum(currentFrequency, current.dmPelsWidth, current.dmPelsHeight);
        }

        // Change only the refresh rate. Resolution, colour depth, orientation and layout stay untouched.
        best.dmFields = DmDisplayFrequency;
        best.dmDisplayFrequency = highestFrequency;

        var testResult = ChangeDisplaySettings(ref best, CdsTest);
        if (testResult != DispChangeSuccessful)
        {
            return RefreshRateResult.Failed($"The display driver rejected {highestFrequency} Hz (code {testResult}). No settings were changed.");
        }

        var applyResult = ChangeDisplaySettings(ref best, CdsUpdateRegistry);
        if (applyResult != DispChangeSuccessful)
        {
            return RefreshRateResult.Failed($"Windows could not apply {highestFrequency} Hz (code {applyResult}).");
        }

        var verified = CreateDevMode();
        if (!EnumDisplaySettings(null, EnumCurrentSettings, ref verified))
        {
            return RefreshRateResult.Applied(currentFrequency, highestFrequency, current.dmPelsWidth, current.dmPelsHeight);
        }

        var verifiedFrequency = NormaliseFrequency(verified.dmDisplayFrequency);
        if (verifiedFrequency < highestFrequency)
        {
            return RefreshRateResult.Failed($"Windows reported {verifiedFrequency} Hz after applying {highestFrequency} Hz. Check Advanced display settings.");
        }

        return RefreshRateResult.Applied(currentFrequency, verifiedFrequency, current.dmPelsWidth, current.dmPelsHeight);
    }

    private static int NormaliseFrequency(int frequency) => frequency <= 1 ? 0 : frequency;

    private static DevMode CreateDevMode()
    {
        return new DevMode
        {
            dmDeviceName = string.Empty,
            dmFormName = string.Empty,
            dmSize = (short)Marshal.SizeOf<DevMode>()
        };
    }

    [DllImport("user32.dll", CharSet = CharSet.Unicode, EntryPoint = "EnumDisplaySettingsW")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool EnumDisplaySettings(string? deviceName, int modeNum, ref DevMode devMode);

    [DllImport("user32.dll", CharSet = CharSet.Unicode, EntryPoint = "ChangeDisplaySettingsW")]
    private static extern int ChangeDisplaySettings(ref DevMode devMode, int flags);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct DevMode
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }
}

public sealed record RefreshRateResult(bool Success, bool Changed, int PreviousHz, int CurrentHz, int Width, int Height, string Error)
{
    public static RefreshRateResult Applied(int previousHz, int currentHz, int width, int height) =>
        new(true, true, previousHz, currentHz, width, height, string.Empty);

    public static RefreshRateResult AlreadyMaximum(int currentHz, int width, int height) =>
        new(true, false, currentHz, currentHz, width, height, string.Empty);

    public static RefreshRateResult Failed(string error) =>
        new(false, false, 0, 0, 0, 0, error);
}
