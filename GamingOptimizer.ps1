# =====================================================
# Slxde Gaming Optimizer
# v0.7.2
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

Write-Log "Application Started"

while ($true) {

    Show-Banner

    Write-Host ""
    Write-Host "Dashboard" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  1. Analyze PC"
    Write-Host "  2. Apply Safe Gaming Tweaks"
    Write-Host "  3. Restore / Undo Gaming Tweaks"
    Write-Host ""
    Write-Host "  4. Windows Tweaks"
    Write-Host "  5. Cleanup / Health Check"
    Write-Host "  6. Quality of Life Tweaks"
    Write-Host "  7. Network Tweaks"
    Write-Host "  8. PC Specs"
    Write-Host "  9. View Latest Log"
    Write-Host ""
    Write-Host "  0. Exit"
    Write-Host ""

    $Choice = Read-Host "Select"

    switch ($Choice) {

        "1" { Get-GamingAnalysis }
        "2" { Invoke-SafeGamingTweaks }
        "3" { Restore-GamingTweaks }
        "4" { Show-WindowsTweaksMenu }
        "5" { Show-CleanupMenu }
        "6" { Show-QualityOfLifeMenu }
        "7" { Show-NetworkMenu }
        "8" { Show-PCSpecs }
        "9" { Show-LatestLog }

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
