# =====================================================
# Network.ps1
# Network tweaks
# =====================================================

function Get-ActiveAdapterInfo {
    try {
        $Adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Sort-Object LinkSpeed -Descending | Select-Object -First 1
        return $Adapter
    }
    catch {
        return $null
    }
}

function Show-ActiveAdapterInfo {
    Show-Banner
    Write-Host "Active Network Adapter Info" -ForegroundColor Yellow
    Write-Host ""

    $Adapter = Get-ActiveAdapterInfo

    if (!$Adapter) {
        Write-Host "No active adapter found." -ForegroundColor Red
        Pause-App
        return
    }

    Write-Status "Name" $Adapter.Name "Green"
    Write-Status "Interface" $Adapter.InterfaceDescription "Green"
    Write-Status "Status" $Adapter.Status "Green"
    Write-Status "Link Speed" $Adapter.LinkSpeed "Cyan"
    Write-Status "MAC" $Adapter.MacAddress "Cyan"

    try {
        $IP = Get-NetIPConfiguration -InterfaceIndex $Adapter.ifIndex
        if ($IP.IPv4Address) { Write-Status "IPv4" $IP.IPv4Address.IPAddress "Cyan" }
        if ($IP.DNSServer.ServerAddresses) { Write-Status "DNS" ($IP.DNSServer.ServerAddresses -join ", ") "Cyan" }
    }
    catch {}

    Write-Host ""
    Write-Host "Advanced properties supported by this adapter:" -ForegroundColor Yellow
    try {
        Get-NetAdapterAdvancedProperty -Name $Adapter.Name | Select-Object -ExpandProperty DisplayName | Sort-Object | ForEach-Object {
            Write-Host " - $_"
        }
    }
    catch {
        Write-Host "Could not read advanced properties." -ForegroundColor Red
    }

    Pause-App
}

function Set-AdapterPropertyIfExists {
    param(
        [string]$AdapterName,
        [string[]]$Names,
        [string[]]$Values
    )

    foreach ($Name in $Names) {
        $Prop = Get-NetAdapterAdvancedProperty -Name $AdapterName -DisplayName $Name -ErrorAction SilentlyContinue

        if ($Prop) {
            foreach ($Value in $Values) {
                try {
                    Set-NetAdapterAdvancedProperty -Name $AdapterName -DisplayName $Name -DisplayValue $Value -NoRestart -ErrorAction Stop
                    Write-Log "Set $Name to $Value on $AdapterName"
                    return $true
                }
                catch {}
            }
        }
    }

    return $false
}

function Invoke-NetworkPack {
    if (!(Assert-Admin)) { return }
    if (!(Confirm-Action "Apply Network Pack? Restart may be required.")) { return }

    Show-Banner
    Write-Host "Applying Network Pack..." -ForegroundColor Yellow
    Write-Host ""

    $Adapter = Get-ActiveAdapterInfo

    if (!$Adapter) {
        Write-Host "No active network adapter found." -ForegroundColor Red
        Pause-App
        return
    }

    Write-Status "Active Adapter" $Adapter.Name "Cyan"

    $Success = 0
    $Tried = 0

    $Settings = @(
        @{ Names = @("Energy Efficient Ethernet", "EEE", "Advanced EEE"); Values = @("Disabled", "Off") },
        @{ Names = @("Green Ethernet", "Green Ethernet Mode"); Values = @("Disabled", "Off") },
        @{ Names = @("Power Saving Mode", "Power Saving"); Values = @("Disabled", "Off") },
        @{ Names = @("Ultra Low Power Mode"); Values = @("Disabled", "Off") },
        @{ Names = @("Wake on Magic Packet"); Values = @("Disabled", "Off") },
        @{ Names = @("Wake on pattern match", "Wake on Pattern Match"); Values = @("Disabled", "Off") },
        @{ Names = @("Interrupt Moderation"); Values = @("Disabled", "Off") },
        @{ Names = @("Speed & Duplex", "Speed and Duplex"); Values = @("Auto Negotiation", "Auto", "Auto-Negotiation") }
    )

    foreach ($Setting in $Settings) {
        $Tried++
        $Applied = Set-AdapterPropertyIfExists -AdapterName $Adapter.Name -Names $Setting.Names -Values $Setting.Values

        if ($Applied) {
            $Success++
            Write-Status ($Setting.Names[0]) "Applied" "Green"
        }
        else {
            Write-Status ($Setting.Names[0]) "Not Supported" "Yellow"
        }
    }

    ipconfig /flushdns | Out-Null

    Write-Host ""
    Write-Status "DNS Flush" "Success" "Green"
    Write-Status "Supported Tweaks Applied" "$Success / $Tried" "Cyan"

    Write-Host ""
    Write-Host "Done. Restart recommended." -ForegroundColor Yellow

    Write-Log "Network Pack completed. Applied $Success / $Tried supported adapter tweaks."
    Pause-App
}

