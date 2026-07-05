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
        [string]$PowerPlan,
        [string]$MouseAcceleration
    )

    $Score = 0
    $Total = 7

    if ($GameMode -eq "Enabled") { $Score++ }
    if ($GameDVR -eq "Disabled") { $Score++ }
    if ($XboxCapture -eq "Disabled") { $Score++ }
    if ($HAGS -eq "Enabled") { $Score++ }
    if ($WindowedOptimizations -eq "Enabled") { $Score++ }
    if ($PowerPlan -match "Ultimate|High|HDOptimised") { $Score++ }
    if ($MouseAcceleration -eq "Disabled") { $Score++ }

    return [math]::Round(($Score / $Total) * 100)
}

function Get-GamingAnalysis {
    Write-Log "Starting gaming analysis"
    Show-Banner

    Write-Section "System"

    if (Test-Administrator) { Write-Status "Administrator" "YES" "Green" }
    else { Write-Status "Administrator" "NO" "Red" }

    Get-HardwareInfo

    Write-Section "Gaming Checks"

    $GameMode = Get-GameModeStatus
    $GameDVR = Get-GameDVRStatus
    $XboxCapture = Get-XboxCaptureStatus
    $HAGS = Get-HAGSStatus
    $WindowedOptimizations = Get-WindowedOptimizationsStatus
    $PowerPlan = Get-PowerPlan
    $UltimateAvailable = Test-UltimatePerformance
    $MouseAcceleration = Get-MouseAccelerationStatus

    if ($GameMode -eq "Enabled") { Write-Status "Game Mode" $GameMode "Green" } else { Write-Status "Game Mode" $GameMode "Yellow" }
    if ($GameDVR -eq "Disabled") { Write-Status "Game DVR" $GameDVR "Green" } else { Write-Status "Game DVR" $GameDVR "Yellow" }
    if ($XboxCapture -eq "Disabled") { Write-Status "Xbox Capture" $XboxCapture "Green" } else { Write-Status "Xbox Capture" $XboxCapture "Yellow" }
    if ($HAGS -eq "Enabled") { Write-Status "HAGS" $HAGS "Green" } else { Write-Status "HAGS" $HAGS "Yellow" }
    if ($WindowedOptimizations -eq "Enabled") { Write-Status "Windowed Optimizations" $WindowedOptimizations "Green" } else { Write-Status "Windowed Optimizations" $WindowedOptimizations "Yellow" }
    if ($PowerPlan -match "Ultimate|High|HDOptimised") { Write-Status "Power Plan" $PowerPlan "Green" } else { Write-Status "Power Plan" $PowerPlan "Yellow" }
    if ($UltimateAvailable) { Write-Status "Ultimate Plan Available" "YES" "Green" } else { Write-Status "Ultimate Plan Available" "NO" "Yellow" }
    if ($MouseAcceleration -eq "Disabled") { Write-Status "Mouse Acceleration" $MouseAcceleration "Green" } else { Write-Status "Mouse Acceleration" $MouseAcceleration "Yellow" }

    $Score = Get-GamingScore -GameMode $GameMode -GameDVR $GameDVR -XboxCapture $XboxCapture -HAGS $HAGS -WindowedOptimizations $WindowedOptimizations -PowerPlan $PowerPlan -MouseAcceleration $MouseAcceleration

    Write-Section "Score"
    Write-Status "Gaming Score" "$Score / 100" "Cyan"

    Write-Log "Gaming analysis completed. Score: $Score/100"
    Pause-App
}
