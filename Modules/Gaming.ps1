# =====================================================
# Gaming.ps1
# Gaming analysis screen
# =====================================================

function Add-Score {
    param(
        [int]$Current,
        [string]$Status,
        [string]$GoodValue
    )

    if ($Status -eq $GoodValue) {
        return ($Current + 1)
    }

    return $Current
}

function Get-GamingAnalysis {
    Write-Log "Starting analyzer"
    Show-Banner

    Show-Section "System"

    if (Test-Administrator) {
        Write-Status "Administrator" "YES" "Green"
    }
    else {
        Write-Status "Administrator" "NO" "Yellow"
    }

    Get-HardwareInfo

    Show-Section "Gaming Checks"

    $Score = 0
    $Total = 7

    $GameMode = Get-GameModeStatus
    $GameDVR = Get-GameDVRStatus
    $GameBar = Get-XboxGameBarStatus
    $HAGS = Get-HAGSStatus
    $VRR = Get-VariableRefreshRateStatus
    $WindowedOpt = Get-WindowedOptimizationsStatus
    $PowerPlan = Get-PowerPlan
    $UltimateInstalled = Test-UltimatePerformance

    switch ($GameMode) {
        "Enabled" { Write-Status "Game Mode" $GameMode "Green"; $Score++ }
        "Disabled" { Write-Status "Game Mode" $GameMode "Red" }
        default { Write-Status "Game Mode" $GameMode "Yellow" }
    }

    switch ($GameDVR) {
        "Disabled" { Write-Status "Game DVR" $GameDVR "Green"; $Score++ }
        "Enabled" { Write-Status "Game DVR" $GameDVR "Yellow" }
        default { Write-Status "Game DVR" $GameDVR "Yellow" }
    }

    switch ($GameBar) {
        "Disabled" { Write-Status "Xbox Capture" $GameBar "Green"; $Score++ }
        "Enabled" { Write-Status "Xbox Capture" $GameBar "Yellow" }
        default { Write-Status "Xbox Capture" $GameBar "Yellow" }
    }

    switch ($HAGS) {
        "Enabled" { Write-Status "HAGS" $HAGS "Green"; $Score++ }
        "Disabled" { Write-Status "HAGS" $HAGS "Red" }
        "Default" { Write-Status "HAGS" $HAGS "Yellow" }
        default { Write-Status "HAGS" $HAGS "Yellow" }
    }

    switch ($VRR) {
        "Enabled" { Write-Status "Variable Refresh Rate" $VRR "Green"; $Score++ }
        "Disabled" { Write-Status "Variable Refresh Rate" $VRR "Yellow" }
        default { Write-Status "Variable Refresh Rate" $VRR "Yellow" }
    }

    switch ($WindowedOpt) {
        "Enabled" { Write-Status "Windowed Optimizations" $WindowedOpt "Green"; $Score++ }
        "Disabled" { Write-Status "Windowed Optimizations" $WindowedOpt "Yellow" }
        default { Write-Status "Windowed Optimizations" $WindowedOpt "Yellow" }
    }

    if ($PowerPlan -match "Ultimate|High|HDOptimised|Performance") {
        Write-Status "Power Plan" $PowerPlan "Green"
        $Score++
    }
    elseif ($PowerPlan -match "Balanced") {
        Write-Status "Power Plan" $PowerPlan "Yellow"
    }
    else {
        Write-Status "Power Plan" $PowerPlan "Yellow"
    }

    if ($UltimateInstalled) {
        Write-Status "Ultimate Plan Available" "YES" "Green"
    }
    else {
        Write-Status "Ultimate Plan Available" "NO" "Yellow"
    }

    Show-Section "Score"

    $Percent = [math]::Round(($Score / $Total) * 100)
    Write-Status "Gaming Score" "$Percent / 100" "Cyan"

    Write-Log "Analyzer complete. Score: $Percent/100"
    Pause-App
}
