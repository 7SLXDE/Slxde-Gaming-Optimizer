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

        $ExistingPlans = powercfg /list

        if ($ExistingPlans -match "SLXDE PowerPlan") {
            $MatchLine = ($ExistingPlans | Select-String "SLXDE PowerPlan" | Select-Object -First 1).Line

            if ($MatchLine -match '([a-fA-F0-9\-]{36})') {
                $ExistingGuid = $Matches[1]
                powercfg /setactive $ExistingGuid | Out-Null
                Write-Log "Existing SLXDE power plan activated"
                return "Success"
            }
        }

        $DuplicateOutput = powercfg -duplicatescheme SCHEME_MIN
        $Guid = $null

        if ($DuplicateOutput -match '([a-fA-F0-9\-]{36})') {
            $Guid = $Matches[1]
        }

        if (!$Guid) {
            Write-Log "Could not create SLXDE power plan GUID" "ERROR"
            return "Failed"
        }

        powercfg -changename $Guid "SLXDE PowerPlan" "Created by Slxde Gaming Optimizer" | Out-Null
        powercfg /setactive $Guid | Out-Null

        # Safe USB selective suspend change. Other processor-specific settings vary by Windows build,
        # so they are not forced here to avoid invalid parameter output.
        powercfg /change monitor-timeout-ac 0 | Out-Null
        powercfg /change standby-timeout-ac 0 | Out-Null

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
