# =====================================================
# AdvancedRegistry.ps1
# =====================================================

function Enable-NetworkThrottlingTweak {
    try {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -PropertyType DWord -Force | Out-Null
        Write-Log "NetworkThrottlingIndex set to ffffffff"
        return "Success"
    }
    catch {
        Write-Log "Failed NetworkThrottlingIndex tweak: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Enable-SystemResponsivenessTweak {
    try {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -PropertyType DWord -Force | Out-Null
        Write-Log "SystemResponsiveness set to 0"
        return "Success"
    }
    catch {
        Write-Log "Failed SystemResponsiveness tweak: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Restore-AdvancedRegistryTweaks {
    try {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -ErrorAction SilentlyContinue
        Write-Log "Advanced registry tweaks restored/removed"
        return "Success"
    }
    catch {
        Write-Log "Failed restoring advanced registry tweaks: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Show-AdvancedRegistryMenu {
    while ($true) {
        Show-Banner
        Write-Host "Advanced Registry Tweaks" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Optional. May help responsiveness on some systems, but not required." -ForegroundColor Yellow
        Write-Host ""

        Write-Host "  1. Set NetworkThrottlingIndex = ffffffff"
        Write-Host "  2. Set SystemResponsiveness = 0"
        Write-Host "  3. Apply Both"
        Write-Host "  4. Restore / Remove Both"
        Write-Host ""
        Write-Host "  0. Back"
        Write-Host ""

        $Choice = Read-Host "Select"

        switch ($Choice) {
            "1" { Write-Status "NetworkThrottlingIndex" (Enable-NetworkThrottlingTweak) "Green"; Pause-App }
            "2" { Write-Status "SystemResponsiveness" (Enable-SystemResponsivenessTweak) "Green"; Pause-App }
            "3" {
                Write-Status "NetworkThrottlingIndex" (Enable-NetworkThrottlingTweak) "Green"
                Write-Status "SystemResponsiveness" (Enable-SystemResponsivenessTweak) "Green"
                Pause-App
            }
            "4" { Write-Status "Restore Advanced Tweaks" (Restore-AdvancedRegistryTweaks) "Yellow"; Pause-App }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Pause-App }
        }
    }
}
