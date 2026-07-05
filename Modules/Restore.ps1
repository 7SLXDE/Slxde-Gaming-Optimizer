# =====================================================
# Restore.ps1
# Restore / undo gaming tweaks
# =====================================================

function Restore-RegistryDword {
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

function Restore-RegistryString {
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

function Restore-GameModeDefault {
    try {
        Write-Log "Restoring Game Mode default/on"
        Restore-RegistryDword -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1
        return "Success"
    }
    catch { Write-Log "Restore Game Mode failed: $($_.Exception.Message)" "ERROR"; return "Failed" }
}

function Restore-GameDVRDefault {
    try {
        Write-Log "Restoring Game DVR/Xbox Capture default/on"
        Restore-RegistryDword -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1
        Restore-RegistryDword -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 1
        return "Success"
    }
    catch { Write-Log "Restore Game DVR failed: $($_.Exception.Message)" "ERROR"; return "Failed" }
}

function Restore-HAGSDefault {
    try {
        Write-Log "Restoring HAGS to Windows default"
        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        if (Test-Path $Path) {
            Remove-ItemProperty -Path $Path -Name "HwSchMode" -ErrorAction SilentlyContinue
        }
        return "Success"
    }
    catch { Write-Log "Restore HAGS failed: $($_.Exception.Message)" "ERROR"; return "Failed" }
}

function Restore-WindowedOptimizationsDefault {
    try {
        Write-Log "Restoring Windowed Optimizations to Windows default"
        $Path = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
        if (Test-Path $Path) {
            Remove-ItemProperty -Path $Path -Name "DirectXUserGlobalSettings" -ErrorAction SilentlyContinue
        }
        return "Success"
    }
    catch { Write-Log "Restore Windowed Optimizations failed: $($_.Exception.Message)" "ERROR"; return "Failed" }
}

function Restore-MouseAccelerationDefault {
    try {
        Write-Log "Restoring mouse acceleration default"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "1"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "6"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "10"
        return "Success"
    }
    catch { Write-Log "Restore Mouse Acceleration failed: $($_.Exception.Message)" "ERROR"; return "Failed" }
}

function Restore-GamingTweaks {
    Show-Banner
    Write-Host "Restoring gaming tweak defaults..." -ForegroundColor Yellow
    Write-Host ""

    $GameMode = Restore-GameModeDefault
    Write-Status "Restore Game Mode" $GameMode $(if ($GameMode -eq "Success") { "Green" } else { "Red" })

    $GameDVR = Restore-GameDVRDefault
    Write-Status "Restore Game DVR/Capture" $GameDVR $(if ($GameDVR -eq "Success") { "Green" } else { "Red" })

    $HAGS = Restore-HAGSDefault
    Write-Status "Restore HAGS Default" $HAGS $(if ($HAGS -eq "Success") { "Green" } else { "Red" })

    $Windowed = Restore-WindowedOptimizationsDefault
    Write-Status "Restore Windowed Optimizations" $Windowed $(if ($Windowed -eq "Success") { "Green" } else { "Red" })

    $Mouse = Restore-MouseAccelerationDefault
    Write-Status "Restore Mouse Acceleration" $Mouse $(if ($Mouse -eq "Success") { "Green" } else { "Red" })

    Write-Host ""
    Write-Host "Restore complete. Some changes may require a restart." -ForegroundColor Yellow
    Pause-App
}
