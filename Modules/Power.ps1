# =====================================================
# Power.ps1
# =====================================================

function Get-PowerPlan {
    try {
        $Output = powercfg /getactivescheme
        if ($Output -match '\((.+)\)') { return $Matches[1] }
        return "Unknown"
    } catch { return "Unknown" }
}

function Test-UltimatePerformance {
    try {
        $Plans = powercfg /list
        if ($Plans -match "Ultimate Performance") { return $true }
        return $false
    } catch { return $false }
}
