# =====================================================
# Slxde Gaming Optimizer
# v0.6.1
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

Write-Log "Application started"

while ($true) {

    Show-Banner

    Write-Host ""
    Write-Host "Dashboard" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  1. Analyze PC"
    Write-Host "  2. Create Restore Point"
    Write-Host "  3. Apply Safe Gaming Tweaks"
    Write-Host "  4. View Latest Log"
    Write-Host ""
    Write-Host "  0. Exit"
    Write-Host ""

    $Choice = Read-Host "Select"

    switch ($Choice) {

        "1" {
            Write-Log "Analyze PC selected"
            Get-GamingAnalysis
        }

        "2" {
            Write-Log "Create Restore Point selected"
            Show-Banner
            Write-Host ""
            Write-Host "Creating restore point..." -ForegroundColor Yellow
            Write-Host ""
            $Result = New-OptimizerRestorePoint
            if ($Result -eq "Success") {
                Write-Host "Restore point created successfully." -ForegroundColor Green
            } else {
                Write-Host "Restore point failed." -ForegroundColor Red
                Write-Host "System Protection may be disabled on this drive." -ForegroundColor Yellow
            }
            Pause-App
        }

        "3" {
            Write-Log "Apply Safe Gaming Tweaks selected"
            Invoke-SafeGamingTweaks
        }

        "4" {
            Show-LatestLog
        }

        "0" {
            Write-Log "Application closed"
            break
        }

        default {
            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Pause-App
        }
    }
}
