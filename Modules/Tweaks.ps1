# =====================================================
# Tweaks.ps1
# Safe optimization actions
# =====================================================

function Enable-GameMode {
    try {
        Write-Log "Enabling Game Mode..."
        New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Log "Game Mode enabled successfully."
        return "Success"
    } catch {
        Write-Log "Failed to enable Game Mode: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Disable-GameDVR {
    try {
        Write-Log "Disabling Game DVR..."
        New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -PropertyType DWord -Force | Out-Null
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
        Write-Log "Game DVR disabled successfully."
        return "Success"
    } catch {
        Write-Log "Failed to disable Game DVR: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Enable-HAGS {
    try {
        Write-Log "Enabling HAGS..."
       if (!(Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers")) {
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "GraphicsDrivers" -Force | Out-Null
}
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -PropertyType DWord -Force | Out-Null
        Write-Log "HAGS enabled successfully. Restart required."
        return "Success"
    } catch {
        Write-Log "Failed to enable HAGS: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Enable-WindowedOptimizations {
    try {
        Write-Log "Enabling Optimizations for Windowed Games..."
        New-Item -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Force | Out-Null
        New-ItemProperty -Path "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences" -Name "DirectXUserGlobalSettings" -Value "SwapEffectUpgradeEnable=1;" -PropertyType String -Force | Out-Null
        Write-Log "Windowed Optimizations enabled successfully."
        return "Success"
    } catch {
        Write-Log "Failed to enable Windowed Optimizations: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Disable-MouseAcceleration {
    try {
        Write-Log "Disabling mouse acceleration..."
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0"
        Write-Log "Mouse acceleration disabled successfully."
        return "Success"
    } catch {
        Write-Log "Failed to disable mouse acceleration: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Invoke-SafeGamingTweaks {
    Show-Banner
    Write-Host ""
    Write-Host "Applying safe gaming tweaks..." -ForegroundColor Yellow
    Write-Host ""

    $Restore = New-OptimizerRestorePoint
    if ($Restore -eq "Success") { Write-Host "Restore Point            Success" -ForegroundColor Green }
    else { Write-Host "Restore Point            Failed/Skipped" -ForegroundColor Yellow }

    $Actions = @(
        @{ Name = "Enable Game Mode"; Function = { Enable-GameMode } },
        @{ Name = "Disable Game DVR"; Function = { Disable-GameDVR } },
        @{ Name = "Enable HAGS"; Function = { Enable-HAGS } },
        @{ Name = "Windowed Optimizations"; Function = { Enable-WindowedOptimizations } },
        @{ Name = "Disable Mouse Acceleration"; Function = { Disable-MouseAcceleration } }
    )

    foreach ($Action in $Actions) {
        $Result = & $Action.Function
        if ($Result -eq "Success") { Write-Status $Action.Name "Success" "Green" }
        else { Write-Status $Action.Name "Failed" "Red" }
    }

    Write-Host ""
    Write-Host "Done. Some changes may require a restart." -ForegroundColor Yellow
    Write-Log "Safe gaming tweaks completed"
    Pause-App
}
