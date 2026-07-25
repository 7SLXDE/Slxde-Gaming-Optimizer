# =====================================================
# RestorePoint.ps1
# =====================================================

function New-OptimizerRestorePoint {
    try {
        Write-Log "Creating restore point"

        Checkpoint-Computer `
            -Description "SLXDE OPTI Restore Point" `
            -RestorePointType "MODIFY_SETTINGS" `
            -ErrorAction Stop

        Write-Log "Restore point created successfully"
        return "Success"
    }
    catch {
        Write-Log "Restore point failed: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}
