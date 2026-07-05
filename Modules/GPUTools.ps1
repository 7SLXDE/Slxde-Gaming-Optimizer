# =====================================================
# GPUTools.ps1
# =====================================================

function Open-GPUSettings {
    Start-Process "ms-settings:display-advancedgraphics"
    Write-Log "Opened Windows graphics settings"
    return "Opened"
}

function Open-NvidiaControlPanel {
    try {
        Start-Process "nvcplui.exe" -ErrorAction Stop
        Write-Log "Opened NVIDIA Control Panel"
        return "Opened"
    }
    catch {
        Write-Log "NVIDIA Control Panel not found"
        return "Not Found"
    }
}

function Open-AMDAdrenalin {
    try {
        Start-Process "AMDSoftware.exe" -ErrorAction Stop
        Write-Log "Opened AMD Adrenalin"
        return "Opened"
    }
    catch {
        try {
            Start-Process "RadeonSoftware.exe" -ErrorAction Stop
            Write-Log "Opened AMD Radeon Software"
            return "Opened"
        }
        catch {
            Write-Log "AMD software not found"
            return "Not Found"
        }
    }
}

function Add-GameHighPerformancePrompt {
    Show-Banner
    Write-Host "Add Game EXE to High Performance GPU Preference" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opening Windows Graphics Settings." -ForegroundColor Yellow
    Write-Host "Browse to your game .exe and set GPU preference to High Performance." -ForegroundColor Yellow
    Write-Host ""

    Open-GPUSettings | Out-Null
    Pause-App
}

function Show-GPUToolsMenu {
    while ($true) {
        Show-Banner
        Write-Host "GPU Tools" -ForegroundColor Yellow
        Write-Host ""

        Write-Host "  1. Open Windows Graphics Settings"
        Write-Host "  2. Open NVIDIA Control Panel"
        Write-Host "  3. Open AMD Adrenalin"
        Write-Host "  4. Add Game EXE to High Performance GPU List"
        Write-Host ""
        Write-Host "  0. Back"
        Write-Host ""

        $Choice = Read-Host "Select"

        switch ($Choice) {
            "1" { Write-Status "Graphics Settings" (Open-GPUSettings) "Yellow"; Pause-App }
            "2" { Write-Status "NVIDIA Control Panel" (Open-NvidiaControlPanel) "Yellow"; Pause-App }
            "3" { Write-Status "AMD Adrenalin" (Open-AMDAdrenalin) "Yellow"; Pause-App }
            "4" { Add-GameHighPerformancePrompt }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Pause-App }
        }
    }
}
