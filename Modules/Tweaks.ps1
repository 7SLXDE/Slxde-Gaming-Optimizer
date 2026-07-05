# =====================================================
# Tweaks.ps1
# Safe optimization actions
# =====================================================

function Disable-GameDVR {

    try {

        Write-Log "Disabling Game DVR..."

        New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
        New-ItemProperty `
            -Path "HKCU:\System\GameConfigStore" `
            -Name "GameDVR_Enabled" `
            -Value 0 `
            -PropertyType DWord `
            -Force | Out-Null

        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null
        New-ItemProperty `
            -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" `
            -Name "AppCaptureEnabled" `
            -Value 0 `
            -PropertyType DWord `
            -Force | Out-Null

        Write-Log "Game DVR disabled successfully."
        return "Success"

    }
    catch {

        Write-Log "Failed to disable Game DVR: $($_.Exception.Message)" "ERROR"
        return "Failed"

    }

}