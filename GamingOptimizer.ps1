. "$PSScriptRoot\Modules\Core.ps1"
. "$PSScriptRoot\Modules\Display.ps1"
. "$PSScriptRoot\Modules\Hardware.ps1"
. "$PSScriptRoot\Modules\GameChecks.ps1"
. "$PSScriptRoot\Modules\Power.ps1"
. "$PSScriptRoot\Modules\Gaming.ps1"

while ($true) {

    Show-Banner

    Write-Host ""
    Write-Host "Dashboard" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  1  Analyze PC"
    Write-Host "  2  Gaming Tweaks"
    Write-Host "  0  Exit"
    Write-Host ""

    $Choice = Read-Host "Select an option"

    switch ($Choice) {

        "1" {
            Get-GamingAnalysis
        }

        "2" {

            Write-Host ""
            Write-Host "Gaming Tweaks coming soon." -ForegroundColor Yellow
            Pause-App

        }

        "0" {

            break

        }

        default {

            Write-Host ""
            Write-Host "Invalid option." -ForegroundColor Red
            Pause-App

        }

    }

}