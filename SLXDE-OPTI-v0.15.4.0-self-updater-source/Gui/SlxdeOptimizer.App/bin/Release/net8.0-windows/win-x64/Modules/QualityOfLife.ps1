# =====================================================
# QualityOfLife.ps1
# =====================================================

function Show-QualityOfLifeMenu {
    while ($true) {
        Show-Banner
        Write-Host "Quality of Life Tweaks" -ForegroundColor Yellow
        Write-Host ""

        Write-Host "  1. Enable Right-Click End Task"
        Write-Host "  2. Set Explorer to This PC"
        Write-Host "  3. Reduce Mouse Hover Time"
        Write-Host "  4. Disable Startup Apps Delay"
        Write-Host ""
        Write-Host "  A. Apply All Quality of Life Tweaks"
        Write-Host "  0. Back"
        Write-Host ""

        $Choice = Read-Host "Select"

        switch ($Choice.ToUpper()) {
            "1" { Write-Status "Right-Click End Task" (Enable-RightClickEndTask) "Green"; Pause-App }
            "2" { Write-Status "Explorer This PC" (Set-ExplorerThisPC) "Green"; Pause-App }
            "3" { Write-Status "Mouse Hover Time" (Reduce-MouseHoverTime) "Green"; Pause-App }
            "4" { Write-Status "Startup Delay" (Disable-StartupDelay) "Green"; Pause-App }

            "A" {
                Show-Banner
                Write-Host "Applying quality of life tweaks..." -ForegroundColor Yellow
                Write-Host ""

                Write-Status "Right-Click End Task" (Enable-RightClickEndTask) "Green"
                Write-Status "Explorer This PC" (Set-ExplorerThisPC) "Green"
                Write-Status "Mouse Hover Time" (Reduce-MouseHoverTime) "Green"
                Write-Status "Startup Delay" (Disable-StartupDelay) "Green"

                Pause-App
            }

            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Pause-App }
        }
    }
}
