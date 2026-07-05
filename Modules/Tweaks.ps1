# =====================================================
# Tweaks.ps1
# Safe gaming tweaks
# =====================================================

function Enable-GameMode {
    try {
        New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Log "Game Mode enabled"
        return "Success"
    }
    catch {
        Write-Log "Failed to enable Game Mode: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Disable-GameDVR {
    try {
        New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -PropertyType DWord -Force | Out-Null

        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -PropertyType DWord -Force | Out-Null

        Write-Log "Game DVR / Xbox Capture disabled"
        return "Success"
    }
    catch {
        Write-Log "Failed to disable Game DVR: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Enable-HAGS {
    try {
        if (!(Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers")) {
            New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "GraphicsDrivers" -Force | Out-Null
        }

        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -PropertyType DWord -Force | Out-Null

        Write-Log "HAGS enabled"
        return "Success"
    }
    catch {
        Write-Log "Failed to enable HAGS: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Enable-WindowedOptimizations {
    try {
        New-Item -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name "DirectXUserGlobalSettings" -Value "SwapEffectUpgradeEnable=1;" -PropertyType String -Force | Out-Null

        Write-Log "Windowed optimizations enabled"
        return "Success"
    }
    catch {
        Write-Log "Failed to enable windowed optimizations: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Disable-MouseAcceleration {
    try {
        New-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -PropertyType String -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -PropertyType String -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -PropertyType String -Force | Out-Null

        Write-Log "Mouse acceleration disabled"
        return "Success"
    }
    catch {
        Write-Log "Failed to disable mouse acceleration: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Invoke-SafeGamingTweaks {
    Show-Banner
    Write-Host ""
    Write-Host "Applying safe gaming tweaks..." -ForegroundColor Yellow
    Write-Host ""

    $RP = New-OptimizerRestorePoint
    Write-Status "Restore Point" $RP $(if($RP -eq "Success"){"Green"}else{"Yellow"})

    Write-Status "Enable Game Mode" (Enable-GameMode) "Green"
    Write-Status "Disable Game DVR" (Disable-GameDVR) "Green"
    Write-Status "Enable HAGS" (Enable-HAGS) "Green"
    Write-Status "Windowed Optimizations" (Enable-WindowedOptimizations) "Green"
    Write-Status "Disable Mouse Acceleration" (Disable-MouseAcceleration) "Green"

    Write-Host ""
    Write-Host "Done. Some changes may require a restart." -ForegroundColor Yellow
    Pause-App
}

function Restore-GamingTweaks {
    Show-Banner
    Write-Host ""
    Write-Host "Restoring gaming tweak defaults..." -ForegroundColor Yellow
    Write-Host ""

    try {
        New-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Status "Restore Game Mode" "Success" "Green"
    } catch { Write-Status "Restore Game Mode" "Failed" "Red" }

    try {
        New-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Status "Restore Game DVR/Capture" "Success" "Green"
    } catch { Write-Status "Restore Game DVR/Capture" "Failed" "Red" }

    try {
        Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -ErrorAction SilentlyContinue
        Write-Status "Restore HAGS Default" "Success" "Green"
    } catch { Write-Status "Restore HAGS Default" "Failed" "Red" }

    try {
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name "DirectXUserGlobalSettings" -ErrorAction SilentlyContinue
        Write-Status "Restore Windowed Optimizations" "Success" "Green"
    } catch { Write-Status "Restore Windowed Optimizations" "Failed" "Red" }

    try {
        New-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "1" -PropertyType String -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "6" -PropertyType String -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "10" -PropertyType String -Force | Out-Null
        Write-Status "Restore Mouse Acceleration" "Success" "Green"
    } catch { Write-Status "Restore Mouse Acceleration" "Failed" "Red" }

    Write-Host ""
    Write-Host "Restore complete. Some changes may require a restart." -ForegroundColor Yellow
    Pause-App
}
