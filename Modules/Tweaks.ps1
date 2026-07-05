# =====================================================
# Tweaks.ps1
# =====================================================

function Set-RegistryDword {
    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )

    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
}

function Set-RegistryString {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value
    )

    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType String -Force | Out-Null
}

function Enable-GameMode {
    try {
        Write-Log "Enabling Game Mode"
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1
        return "Success"
    }
    catch { Write-Log "Enable Game Mode failed: $($_.Exception.Message)" "ERROR"; return "Failed" }
}

function Disable-GameDVR {
    try {
        Write-Log "Disabling Game DVR"
        Set-RegistryDword -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
        Set-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0
        return "Success"
    }
    catch { Write-Log "Disable Game DVR failed: $($_.Exception.Message)" "ERROR"; return "Failed" }
}

function Enable-HAGS {
    try {
        Write-Log "Enabling HAGS"
        Set-RegistryDword -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2
        return "Success"
    }
    catch { Write-Log "Enable HAGS failed: $($_.Exception.Message)" "ERROR"; return "Failed" }
}

function Enable-WindowedOptimizations {
    try {
        Write-Log "Enabling Windowed Optimizations"
        Set-RegistryString -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name "DirectXUserGlobalSettings" -Value "SwapEffectUpgradeEnable=1;"
        return "Success"
    }
    catch { Write-Log "Enable Windowed Optimizations failed: $($_.Exception.Message)" "ERROR"; return "Failed" }
}

function Disable-MouseAcceleration {
    try {
        Write-Log "Disabling mouse acceleration"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0"
        return "Success"
    }
    catch { Write-Log "Disable Mouse Acceleration failed: $($_.Exception.Message)" "ERROR"; return "Failed" }
}

function Apply-SafeGamingTweaks {
    Show-Banner
    Write-Host "Applying safe gaming tweaks..." -ForegroundColor Yellow
    Write-Host ""

    $RestorePoint = New-OptimizerRestorePoint
    Write-Status "Restore Point" $RestorePoint $(if ($RestorePoint -eq "Success") { "Green" } else { "Yellow" })

    $GameMode = Enable-GameMode
    Write-Status "Enable Game Mode" $GameMode $(if ($GameMode -eq "Success") { "Green" } else { "Red" })

    $GameDVR = Disable-GameDVR
    Write-Status "Disable Game DVR" $GameDVR $(if ($GameDVR -eq "Success") { "Green" } else { "Red" })

    $HAGS = Enable-HAGS
    Write-Status "Enable HAGS" $HAGS $(if ($HAGS -eq "Success") { "Green" } else { "Red" })

    $Windowed = Enable-WindowedOptimizations
    Write-Status "Windowed Optimizations" $Windowed $(if ($Windowed -eq "Success") { "Green" } else { "Red" })

    $Mouse = Disable-MouseAcceleration
    Write-Status "Disable Mouse Acceleration" $Mouse $(if ($Mouse -eq "Success") { "Green" } else { "Red" })

    Write-Host ""
    Write-Host "Done. Some changes may require a restart." -ForegroundColor Yellow
    Pause-App
}
