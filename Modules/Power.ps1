# =====================================================
# Power.ps1
# Power plan tools
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

function Get-SlxdePowerPlanGuid {
    try {
        $Plans = powercfg /list
        $Line = ($Plans | Select-String "SLXDE PowerPlan" | Select-Object -First 1).Line

        if ($Line -match '([a-fA-F0-9\-]{36})') {
            return $Matches[1]
        }

        return $null
    }
    catch {
        return $null
    }
}

function Set-SlxdePowerPlanSettings {
    param(
        [string]$Guid
    )

    try {
        if (!$Guid) { return "Failed" }

        # Make the plan active first so /change targets the correct plan.
        powercfg /setactive $Guid | Out-Null

        # Safe, visible powercfg shortcuts.
        powercfg /change monitor-timeout-ac 0 | Out-Null
        powercfg /change monitor-timeout-dc 0 | Out-Null
        powercfg /change standby-timeout-ac 0 | Out-Null
        powercfg /change standby-timeout-dc 0 | Out-Null
        powercfg /change hibernate-timeout-ac 0 | Out-Null
        powercfg /change hibernate-timeout-dc 0 | Out-Null
        powercfg /change disk-timeout-ac 0 | Out-Null
        powercfg /change disk-timeout-dc 0 | Out-Null

        # Deeper settings. Output is suppressed because some builds hide/rename aliases.
        cmd /c "powercfg -setacvalueindex $Guid SUB_SLEEP RTCWAKE 0 >nul 2>nul"
        cmd /c "powercfg -setdcvalueindex $Guid SUB_SLEEP RTCWAKE 0 >nul 2>nul"
        cmd /c "powercfg -setacvalueindex $Guid SUB_SLEEP HYBRIDSLEEP 0 >nul 2>nul"
        cmd /c "powercfg -setdcvalueindex $Guid SUB_SLEEP HYBRIDSLEEP 0 >nul 2>nul"
        cmd /c "powercfg -setacvalueindex $Guid SUB_USB USBSELECTIVE 0 >nul 2>nul"
        cmd /c "powercfg -setdcvalueindex $Guid SUB_USB USBSELECTIVE 0 >nul 2>nul"
        cmd /c "powercfg -setacvalueindex $Guid SUB_PCIEXPRESS ASPM 0 >nul 2>nul"
        cmd /c "powercfg -setdcvalueindex $Guid SUB_PCIEXPRESS ASPM 0 >nul 2>nul"

        powercfg /setactive $Guid | Out-Null

        Write-Log "SLXDE power plan settings applied"
        return "Success"
    }
    catch {
        Write-Log "Failed to apply SLXDE power plan settings: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function New-SlxdePowerPlan {
    if (!(Assert-Admin)) { return "Failed" }

    if (Get-Command Confirm-LaptopPerformanceTweaks -ErrorAction SilentlyContinue) {
        if (!(Confirm-LaptopPerformanceTweaks)) { return "Cancelled" }
    }

    try {
        Write-Log "Creating/loading SLXDE power plan"

        $ExistingGuid = Get-SlxdePowerPlanGuid

        if ($ExistingGuid) {
            powercfg /setactive $ExistingGuid | Out-Null
            Set-SlxdePowerPlanSettings -Guid $ExistingGuid | Out-Null
            Write-Log "Existing SLXDE power plan activated and optimized"
            return "Success"
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

        Set-SlxdePowerPlanSettings -Guid $Guid | Out-Null

        Write-Log "SLXDE power plan created, optimized and activated"
        return "Success"
    }
    catch {
        Write-Log "Failed to create SLXDE power plan: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Set-BalancedPowerPlan {
    if (!(Assert-Admin)) { return "Failed" }

    try {
        powercfg /setactive SCHEME_BALANCED | Out-Null

        # Balanced laptop-friendly defaults.
        # AC: display 15 min, sleep never for desktop/gaming use.
        # DC: display 5 min, sleep 15 min for battery safety.
        powercfg /change monitor-timeout-ac 15 | Out-Null
        powercfg /change standby-timeout-ac 0 | Out-Null
        powercfg /change hibernate-timeout-ac 0 | Out-Null

        powercfg /change monitor-timeout-dc 5 | Out-Null
        powercfg /change standby-timeout-dc 15 | Out-Null
        powercfg /change hibernate-timeout-dc 30 | Out-Null

        cmd /c "powercfg -setacvalueindex SCHEME_BALANCED SUB_SLEEP RTCWAKE 0 >nul 2>nul"
        cmd /c "powercfg -setdcvalueindex SCHEME_BALANCED SUB_SLEEP RTCWAKE 0 >nul 2>nul"
        cmd /c "powercfg -setacvalueindex SCHEME_BALANCED SUB_USB USBSELECTIVE 1 >nul 2>nul"
        cmd /c "powercfg -setdcvalueindex SCHEME_BALANCED SUB_USB USBSELECTIVE 1 >nul 2>nul"

        powercfg /setactive SCHEME_BALANCED | Out-Null

        Write-Log "Balanced power plan activated with laptop-friendly defaults"
        return "Success"
    }
    catch {
        Write-Log "Failed to activate Balanced power plan: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}
