# =====================================================
# DisplayTweaks.ps1
# =====================================================

function Get-DisplayRefreshInfo {
    Show-Banner
    Write-Host "Display Refresh Info" -ForegroundColor Yellow
    Write-Host ""

    try {
        $Video = Get-CimInstance Win32_VideoController | Select-Object -First 1

        Write-Status "GPU" $Video.Name "Green"
        Write-Status "Current Refresh" "$($Video.CurrentRefreshRate) Hz" "Cyan"
        Write-Status "Resolution" "$($Video.CurrentHorizontalResolution) x $($Video.CurrentVerticalResolution)" "Cyan"

        Write-Host ""
        Write-Host "For exact per-monitor refresh rates, use Advanced Display Settings." -ForegroundColor Yellow

        Write-Log "Display refresh info shown"
    }
    catch {
        Write-Host "Could not read display refresh info." -ForegroundColor Red
        Write-Log "Failed reading display refresh info: $($_.Exception.Message)" "ERROR"
    }

    Pause-App
}

function Open-AdvancedDisplaySettings {
    Start-Process "ms-settings:display-advanced"
    Write-Log "Opened advanced display settings"
}

function Set-AllDisplaysMaxRefresh {
    Show-Banner
    Write-Host "Set All Displays to Max Refresh Rate" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opening Windows Advanced Display Settings." -ForegroundColor Yellow
    Write-Host "Choose each monitor and select the highest refresh rate available." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This is safer than forcing a display mode through script." -ForegroundColor Yellow

    Open-AdvancedDisplaySettings
    Pause-App
}

function Show-DisplayTweaksMenu {
    while ($true) {
        Show-Banner
        Write-Host "Display Tweaks" -ForegroundColor Yellow
        Write-Host ""

        Write-Host "  1. Show Current Refresh Info"
        Write-Host "  2. Open Advanced Display Settings"
        Write-Host "  3. Set All Displays to Max Refresh Rate"
        Write-Host ""
        Write-Host "  0. Back"
        Write-Host ""

        $Choice = Read-Host "Select"

        switch ($Choice) {
            "1" { Get-DisplayRefreshInfo }
            "2" { Open-AdvancedDisplaySettings; Pause-App }
            "3" { Set-AllDisplaysMaxRefresh }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Pause-App }
        }
    }
}
