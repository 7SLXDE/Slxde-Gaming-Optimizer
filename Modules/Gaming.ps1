function Get-GamingAnalysis {

    Show-Banner

    Write-Host "Gaming Analysis" -ForegroundColor Yellow
    Write-Host ""

    if (Test-Administrator) {
        Write-Status "Administrator" "YES" "Green"
    }
    else {
        Write-Status "Administrator" "NO" "Red"
    }

    Get-HardwareInfo

    Write-Host ""
    Write-Host "Gaming Checks" -ForegroundColor Yellow
    Write-Host ""

    $GameMode = Get-GameModeStatus
    $GameDVR  = Get-GameDVRStatus

    if ($GameMode -eq "Enabled") {
        Write-Status "Game Mode" $GameMode "Green"
    }
    elseif ($GameMode -eq "Disabled") {
        Write-Status "Game Mode" $GameMode "Red"
    }
    else {
        Write-Status "Game Mode" $GameMode "Yellow"
    }

    if ($GameDVR -eq "Enabled") {
        Write-Status "Game DVR" $GameDVR "Yellow"
    }
    elseif ($GameDVR -eq "Disabled") {
        Write-Status "Game DVR" $GameDVR "Green"
    }
    else {
        Write-Status "Game DVR" $GameDVR "Yellow"
    }

    Write-Status "Xbox Game Bar" "Coming Soon" "Yellow"
    Write-Status "HAGS" "Coming Soon" "Yellow"
    $PowerPlan = Get-PowerPlan

if ($PowerPlan -eq "Ultimate Performance") {

    Write-Status "Power Plan" $PowerPlan "Green"

}
elseif ($PowerPlan -eq "High performance") {

    Write-Status "Power Plan" $PowerPlan "Green"

}
elseif ($PowerPlan -eq "Balanced") {

    Write-Status "Power Plan" $PowerPlan "Yellow"

}
else {

    Write-Status "Power Plan" $PowerPlan "Yellow"

}

    Pause-App
}