# =====================================================
# OverlayDetection.ps1
# =====================================================

function Test-ProcessRunning {
    param([string[]]$Names)

    foreach ($Name in $Names) {
        if (Get-Process -Name $Name -ErrorAction SilentlyContinue) {
            return $true
        }
    }

    return $false
}

function Show-OverlayDetection {
    Show-Banner
    Write-Host "Overlay / Background App Detection" -ForegroundColor Yellow
    Write-Host ""

    $Items = @(
        @{ Name = "Discord"; Processes = @("Discord") },
        @{ Name = "Steam"; Processes = @("steam", "steamwebhelper") },
        @{ Name = "Xbox Game Bar"; Processes = @("GameBar", "GameBarFTServer", "XboxGameBar") },
        @{ Name = "NVIDIA Overlay"; Processes = @("NVIDIA Share", "nvsphelper64", "NVIDIA Web Helper") },
        @{ Name = "AMD Software"; Processes = @("AMDSoftware", "RadeonSoftware") },
        @{ Name = "Overwolf"; Processes = @("Overwolf") },
        @{ Name = "Medal"; Processes = @("Medal") },
        @{ Name = "OBS"; Processes = @("obs64", "obs32") },
        @{ Name = "MSI Afterburner / RTSS"; Processes = @("MSIAfterburner", "RTSS") }
    )

    foreach ($Item in $Items) {
        if (Test-ProcessRunning $Item.Processes) {
            Write-Status $Item.Name "Running" "Yellow"
        }
        else {
            Write-Status $Item.Name "Not Running" "Green"
        }
    }

    Write-Host ""
    Write-Host "Detection only. Nothing is closed automatically." -ForegroundColor Yellow
    Write-Log "Overlay detection completed"

    Pause-App
}
