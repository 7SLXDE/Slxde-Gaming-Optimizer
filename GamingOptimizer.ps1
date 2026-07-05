# =====================================================
# Slxde Gaming Optimizer v0.5.2
# Main Launcher
# =====================================================

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\Modules\Core.ps1"
. "$PSScriptRoot\Modules\Display.ps1"
. "$PSScriptRoot\Modules\Logger.ps1"
. "$PSScriptRoot\Modules\Hardware.ps1"
. "$PSScriptRoot\Modules\GameChecks.ps1"
. "$PSScriptRoot\Modules\Power.ps1"
. "$PSScriptRoot\Modules\Gaming.ps1"

Initialize-Logger
Write-Log "Application started"

while ($true) {
    Show-Banner

    Write-Host "Dashboard" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Analyze PC"
    Write-Host "  2. Gaming Tweaks      (Coming Soon)"
    Write-Host "  3. Windows Tweaks     (Coming Soon)"
    Write-Host "  4. Network Tweaks     (Coming Soon)"
    Write-Host "  5. Cleanup            (Coming Soon)"
    Write-Host "  6. Repair             (Coming Soon)"
    Write-Host "  7. Restore            (Coming Soon)"
    Write-Host ""
    Write-Host "  0. Exit"
    Write-Host ""

    $Choice = Read-Host "Select"

    switch ($Choice) {
        "1" {
            Write-Log "Analyze PC selected"
            Get-GamingAnalysis
        }
        "0" {
            Write-Log "Application closed"
            break
        }
        default {
            Show-Warning "Feature not implemented yet."
            Pause-App
        }
    }
}
