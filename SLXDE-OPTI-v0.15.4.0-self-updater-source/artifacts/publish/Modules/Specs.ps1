# =====================================================
# Specs.ps1
# =====================================================

function Show-PCSpecs {
    Show-Banner
    Show-Section "PC Specs"
    Get-HardwareInfo

    Show-Section "Current Optimisation Status"
    Write-Status "Power Plan" (Get-PowerPlan) "Green"
    Write-Status "Game Mode" (Get-GameModeStatus) "Green"
    Write-Status "Game DVR" (Get-GameDVRStatus) "Green"
    Write-Status "Xbox Capture" (Get-XboxCaptureStatus) "Green"
    Write-Status "HAGS" (Get-HAGSStatus) "Green"
    Write-Status "Windowed Optimisations" (Get-WindowedOptimizationsStatus) "Green"

    Pause-App
}
