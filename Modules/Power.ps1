# =====================================================
# Power.ps1
# =====================================================

function Get-PowerPlan {
    try {
        $Output = powercfg /getactivescheme
        if ($Output -match '\((.+)\)') { return $Matches[1] }
        return "Unknown"
    }
    catch { return "Unknown" }
}

function Test-UltimatePerformance {
    try {
        $Plans = powercfg /list
        return ($Plans -match "Ultimate Performance")
    }
    catch { return $false }
}

function New-SlxdePowerPlan {
    if (!(Assert-Admin)) { return "Failed" }

    try {
        Write-Log "Creating SLXDE power plan"

        $DuplicateOutput = powercfg -duplicatescheme SCHEME_MIN
        $Guid = $null

        if ($DuplicateOutput -match '([a-fA-F0-9\-]{36})') {
            $Guid = $Matches[1]
        }

        if (!$Guid) { return "Failed" }

        powercfg -changename $Guid "SLXDE PowerPlan" "Created by Slxde Gaming Optimizer"
        powercfg /setactive $Guid

        # Safe power tweaks
        powercfg -setacvalueindex $Guid SUB_PROCESSOR PROCTHROTTLEMIN 100 | Out-Null
        powercfg -setacvalueindex $Guid SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null
        powercfg -setacvalueindex $Guid SUB_USB USBSELECTIVE 0 | Out-Null
        powercfg /setactive $Guid | Out-Null

        Write-Log "SLXDE power plan created and activated"
        return "Success"
    }
    catch {
        Write-Log "Failed to create SLXDE power plan: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Set-BalancedPowerPlan {
    try {
        powercfg /setactive SCHEME_BALANCED | Out-Null
        Write-Log "Balanced power plan activated"
        return "Success"
    }
    catch {
        Write-Log "Failed to activate Balanced power plan: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}
