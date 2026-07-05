# =====================================================
# Power.ps1
# Power plan detection
# =====================================================

function Get-PowerPlan {
    try {
        $Output = powercfg /getactivescheme

        if ($Output -match '\((.+)\)') {
            return $Matches[1]
        }

        return "Unknown"
    }
    catch {
        return "Unknown"
    }
}

function Test-UltimatePerformance {
    try {
        $Plans = powercfg /list
        return ($Plans -match "Ultimate Performance")
    }
    catch {
        return $false
    }
}
