# =====================================================
# Gaming.ps1
# =====================================================

function Get-GamingScore {
    param(
        [string]$GameMode,
        [string]$GameDVR,
        [string]$XboxCapture,
        [string]$HAGS,
        [string]$WindowedOpt,
        [string]$PowerPlan
    )

    $Score = 0
    $Total = 5

    if ($GameMode -eq "Enabled") { $Score++ }
    if ($GameDVR -eq "Disabled") { $Score++ }
    if ($XboxCapture -eq "Disabled") { $Score++ }
    if ($HAGS -eq "Enabled") { $Score++ }
    if ($WindowedOpt -eq "Enabled") { $Score++ }

    # Power plan is informational because custom plans vary.
    $Percent = [math]::Round(($Score / $Total) * 100)
    return $Percent
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

    $GameMode  = Get-GameModeStatus
    $GameDVR   = Get-GameDVRStatus
    $Xbox      = Get-XboxCaptureStatus
    $HAGS      = Get-HAGSStatus
    $WinOpt    = Get-WindowedOptimizationsStatus
    $PowerPlan = Get-PowerPlan
    $Ultimate  = Test-UltimatePerformance

    switch ($GameMode) {
        "Enabled"  { Write-Status "Game Mode" $GameMode "Green" }
        "Disabled" { Write-Status "Game Mode" $GameMode "Red" }
        default    { Write-Status "Game Mode" $GameMode "Yellow" }
    }

    switch ($GameDVR) {
        "Disabled" { Write-Status "Game DVR" $GameDVR "Green" }
        "Enabled"  { Write-Status "Game DVR" $GameDVR "Yellow" }
        default    { Write-Status "Game DVR" $GameDVR "Yellow" }
    }

    switch ($Xbox) {
        "Disabled" { Write-Status "Xbox Capture" $Xbox "Green" }
        "Enabled"  { Write-Status "Xbox Capture" $Xbox "Yellow" }
        default    { Write-Status "Xbox Capture" $Xbox "Yellow" }
    }

    switch ($HAGS) {
        "Enabled"  { Write-Status "HAGS" $HAGS "Green" }
        "Disabled" { Write-Status "HAGS" $HAGS "Red" }
        default    { Write-Status "HAGS" $HAGS "Yellow" }
    }

    switch ($WinOpt) {
        "Enabled"  { Write-Status "Windowed Optimizations" $WinOpt "Green" }
        "Disabled" { Write-Status "Windowed Optimizations" $WinOpt "Yellow" }
        default    { Write-Status "Windowed Optimizations" $WinOpt "Yellow" }
    }

    Write-Status "Power Plan" $PowerPlan "Green"

    if ($Ultimate) {
        Write-Status "Ultimate Plan Available" "YES" "Green"
    }
    else {
        Write-Status "Ultimate Plan Available" "NO" "Yellow"
    }

    Show-Section "Score"

    $Score = Get-GamingScore $GameMode $GameDVR $Xbox $HAGS $WinOpt $PowerPlan
    Write-Status "Gaming Score" "$Score / 100" "Cyan"

    Write-Log "Gaming analysis completed. Score: $Score/100"

    Pause-App
}
