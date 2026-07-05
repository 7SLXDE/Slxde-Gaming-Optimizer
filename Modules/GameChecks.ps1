# =====================================================
# GameChecks.ps1
# =====================================================

function Get-GameModeStatus {
    try {
        $Value = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -ErrorAction Stop
        if ($Value -eq 1) { return "Enabled" }
        return "Disabled"
    }
    catch { return "Unknown" }
}

function Get-GameDVRStatus {
    try {
        $Value = Get-ItemPropertyValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -ErrorAction Stop
        if ($Value -eq 1) { return "Enabled" }
        return "Disabled"
    }
    catch { return "Unknown" }
}

function Get-XboxCaptureStatus {
    try {
        $Value = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -ErrorAction Stop
        if ($Value -eq 1) { return "Enabled" }
        return "Disabled"
    }
    catch { return "Unknown" }
}

function Get-HAGSStatus {
    try {
        $Value = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -ErrorAction Stop

        switch ($Value) {
            2 { return "Enabled" }
            1 { return "Disabled" }
            0 { return "Default" }
            default { return "Unknown" }
        }
    }
    catch { return "Unknown" }
}

function Get-WindowedOptimizationsStatus {
    try {
        $Value = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name "DirectXUserGlobalSettings" -ErrorAction Stop

        if ($Value -match "SwapEffectUpgradeEnable=1") { return "Enabled" }
        if ($Value -match "SwapEffectUpgradeEnable=0") { return "Disabled" }
        return "Unknown"
    }
    catch { return "Unknown" }
}

function Get-MouseAccelerationStatus {
    try {
        $MouseSpeed = Get-ItemPropertyValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -ErrorAction Stop
        $Threshold1 = Get-ItemPropertyValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -ErrorAction Stop
        $Threshold2 = Get-ItemPropertyValue -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -ErrorAction Stop

        if ($MouseSpeed -eq "0" -and $Threshold1 -eq "0" -and $Threshold2 -eq "0") { return "Disabled" }
        return "Enabled"
    }
    catch { return "Unknown" }
}