function Reset-NetworkStack {
    if (!(Assert-Admin)) { return "Failed" }

    # v0.8.2 safety: create a backup before grouped tweak actions where possible.
    if (Get-Command New-SlxdeBackup -ErrorAction SilentlyContinue) { New-SlxdeBackup | Out-Null }
    if (!(Confirm-Action "Reset network stack? This may remove custom network settings and needs a restart.")) { return "Cancelled" }

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
        Write-Log "Attempting NIC power saving tweaks"

        $Adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue

        foreach ($Adapter in $Adapters) {
            try {
                Set-NetAdapterPowerManagement -Name $Adapter.Name -AllowComputerToTurnOffDevice Disabled -ErrorAction SilentlyContinue | Out-Null
            }
            catch {
                Write-Log "NIC adapter does not support Set-NetAdapterPowerManagement: $($Adapter.Name)" "WARN"
            }
        }

        Write-Log "NIC power saving attempt completed"
        return "Completed"
    }
    catch {
        Write-Log "Failed disabling NIC power saving: $($_.Exception.Message)" "ERROR"
        return "Partial"
    }
}

function Disable-IPv6 {
    if (!(Assert-Admin)) { return "Failed" }
    if (!(Confirm-Action "Disable IPv6? This can affect Xbox, VPNs, and some networks.")) { return "Cancelled" }

    try {
        Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        Write-Log "IPv6 disabled"
        return "Success"
    }
    catch {
        Write-Log "Failed to disable IPv6: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Enable-IPv6 {
    if (!(Assert-Admin)) { return "Failed" }

    try {
        Enable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        Write-Log "IPv6 enabled"
        return "Success"
    }
    catch {
        Write-Log "Failed to enable IPv6: $($_.Exception.Message)" "ERROR"
        return "Failed"
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

        Write-Host "  1. Network Pack"
        Write-Host "  2. Reset Network Stack"
        Write-Host "  3. Disable NIC Power Saving"
        Write-Host "  4. Disable IPv6"
        Write-Host "  5. Enable IPv6"
        Write-Host "  6. Open Network Adapters"
        Write-Host "  7. Show Active Adapter Info"
        Write-Host ""
        Write-Host "  0. Back"
        Write-Host ""

        $Choice = Read-Host "Select"

        switch ($Choice) {
            "1" { Invoke-NetworkPack }
            "2" { Write-Status "Network Reset" (Reset-NetworkStack) "Yellow"; Pause-App }
            "3" { Write-Status "NIC Power Saving" (Disable-NICPowerSaving) "Green"; Pause-App }
            "4" { Write-Status "Disable IPv6" (Disable-IPv6) "Yellow"; Pause-App }
            "5" { Write-Status "Enable IPv6" (Enable-IPv6) "Green"; Pause-App }
            "6" { Write-Status "Network Adapters" (Open-NetworkAdapters) "Yellow"; Pause-App }
            "7" { Show-ActiveAdapterInfo }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Pause-App }
        }
    }
}
