# =====================================================
# WindowsTweaks.ps1
# Requested Windows tweak actions
# =====================================================

function Optimize-WindowsAppearance {
    try {
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -PropertyType Binary -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -PropertyType DWord -Force | Out-Null
        Write-Log "Windows appearance optimized"
        return "Success"
    }
    catch {
        Write-Log "Failed to optimize Windows appearance: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Disable-BackgroundApps {
    try {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Log "Background apps disabled"
        return "Success"
    }
    catch {
        Write-Log "Failed to disable background apps: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Disable-LocationTracking {
    try {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -PropertyType String -Force | Out-Null
        Write-Log "Location tracking disabled"
        return "Success"
    }
    catch {
        Write-Log "Failed to disable location tracking: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Disable-USBPowerSaving {
    try {
        powercfg -setacvalueindex SCHEME_CURRENT SUB_USB USBSELECTIVE 0 | Out-Null
        powercfg -setdcvalueindex SCHEME_CURRENT SUB_USB USBSELECTIVE 0 | Out-Null
        powercfg /setactive SCHEME_CURRENT | Out-Null

        $UsbDevices = Get-CimInstance MSPower_DeviceEnable -Namespace root\wmi -ErrorAction SilentlyContinue
        foreach ($Device in $UsbDevices) {
            $Device.Enable = $false
            Set-CimInstance -InputObject $Device -ErrorAction SilentlyContinue | Out-Null
        }

        Write-Log "USB power saving disabled"
        return "Success"
    }
    catch {
        Write-Log "Failed to disable USB power saving: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Disable-StartupDelay {
    try {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -Value 0 -PropertyType DWord -Force | Out-Null
        Write-Log "Startup delay disabled"
        return "Success"
    }
    catch {
        Write-Log "Failed to disable startup delay: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Set-ExplorerThisPC {
    try {
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Log "Explorer set to This PC"
        return "Success"
    }
    catch {
        Write-Log "Failed to set Explorer to This PC: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Enable-RightClickEndTask {
    try {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Log "Right-click End Task enabled"
        return "Success"
    }
    catch {
        Write-Log "Failed to enable right-click End Task: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Reduce-MouseHoverTime {
    try {
        New-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -Value "100" -PropertyType String -Force | Out-Null
        Write-Log "Mouse hover time reduced"
        return "Success"
    }
    catch {
        Write-Log "Failed to reduce mouse hover time: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Open-DisplaySettings {
    Start-Process "ms-settings:display-advanced"
    Write-Log "Opened advanced display settings"
    return "Opened"
}

function Open-StartupApps {
    Start-Process "ms-settings:startupapps"
    Write-Log "Opened startup apps settings"
    return "Opened"
}

function Show-WindowsTweaksMenu {

    while ($true) {
        Show-Banner
        Write-Host "Windows Tweaks" -ForegroundColor Yellow
        Write-Host ""

        Write-Host "  1. Create / Load SLXDE Power Plan"
        Write-Host "  2. Load Balanced Power Plan"
        Write-Host "  3. Optimize Windows Appearance"
        Write-Host "  4. Disable Background Apps"
        Write-Host "  5. Disable Location Tracking"
        Write-Host "  6. Disable USB Power Saving"
        Write-Host "  7. Disable Startup Apps Delay"
        Write-Host "  8. Open Max Refresh Rate Settings"
        Write-Host "  9. Open Startup Apps Settings"
        Write-Host ""
        Write-Host "  A. Apply All Safe Windows Tweaks"
        Write-Host "  0. Back"
        Write-Host ""

        $Choice = Read-Host "Select"

        switch ($Choice.ToUpper()) {
            "1" { Write-Status "SLXDE Power Plan" (New-SlxdePowerPlan) "Green"; Pause-App }
            "2" { Write-Status "Balanced Power Plan" (Set-BalancedPowerPlan) "Green"; Pause-App }
            "3" { Write-Status "Optimize Appearance" (Optimize-WindowsAppearance) "Green"; Pause-App }
            "4" { Write-Status "Disable Background Apps" (Disable-BackgroundApps) "Green"; Pause-App }
            "5" { Write-Status "Disable Location" (Disable-LocationTracking) "Green"; Pause-App }
            "6" { Write-Status "Disable USB Power Saving" (Disable-USBPowerSaving) "Green"; Pause-App }
            "7" { Write-Status "Disable Startup Delay" (Disable-StartupDelay) "Green"; Pause-App }
            "8" { Write-Status "Display Settings" (Open-DisplaySettings) "Yellow"; Pause-App }
            "9" { Write-Status "Startup Apps Settings" (Open-StartupApps) "Yellow"; Pause-App }

            "A" {
                Show-Banner
                Write-Host "Applying safe Windows tweaks..." -ForegroundColor Yellow
                Write-Host ""

                Write-Status "Restore Point" (New-OptimizerRestorePoint) "Green"
                Write-Status "SLXDE Power Plan" (New-SlxdePowerPlan) "Green"
                Write-Status "Optimize Appearance" (Optimize-WindowsAppearance) "Green"
                Write-Status "Disable Background Apps" (Disable-BackgroundApps) "Green"
                Write-Status "Disable Location" (Disable-LocationTracking) "Green"
                Write-Status "Disable USB Power Saving" (Disable-USBPowerSaving) "Green"
                Write-Status "Disable Startup Delay" (Disable-StartupDelay) "Green"

                Write-Host ""
                Write-Host "Done. Some changes may require sign-out or restart." -ForegroundColor Yellow
                Pause-App
            }

            "0" { return }

            default {
                Write-Host "Invalid option." -ForegroundColor Red
                Pause-App
            }
        }
    }
}
