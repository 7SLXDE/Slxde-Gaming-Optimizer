# =====================================================
# Network.ps1
# =====================================================

function Reset-NetworkStack {
    if (!(Assert-Admin)) { return "Failed" }

    try {
        ipconfig /flushdns | Out-Null
        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null

        Write-Log "Network stack reset"
        return "Success"
    }
    catch {
        Write-Log "Failed network reset: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Disable-NICPowerSaving {
    if (!(Assert-Admin)) { return "Failed" }

    try {
        $Adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue

        foreach ($Adapter in $Adapters) {
            $PnP = Get-PnpDevice -InstanceId $Adapter.PnPDeviceID -ErrorAction SilentlyContinue
            if ($PnP) {
                powercfg /devicequery wake_armed | Out-Null
            }

            Set-NetAdapterPowerManagement -Name $Adapter.Name -AllowComputerToTurnOffDevice Disabled -ErrorAction SilentlyContinue
        }

        Write-Log "NIC power saving disabled where supported"
        return "Success"
    }
    catch {
        Write-Log "Failed disabling NIC power saving: $($_.Exception.Message)" "ERROR"
        return "Partial/Failed"
    }
}

function Open-NetworkAdapters {
    Start-Process ncpa.cpl
    Write-Log "Opened network adapters"
    return "Opened"
}

function Show-NetworkMenu {
    while ($true) {
        Show-Banner
        Write-Host "Network Tweaks" -ForegroundColor Yellow
        Write-Host ""

        Write-Host "  1. Reset Network Stack"
        Write-Host "  2. Disable NIC Power Saving"
        Write-Host "  3. Open Network Adapters"
        Write-Host ""
        Write-Host "  0. Back"
        Write-Host ""

        $Choice = Read-Host "Select"

        switch ($Choice) {
            "1" { Write-Status "Network Reset" (Reset-NetworkStack) "Yellow"; Pause-App }
            "2" { Write-Status "NIC Power Saving" (Disable-NICPowerSaving) "Green"; Pause-App }
            "3" { Write-Status "Network Adapters" (Open-NetworkAdapters) "Yellow"; Pause-App }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Pause-App }
        }
    }
}
