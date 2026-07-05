# =====================================================
# Slxde Gaming Optimizer
# v0.7.8.6
# =====================================================

. "$PSScriptRoot\Modules\Core.ps1"
. "$PSScriptRoot\Modules\Display.ps1"
. "$PSScriptRoot\Modules\Logger.ps1"
. "$PSScriptRoot\Modules\Hardware.ps1"
. "$PSScriptRoot\Modules\GameChecks.ps1"
. "$PSScriptRoot\Modules\Power.ps1"
. "$PSScriptRoot\Modules\Gaming.ps1"
. "$PSScriptRoot\Modules\RestorePoint.ps1"
. "$PSScriptRoot\Modules\Tweaks.ps1"
. "$PSScriptRoot\Modules\WindowsTweaks.ps1"
. "$PSScriptRoot\Modules\Cleanup.ps1"
. "$PSScriptRoot\Modules\QualityOfLife.ps1"
. "$PSScriptRoot\Modules\Network.ps1"
. "$PSScriptRoot\Modules\Specs.ps1"
. "$PSScriptRoot\Modules\DisplayTweaks.ps1"
. "$PSScriptRoot\Modules\GPUTools.ps1"
. "$PSScriptRoot\Modules\OverlayDetection.ps1"
. "$PSScriptRoot\Modules\AdvancedRegistry.ps1"

Write-Log "Application Started"

while ($true) {

    Show-Banner

    Write-Host ""
    Write-Host "Dashboard" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  1. Analyze PC"
    Write-Host "  2. Gaming Tweaks"
    Write-Host "  3. Windows Tweaks"
    Write-Host "  4. Network Tweaks"
    Write-Host "  5. Cleanup / Health Check"
    Write-Host "  6. Quality of Life Tweaks"
    Write-Host "  7. Display Tweaks"
    Write-Host "  8. GPU Tools"
    Write-Host "  9. Overlay Detection"
    Write-Host " 10. Advanced Registry Tweaks"
    Write-Host " 11. PC Specs"
    Write-Host " 12. View Latest Log"
    Write-Host ""
    Write-Host "  0. Exit"
    Write-Host ""

    $Choice = Read-Host "Select"

    switch ($Choice) {

        "1" { Get-GamingAnalysis }
        "2" { Show-GamingTweaksMenu }
        "3" { Show-WindowsTweaksMenu }
        "4" { Show-NetworkMenu }
        "5" { Show-CleanupMenu }
        "6" { Show-QualityOfLifeMenu }
        "7" { Show-DisplayTweaksMenu }
        "8" { Show-GPUToolsMenu }
        "9" { Show-OverlayDetection }
        "10" { Show-AdvancedRegistryMenu }
        "11" { Show-PCSpecs }
        "12" { Show-LatestLog }

        "0" {
            Write-Log "Application Closed"
            break
        }

        default {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Pause-App
        }
    }
}
