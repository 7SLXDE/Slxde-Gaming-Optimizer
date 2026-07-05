# =====================================================
# Gaming.ps1
# =====================================================

function Get-GamingScore {
    param(
        [string]$GameMode,
        [string]$GameDVR,
        [string]$XboxCapture,
        [string]$HAGS,
        [string]$WindowedOptimizations,
        [string]$PowerPlan
    )

    $Score = 0

    if ($GameMode -eq "Enabled") { $Score += 20 }
    if ($GameDVR -eq "Disabled") { $Score += 20 }
    if ($XboxCapture -eq "Disabled") { $Score += 15 }
    if ($HAGS -eq "Enabled") { $Score += 15 }
    if ($WindowedOptimizations -eq "Enabled") { $Score += 10 }
    if ($PowerPlan -match "Ultimate|High|HDOptimised|Performance") { $Score += 20 }
    elseif ($PowerPlan -match "Balanced") { $Score += 10 }

    if ($Score -gt 100) { $Score = 100 }
    return $Score
}

function Get-GamingAnalysis {
    Write-Log "Starting gaming analysis"

    Show-Banner

    Show-Section "System"

    if (Test-Administrator) {
        Write-Status "Administrator" "YES" "Green"
    }
    else {
        Write-Status "Administrator" "NO" "Red"
    }

    Get-HardwareInfo

    Show-Section "Gaming Checks"

    $GameMode = Get-GameModeStatus
    $GameDVR = Get-GameDVRStatus
    $XboxCapture = Get-XboxCaptureStatus
    $HAGS = Get-HAGSStatus
    $WindowedOptimizations = Get-WindowedOptimizationsStatus
    $PowerPlan = Get-PowerPlan
    $UltimateAvailable = Test-UltimatePerformance

    if ($GameMode -eq "Enabled") { Write-Status "Game Mode" $GameMode "Green" } else { Write-Status "Game Mode" $GameMode "Yellow" }
    if ($GameDVR -eq "Disabled") { Write-Status "Game DVR" $GameDVR "Green" } else { Write-Status "Game DVR" $GameDVR "Yellow" }
    if ($XboxCapture -eq "Disabled") { Write-Status "Xbox Capture" $XboxCapture "Green" } else { Write-Status "Xbox Capture" $XboxCapture "Yellow" }
    if ($HAGS -eq "Enabled") { Write-Status "HAGS" $HAGS "Green" } else { Write-Status "HAGS" $HAGS "Yellow" }
    if ($WindowedOptimizations -eq "Enabled") { Write-Status "Windowed Optimizations" $WindowedOptimizations "Green" } else { Write-Status "Windowed Optimizations" $WindowedOptimizations "Yellow" }

    if ($PowerPlan -match "Ultimate|High|HDOptimised|Performance") {
        Write-Status "Power Plan" $PowerPlan "Green"
    }
    elseif ($PowerPlan -match "Balanced") {
        Write-Status "Power Plan" $PowerPlan "Yellow"
    }
    else {
        Write-Status "Power Plan" $PowerPlan "Yellow"
    }

    if ($UltimateAvailable) {
        Write-Status "Ultimate Plan Available" "YES" "Green"
    }
    else {
        Write-Status "Ultimate Plan Available" "NO" "Yellow"
    }

    $Score = Get-GamingScore `
        -GameMode $GameMode `
        -GameDVR $GameDVR `
        -XboxCapture $XboxCapture `
        -HAGS $HAGS `
        -WindowedOptimizations $WindowedOptimizations `
        -PowerPlan $PowerPlan

    Show-Section "Score"
    Write-Status "Gaming Score" "$Score / 100" "Cyan"

    Write-Log "Gaming analysis completed. Score: $Score"

    Pause-App
}
