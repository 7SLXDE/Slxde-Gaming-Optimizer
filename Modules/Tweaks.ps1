# =====================================================
# Tweaks.ps1
# Gaming tweak actions
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
        if (!(Assert-Admin)) { return "Failed" }

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

function Disable-FullscreenOptimizationsForExe {
    Show-Banner
    Write-Host "Disable Fullscreen Optimizations for Game EXE" -ForegroundColor Yellow
    Write-Host ""

    $Path = Read-Host "Paste full path to game .exe"

    if (!(Test-Path $Path)) {
        Write-Host "File not found." -ForegroundColor Red
        Pause-App
        return
    }

    try {
        New-Item -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Force | Out-Null
        New-ItemProperty `
            -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" `
            -Name $Path `
            -Value "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" `
            -PropertyType String `
            -Force | Out-Null

        Write-Log "Disabled fullscreen optimizations for $Path"
        Write-Host "Fullscreen optimizations disabled for:" -ForegroundColor Green
        Write-Host $Path
    }
    catch {
        Write-Log "Failed to disable fullscreen optimizations: $($_.Exception.Message)" "ERROR"
        Write-Host "Failed." -ForegroundColor Red
    }

    Pause-App
}

function Add-GameHighPerformanceGPUPreference {
    Show-Banner
    Write-Host "Add Game EXE to High Performance GPU Preference" -ForegroundColor Yellow
    Write-Host ""

    $Path = Read-Host "Paste full path to game .exe"

    if (!(Test-Path $Path)) {
        Write-Host "File not found." -ForegroundColor Red
        Pause-App
        return
    }

    try {
        New-Item -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Force | Out-Null
        New-ItemProperty `
            -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" `
            -Name $Path `
            -Value "GpuPreference=2;" `
            -PropertyType String `
            -Force | Out-Null

        Write-Log "Set high performance GPU preference for $Path"
        Write-Host "High performance GPU preference added for:" -ForegroundColor Green
        Write-Host $Path
    }
    catch {
        Write-Log "Failed to set high performance GPU preference: $($_.Exception.Message)" "ERROR"
        Write-Host "Failed." -ForegroundColor Red
    }

    Pause-App
}

function Invoke-SafeGamingTweaks {
    if (!(Confirm-Action "Apply all safe gaming tweaks? A restore point will be created first.")) { return }

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
    Write-Host "Done. Restart recommended." -ForegroundColor Yellow
    Pause-App
}

function Restore-GamingTweaks {
    if (!(Confirm-Action "Restore gaming tweak defaults?")) { return }

    Show-Banner
    Write-Host ""
    Write-Host "Restoring gaming tweak defaults..." -ForegroundColor Yellow
    Write-Host ""

    try {
        New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Status "Restore Game Mode" "Success" "Green"
    } catch { Write-Status "Restore Game Mode" "Failed" "Red" }

    try {
        New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null
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
    Write-Host "Restore complete. Restart recommended." -ForegroundColor Yellow
    Pause-App
}

function Show-GamingTweaksMenu {
    while ($true) {
        Show-Banner
        Write-Host "Gaming Tweaks" -ForegroundColor Yellow
        Write-Host ""

        Write-Host "  1. Enable Game Mode"
        Write-Host "  2. Disable Game DVR / Xbox Capture"
        Write-Host "  3. Enable HAGS"
        Write-Host "  4. Enable Windowed Optimizations"
        Write-Host "  5. Disable Mouse Acceleration"
        Write-Host "  6. Disable Fullscreen Optimizations for selected EXE"
        Write-Host "  7. Add selected EXE to High Performance GPU Preference"
        Write-Host ""
        Write-Host "  A. Apply All Safe Gaming Tweaks"
        Write-Host "  R. Restore Gaming Defaults"
        Write-Host "  0. Back"
        Write-Host ""

        $Choice = Read-Host "Select"

        switch ($Choice.ToUpper()) {
            "1" { Write-Status "Enable Game Mode" (Enable-GameMode) "Green"; Pause-App }
            "2" { Write-Status "Disable Game DVR" (Disable-GameDVR) "Green"; Pause-App }
            "3" { Write-Status "Enable HAGS" (Enable-HAGS) "Green"; Write-Host "Restart recommended." -ForegroundColor Yellow; Pause-App }
            "4" { Write-Status "Windowed Optimizations" (Enable-WindowedOptimizations) "Green"; Pause-App }
            "5" { Write-Status "Mouse Acceleration" (Disable-MouseAcceleration) "Green"; Pause-App }
            "6" { Disable-FullscreenOptimizationsForExe }
            "7" { Add-GameHighPerformanceGPUPreference }
            "A" { Invoke-SafeGamingTweaks }
            "R" { Restore-GamingTweaks }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Pause-App }
        }
    }
}
