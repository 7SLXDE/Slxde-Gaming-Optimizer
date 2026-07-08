# =====================================================
# GuiBridge.ps1
# GUI-safe wrapper functions
# These avoid console-only menu functions that pause or ask for typed input.
# =====================================================

function Get-GuiGamingAnalysis {
    try {
        $Info = Get-HardwareInfo
        $GameMode  = Get-GameModeStatus
        $GameDVR   = Get-GameDVRStatus
        $Xbox      = Get-XboxCaptureStatus
        $HAGS      = Get-HAGSStatus
        $WinOpt    = Get-WindowedOptimizationsStatus
        $PowerPlan = Get-PowerPlan
        $Ultimate  = Test-UltimatePerformance
        $MsiStatus = Get-GuiGpuMsiStatusShort
        $Score     = Get-GamingScore $GameMode $GameDVR $Xbox $HAGS $WinOpt $PowerPlan

        Write-Log "GUI analysis completed. Score: $Score/100"

        return @"
Gaming analysis complete.

Score: $Score / 100

Game Mode: $GameMode
Game DVR: $GameDVR
Xbox Capture: $Xbox
HAGS: $HAGS
Windowed Optimizations: $WinOpt
Power Plan: $PowerPlan
Ultimate Plan Available: $Ultimate
GPU MSI Mode: $MsiStatus
"@
    }
    catch {
        Write-Log "GUI analysis failed: $($_.Exception.Message)" "ERROR"
        return "Failed: $($_.Exception.Message)"
    }
}

function Set-GuiSlxdePowerPlan {
    if (!(Assert-Admin)) { return "Failed - run the app as Administrator" }

    try {
        Write-Log "GUI creating/loading SLXDE power plan"

        $ExistingGuid = Get-SlxdePowerPlanGuid

        if ($ExistingGuid) {
            powercfg /setactive $ExistingGuid | Out-Null
            Set-SlxdePowerPlanSettings -Guid $ExistingGuid | Out-Null
            Write-Log "GUI existing SLXDE power plan activated and optimized"
            return "Success - Optimal Power Plan activated and optimized"
        }

        $DuplicateOutput = powercfg -duplicatescheme SCHEME_MIN
        $Guid = $null

        if ($DuplicateOutput -match '([a-fA-F0-9\-]{36})') {
            $Guid = $Matches[1]
        }

        if (!$Guid) {
            Write-Log "GUI could not create SLXDE power plan GUID" "ERROR"
            return "Failed - could not create power plan"
        }

        powercfg -changename $Guid "Optimal Power Plan" "Created by Slxde Gaming Optimizer" | Out-Null
        powercfg /setactive $Guid | Out-Null
        Set-SlxdePowerPlanSettings -Guid $Guid | Out-Null

        Write-Log "GUI SLXDE power plan created, optimized and activated"
        return "Success - Optimal Power Plan created and activated"
    }
    catch {
        Write-Log "GUI failed creating SLXDE power plan: $($_.Exception.Message)" "ERROR"
        return "Failed: $($_.Exception.Message)"
    }
}

function Get-GuiLatestLog {
    try {
        $Candidates = @()

        $RepoRoot = Split-Path -Parent $PSScriptRoot
        $Candidates += Join-Path $RepoRoot "Logs"
        $Candidates += Join-Path $env:ProgramData "Slxde Gaming Optimizer\Logs"
        $Candidates += Join-Path $env:ProgramData "Slxde's Gaming Opti\Logs"

        foreach ($Dir in $Candidates) {
            if (!(Test-Path $Dir)) { continue }

            $Latest = Get-ChildItem -Path $Dir -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -in ".log", ".txt" } |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1

            if ($Latest) {
                $Content = Get-Content $Latest.FullName -Tail 80 -ErrorAction Stop | Out-String
                return "Latest log: $($Latest.Name)`n`n$Content"
            }
        }

        return "No log file found yet. Run a tweak first, then try View Latest Log again."
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}

function Invoke-GuiSystemFileCheck {
    return Invoke-SystemFileCheck
}

function Invoke-GuiWindowsImageRepair {
    return Invoke-WindowsImageRepair
}

function Open-GuiBackupFolder {
    return Open-SlxdeBackupFolder
}

function Restore-GuiLatestBackup {
    return Restore-SlxdeLatestBackup
}


