# =====================================================
# GameChecks.ps1
# Windows gaming setting detection
# =====================================================

function Get-GameModeStatus {
    $Value = Get-SafeRegistryValue -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled"

    if ($null -eq $Value) { return "Unknown" }
    if ($Value -eq 1) { return "Enabled" }
    return "Disabled"
}

function Get-GameDVRStatus {
    $Value = Get-SafeRegistryValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled"

    if ($null -eq $Value) { return "Unknown" }
    if ($Value -eq 1) { return "Enabled" }
    return "Disabled"
}

function Get-XboxGameBarStatus {
    $Value = Get-SafeRegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled"

    if ($null -eq $Value) { return "Unknown" }
    if ($Value -eq 1) { return "Enabled" }
    return "Disabled"
}

function Get-HAGSStatus {
    $Value = Get-SafeRegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode"

    if ($null -eq $Value) { return "Unknown" }

    switch ($Value) {
        2 { return "Enabled" }
        1 { return "Disabled" }
        0 { return "Default" }
        default { return "Unknown" }
    }
}

function Get-DirectXGlobalSettingString {
    return Get-SafeRegistryValue -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name "DirectXUserGlobalSettings"
}

function Get-VariableRefreshRateStatus {
    $Value = Get-DirectXGlobalSettingString

    if ([string]::IsNullOrWhiteSpace($Value)) { return "Unknown" }
    if ($Value -match "VRROptimizeEnable=1") { return "Enabled" }
    if ($Value -match "VRROptimizeEnable=0") { return "Disabled" }
    return "Unknown"
}

function Get-WindowedOptimizationsStatus {
    $Value = Get-DirectXGlobalSettingString

    if ([string]::IsNullOrWhiteSpace($Value)) { return "Unknown" }
    if ($Value -match "SwapEffectUpgradeEnable=1") { return "Enabled" }
    if ($Value -match "SwapEffectUpgradeEnable=0") { return "Disabled" }
    return "Unknown"
}
