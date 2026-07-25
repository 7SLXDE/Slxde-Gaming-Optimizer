# =====================================================
# GameChecks.ps1
# =====================================================

function Get-RegValueOrUnknown {
    param(
        [string]$Path,
        [string]$Name
    )

    try {
        return Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop
    }
    catch {
        return $null
    }
}

function Get-GameModeStatus {
    $Value = Get-RegValueOrUnknown "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled"
    if ($null -eq $Value) { return "Unknown" }
    if ($Value -eq 1) { return "Enabled" }
    return "Disabled"
}

function Get-GameDVRStatus {
    $Value = Get-RegValueOrUnknown "HKCU:\System\GameConfigStore" "GameDVR_Enabled"
    if ($null -eq $Value) { return "Unknown" }
    if ($Value -eq 1) { return "Enabled" }
    return "Disabled"
}

function Get-XboxCaptureStatus {
    $Value = Get-RegValueOrUnknown "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled"
    if ($null -eq $Value) { return "Unknown" }
    if ($Value -eq 1) { return "Enabled" }
    return "Disabled"
}

function Get-HAGSStatus {
    $Value = Get-RegValueOrUnknown "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode"
    if ($null -eq $Value) { return "Unknown" }

    switch ($Value) {
        2 { return "Enabled" }
        1 { return "Disabled" }
        0 { return "Default" }
        Default { return "Unknown" }
    }
}

function Get-WindowedOptimizationsStatus {
    $Value = Get-RegValueOrUnknown "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" "DirectXUserGlobalSettings"
    if ($null -eq $Value) { return "Unknown" }

    if ($Value -match "SwapEffectUpgradeEnable=1") { return "Enabled" }
    if ($Value -match "SwapEffectUpgradeEnable=0") { return "Disabled" }

    return "Unknown"
}