function Invoke-GuiNetworkPack {
    if (!(Assert-Admin)) { return "Failed - run the app as Administrator" }

    try {
        $Messages = New-Object System.Collections.Generic.List[string]

        ipconfig /flushdns | Out-Null
        $Messages.Add("DNS cache flushed")

        $Adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue |
            Where-Object { $_.Status -eq "Up" }

        if (!$Adapters) {
            $Messages.Add("No active physical adapters found")
        }
        else {
            foreach ($Adapter in $Adapters) {
                $Messages.Add("Adapter: $($Adapter.Name)")

                try {
                    $PowerProps = Get-NetAdapterPowerManagement -Name $Adapter.Name -ErrorAction SilentlyContinue
                    if ($PowerProps) {
                        Disable-NetAdapterPowerManagement -Name $Adapter.Name -ErrorAction SilentlyContinue
                        $Messages.Add("  Power saving disabled where supported")
                    }
                }
                catch {
                    $Messages.Add("  Power saving not supported on this adapter")
                }

                $SafeProperties = @(
                    @{ Name = "Energy Efficient Ethernet"; Value = "Disabled" },
                    @{ Name = "Green Ethernet"; Value = "Disabled" },
                    @{ Name = "Power Saving Mode"; Value = "Disabled" },
                    @{ Name = "Ultra Low Power Mode"; Value = "Disabled" },
                    @{ Name = "Wake on Magic Packet"; Value = "Disabled" },
                    @{ Name = "Wake on Pattern Match"; Value = "Disabled" }
                )

                foreach ($Prop in $SafeProperties) {
                    try {
                        $AdvancedProp = Get-NetAdapterAdvancedProperty -Name $Adapter.Name -DisplayName $Prop.Name -ErrorAction SilentlyContinue
                        if ($AdvancedProp) {
                            Set-NetAdapterAdvancedProperty -Name $Adapter.Name -DisplayName $Prop.Name -DisplayValue $Prop.Value -NoRestart -ErrorAction SilentlyContinue
                            $Messages.Add("  $($Prop.Name): $($Prop.Value)")
                        }
                    }
                    catch {
                        # Skip unsupported adapter properties quickly.
                    }
                }
            }
        }

        Write-Log "GUI Network Pack completed"
        return "Network Pack complete.`n`n$($Messages -join "`n")`n`nRestart recommended if adapter settings changed."
    }
    catch {
        Write-Log "GUI Network Pack failed: $($_.Exception.Message)" "ERROR"
        return "Failed: $($_.Exception.Message)"
    }
}

function Reset-GuiNetworkStack {
    if (!(Assert-Admin)) { return "Failed - run the app as Administrator" }

    try {
        ipconfig /flushdns | Out-Null
        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null

        Write-Log "GUI network stack reset"
        return "Success - network stack reset. Restart PC required."
    }
    catch {
        Write-Log "GUI network stack reset failed: $($_.Exception.Message)" "ERROR"
        return "Failed: $($_.Exception.Message)"
    }
}

function Get-GuiActiveAdapterInfo {
    try {
        $Adapter = Get-NetAdapter |
            Where-Object { $_.Status -eq "Up" } |
            Select-Object -First 1

        if (!$Adapter) {
            return "No active network adapter found."
        }

        $IP = Get-NetIPConfiguration -InterfaceIndex $Adapter.ifIndex -ErrorAction SilentlyContinue

        return @"
Active adapter info:

Name: $($Adapter.Name)
Interface: $($Adapter.InterfaceDescription)
Status: $($Adapter.Status)
Link Speed: $($Adapter.LinkSpeed)
MAC Address: $($Adapter.MacAddress)
IPv4: $($IP.IPv4Address.IPAddress)
Gateway: $($IP.IPv4DefaultGateway.NextHop)
DNS: $($IP.DNSServer.ServerAddresses -join ', ')
"@
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}


function Open-GuiAdvancedDisplaySettings {
    try {
        Start-Process "ms-settings:display-advanced"
        Write-Log "GUI opened advanced display settings"
        return "Opened Advanced Display Settings"
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}

function Open-GuiRefreshRateSettings {
    try {
        Start-Process "ms-settings:display-advanced"
        Write-Log "GUI opened refresh rate helper"
        return "Opened Advanced Display Settings. Set your display to the highest available refresh rate."
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}

function Restore-GuiLatestBackup {
    return Restore-SlxdeLatestBackup
}

function Open-GuiBackupFolder {
    return Open-SlxdeBackupFolder
}

function Get-GuiLatestLog {
    try {
        $LogDir = Join-Path $env:ProgramData "Slxde Gaming Optimizer\Logs"

        if (!(Test-Path $LogDir)) {
            return "No log folder found yet."
        }

        $Latest = Get-ChildItem -Path $LogDir -Filter *.log -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if (!$Latest) {
            return "No log files found yet."
        }

        return (Get-Content $Latest.FullName -Tail 60 | Out-String)
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}


function Open-GuiGameControllers {
    try {
        Start-Process "joy.cpl"
        Write-Log "GUI opened Game Controllers panel"
        return "Opened Game Controllers"
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}

function Open-GuiMouseSettings {
    try {
        Start-Process "ms-settings:mousetouchpad"
        Write-Log "GUI opened Mouse settings"
        return "Opened Mouse Settings"
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}

function Open-GuiMemoryIntegritySettings {
    try {
        Start-Process "windowsdefender://coreisolation"
        Write-Log "GUI opened Core Isolation settings"
        return "Opened Core Isolation / Memory Integrity settings. Only change this if you understand the security trade-off."
    }
    catch {
        try {
            Start-Process "ms-settings:windowsdefender"
            return "Opened Windows Security settings."
        }
        catch {
            return "Failed: $($_.Exception.Message)"
        }
    }
}

function Get-GuiControllerOverclockInfo {
    return @"
Controller overclocking is not applied automatically.

Important:
- It can require third-party drivers/tools.
- It may require Secure Boot / Memory Integrity changes.
- It can reduce Windows security.
- It may cause controller disconnects or driver issues.

Recommended:
Only do this manually if you understand the risk and have a restore point.
"@
}

function Set-GuiInputResponsiveness {
    try {
        # Safe input-related responsiveness values.
        New-Item -Path "HKCU:\Control Panel\Mouse" -Force | Out-Null

        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -Value "10" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -ErrorAction SilentlyContinue

        Write-Log "GUI input responsiveness tweaks applied"
        return "Success - input responsiveness tweaks applied. Sign out/restart recommended."
    }
    catch {
        Write-Log "GUI input responsiveness failed: $($_.Exception.Message)" "ERROR"
        return "Failed: $($_.Exception.Message)"
    }
}


function Enable-GuiOptimizerScripts {
    try {
        $Root = Split-Path -Parent $PSScriptRoot

        Get-ChildItem -Path $Root -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object {
                try { Unblock-File -Path $_.FullName -ErrorAction SilentlyContinue } catch {}
            }

        try {
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction SilentlyContinue
        }
        catch {}

        Write-Log "GUI optimizer scripts unblocked / CurrentUser RemoteSigned attempted"
        return "Success - optimizer scripts allowed/unblocked"
    }
    catch {
        Write-Log "GUI allow scripts failed: $($_.Exception.Message)" "ERROR"
        return "Failed: $($_.Exception.Message)"
    }
}

function Restore-GuiWindowsDefaults {
    if (!(Assert-Admin)) { return "Failed - run the app as Administrator" }

    try {
        Write-Log "GUI restoring Windows defaults"

        # Power plan
        Set-BalancedPowerPlan | Out-Null

        # Game defaults
        try { Restore-GameMode | Out-Null } catch {}
        try { Restore-GameDVR | Out-Null } catch {}
        try { Restore-HAGS | Out-Null } catch {}
        try { Restore-WindowedOptimizations | Out-Null } catch {}
        try { Restore-MouseAcceleration | Out-Null } catch {}

        # Windows visual effects / Explorer defaults that the optimizer commonly touches.
        try {
            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -ErrorAction SilentlyContinue
        } catch {}

        # Background apps / location are returned to Windows-managed/default where possible.
        try {
            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -ErrorAction SilentlyContinue
        } catch {}

        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Allow" -ErrorAction SilentlyContinue
        } catch {}

        # USB selective suspend back on for Balanced where supported.
        try {
            cmd /c "powercfg -setacvalueindex SCHEME_BALANCED SUB_USB USBSELECTIVE 1 >nul 2>nul"
            cmd /c "powercfg -setdcvalueindex SCHEME_BALANCED SUB_USB USBSELECTIVE 1 >nul 2>nul"
            powercfg /setactive SCHEME_BALANCED | Out-Null
        } catch {}

        Write-Log "GUI Windows defaults restored"
        return "Success - Windows defaults restored. Restart recommended."
    }
    catch {
        Write-Log "GUI restore Windows defaults failed: $($_.Exception.Message)" "ERROR"
        return "Failed: $($_.Exception.Message)"
    }
}


function Enable-GuiGpuMsiMode {
    if (!(Assert-Admin)) { return "Failed - run the app as Administrator" }

    try {
        $Gpu = Get-CimInstance Win32_VideoController |
            Where-Object {
                $_.PNPDeviceID -like "PCI\*" -and
                $_.Name -notmatch "Microsoft Basic|Remote|Parsec|Virtual"
            } |
            Select-Object -First 1

        if (!$Gpu) {
            return "Failed - no PCI GPU found"
        }

        $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($Gpu.PNPDeviceID)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"

        New-Item -Path $RegPath -Force | Out-Null

        New-ItemProperty -Path $RegPath -Name "MSISupported" -PropertyType DWord -Value 1 -Force | Out-Null
        New-ItemProperty -Path $RegPath -Name "MessageNumberLimit" -PropertyType DWord -Value 1 -Force | Out-Null

        Write-Log "GUI enabled MSI mode for GPU: $($Gpu.Name)"
        return "Success - MSI mode enabled for $($Gpu.Name). Restart required."
    }
    catch {
        Write-Log "GUI GPU MSI mode failed: $($_.Exception.Message)" "ERROR"
        return "Failed: $($_.Exception.Message)"
    }
}

function Get-GuiGpuMsiStatus {
    try {
        $Gpu = Get-CimInstance Win32_VideoController |
            Where-Object {
                $_.PNPDeviceID -like "PCI\*" -and
                $_.Name -notmatch "Microsoft Basic|Remote|Parsec|Virtual"
            } |
            Select-Object -First 1

        if (!$Gpu) {
            return "No PCI GPU found."
        }

        $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($Gpu.PNPDeviceID)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        $Value = (Get-ItemProperty -Path $RegPath -Name "MSISupported" -ErrorAction SilentlyContinue).MSISupported

        if ($Value -eq 1) {
            return "MSI mode appears enabled for $($Gpu.Name)."
        }

        return "MSI mode does not appear enabled for $($Gpu.Name)."
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}

function Apply-GuiNvidiaBestProfileHelper {
    try {
        $Gpu = Get-CimInstance Win32_VideoController |
            Where-Object { $_.Name -match "NVIDIA" } |
            Select-Object -First 1

        if (!$Gpu) {
            return "No NVIDIA GPU detected. This helper is for NVIDIA systems."
        }

        try { Start-Process "nvcplui.exe" -ErrorAction SilentlyContinue } catch {}

        return @"
NVIDIA GPU detected: $($Gpu.Name)

Opened NVIDIA Control Panel if available.

Recommended global/profile settings for gaming:

Manage 3D settings:
- Power management mode: Prefer maximum performance
- Low Latency Mode: On or Ultra, test both
- Shader Cache Size: Driver Default or Unlimited
- Texture filtering - Quality: High performance
- Threaded optimization: Auto
- Vertical sync: Off, unless you use G-Sync/FreeSync with a frame cap
- Max Frame Rate: Use only if you want a cap
- Preferred refresh rate: Highest available
- OpenGL rendering GPU: Your NVIDIA GPU

Display:
- Set highest refresh rate
- Use native resolution
- Enable G-Sync if your monitor supports it

Full automatic driver profile applying requires NVIDIA Profile Inspector/NVAPI.
This app does not silently write NVIDIA binary driver profiles yet.
"@
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}


function Set-GuiAllDisplaysMaxRefreshRate {
    try {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class SlxdeDisplay {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
        public short dmSpecVersion; public short dmDriverVersion; public short dmSize; public short dmDriverExtra;
        public int dmFields; public int dmPositionX; public int dmPositionY; public int dmDisplayOrientation; public int dmDisplayFixedOutput;
        public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption; public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
        public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight; public int dmDisplayFlags; public int dmDisplayFrequency;
        public int dmICMMethod; public int dmICMIntent; public int dmMediaType; public int dmDitherType; public int dmReserved1; public int dmReserved2; public int dmPanningWidth; public int dmPanningHeight;
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DISPLAY_DEVICE {
        public int cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
        public int StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
    }
    [DllImport("user32.dll", CharSet = CharSet.Ansi)] public static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);
    [DllImport("user32.dll", CharSet = CharSet.Ansi)] public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);
    [DllImport("user32.dll", CharSet = CharSet.Ansi)] public static extern int ChangeDisplaySettingsEx(string lpszDeviceName, ref DEVMODE lpDevMode, IntPtr hwnd, int dwflags, IntPtr lParam);
}
"@ -ErrorAction SilentlyContinue

        $Changed = @()
        $Notes = @()
        $ENUM_CURRENT_SETTINGS = -1
        $CDS_UPDATEREGISTRY = 1
        $CDS_NORESET = 0x10000000
        $CDS_RESET = 0x40000000

        for ($i = 0; $i -lt 16; $i++) {
            $dev = New-Object SlxdeDisplay+DISPLAY_DEVICE
            $dev.cb = [Runtime.InteropServices.Marshal]::SizeOf($dev)
            if (-not [SlxdeDisplay]::EnumDisplayDevices($null, [uint32]$i, [ref]$dev, 0)) { continue }
            if (($dev.StateFlags -band 1) -ne 1) { continue }

            $cur = New-Object SlxdeDisplay+DEVMODE
            $cur.dmSize = [Runtime.InteropServices.Marshal]::SizeOf($cur)
            if (-not [SlxdeDisplay]::EnumDisplaySettings($dev.DeviceName, $ENUM_CURRENT_SETTINGS, [ref]$cur)) { continue }

            $best = $null
            for ($m = 0; $m -lt 512; $m++) {
                $mode = New-Object SlxdeDisplay+DEVMODE
                $mode.dmSize = [Runtime.InteropServices.Marshal]::SizeOf($mode)
                if (-not [SlxdeDisplay]::EnumDisplaySettings($dev.DeviceName, $m, [ref]$mode)) { break }

                if ($mode.dmPelsWidth -eq $cur.dmPelsWidth -and $mode.dmPelsHeight -eq $cur.dmPelsHeight -and $mode.dmBitsPerPel -eq $cur.dmBitsPerPel) {
                    if ($null -eq $best -or $mode.dmDisplayFrequency -gt $best.dmDisplayFrequency) { $best = $mode }
                }
            }

            if ($null -eq $best -or $best.dmDisplayFrequency -le $cur.dmDisplayFrequency) {
                $Notes += "$($dev.DeviceString): already max/current at $($cur.dmDisplayFrequency)Hz"
                continue
            }

            $result = [SlxdeDisplay]::ChangeDisplaySettingsEx($dev.DeviceName, [ref]$best, [IntPtr]::Zero, $CDS_UPDATEREGISTRY -bor $CDS_NORESET, [IntPtr]::Zero)
            if ($result -eq 0) { $Changed += "$($dev.DeviceString): $($cur.dmDisplayFrequency)Hz -> $($best.dmDisplayFrequency)Hz" }
            else { $Notes += "$($dev.DeviceString): failed code $result" }
        }

        $dummy = New-Object SlxdeDisplay+DEVMODE
        $dummy.dmSize = [Runtime.InteropServices.Marshal]::SizeOf($dummy)
        [void][SlxdeDisplay]::ChangeDisplaySettingsEx($null, [ref]$dummy, [IntPtr]::Zero, $CDS_RESET, [IntPtr]::Zero)

        if ($Changed.Count -eq 0) {
            return "Max refresh check complete. No changes made.`n`n$($Notes -join "`n")"
        }

        Write-Log "GUI max refresh applied: $($Changed -join '; ')"
        return "Max refresh applied:`n`n$($Changed -join "`n")`n`nNotes:`n$($Notes -join "`n")"
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}


function Enable-GuiRightClickEndTask {
    try {
        if (Get-Command Enable-RightClickEndTask -ErrorAction SilentlyContinue) {
            return Enable-RightClickEndTask
        }

        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -PropertyType DWord -Value 1 -Force | Out-Null

        Write-Log "GUI enabled right-click End Task"
        return "Success - right-click End Task enabled. Restart Explorer or restart PC if it does not appear."
    }
    catch {
        Write-Log "GUI right-click End Task failed: $($_.Exception.Message)" "ERROR"
        return "Failed: $($_.Exception.Message)"
    }
}

function Set-GuiExplorerThisPC {
    try {
        if (Get-Command Set-ExplorerThisPC -ErrorAction SilentlyContinue) {
            return Set-ExplorerThisPC
        }

        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -PropertyType DWord -Value 1 -Force | Out-Null

        Write-Log "GUI set Explorer to This PC"
        return "Success - File Explorer now opens to This PC"
    }
    catch {
        Write-Log "GUI Explorer This PC failed: $($_.Exception.Message)" "ERROR"
        return "Failed: $($_.Exception.Message)"
    }
}

function Set-GuiFastMenuDelay {
    try {
        New-Item -Path "HKCU:\Control Panel\Desktop" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -PropertyType String -Value "50" -Force | Out-Null

        New-Item -Path "HKCU:\Control Panel\Mouse" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -PropertyType String -Value "10" -Force | Out-Null

        Write-Log "GUI reduced menu/hover delay"
        return "Success - menu and hover delay reduced. Sign out/restart recommended."
    }
    catch {
        Write-Log "GUI menu/hover delay failed: $($_.Exception.Message)" "ERROR"
        return "Failed: $($_.Exception.Message)"
    }
}

function Disable-GuiStartupAppsDelay {
    try {
        if (Get-Command Disable-StartupAppsDelay -ErrorAction SilentlyContinue) {
            return Disable-StartupAppsDelay
        }

        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -PropertyType DWord -Value 0 -Force | Out-Null

        Write-Log "GUI disabled startup apps delay"
        return "Success - startup apps delay disabled"
    }
    catch {
        Write-Log "GUI startup delay failed: $($_.Exception.Message)" "ERROR"
        return "Failed: $($_.Exception.Message)"
    }
}

function Open-GuiStartupAppsSettings {
    try {
        Start-Process "ms-settings:startupapps"
        Write-Log "GUI opened startup apps settings"
        return "Opened Startup Apps settings"
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}

function Restart-GuiExplorer {
    try {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Process explorer.exe
        Write-Log "GUI restarted Explorer"
        return "Success - Explorer restarted"
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}


function Get-GuiGpuMsiStatusShort {
    try {
        $Gpu = Get-CimInstance Win32_VideoController |
            Where-Object {
                $_.PNPDeviceID -like "PCI\*" -and
                $_.Name -notmatch "Microsoft Basic|Remote|Parsec|Virtual"
            } |
            Select-Object -First 1

        if (!$Gpu) {
            return "Unknown - no PCI GPU found"
        }

        $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($Gpu.PNPDeviceID)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        $Value = (Get-ItemProperty -Path $RegPath -Name "MSISupported" -ErrorAction SilentlyContinue).MSISupported

        if ($Value -eq 1) {
            return "Enabled - $($Gpu.Name)"
        }

        return "Not Enabled - $($Gpu.Name)"
    }
    catch {
        return "Unknown"
    }
}


function Apply-GuiNvidiaDriverSettings {
    try {
        $Gpu = Get-CimInstance Win32_VideoController |
            Where-Object { $_.Name -match "NVIDIA" } |
            Select-Object -First 1

        if (!$Gpu) {
            return "No NVIDIA GPU detected. This setting is for NVIDIA systems."
        }

        try { Start-Process "nvcplui.exe" -ErrorAction SilentlyContinue } catch {}

        return @"
NVIDIA GPU detected: $($Gpu.Name)

Opened NVIDIA Control Panel if available.

Recommended NVIDIA settings:

Manage 3D Settings:
- Power management mode: Prefer maximum performance
- Low Latency Mode: On or Ultra, test both
- Shader Cache Size: Driver Default or Unlimited
- Texture filtering - Quality: High performance
- Threaded optimization: Auto
- Vertical sync: Off unless using G-Sync/FreeSync with frame cap
- Preferred refresh rate: Highest available
- OpenGL rendering GPU: Your NVIDIA GPU

Automatic NVIDIA profile writing will need NVIDIA Profile Inspector/NVAPI support in a later build.
"@
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}
