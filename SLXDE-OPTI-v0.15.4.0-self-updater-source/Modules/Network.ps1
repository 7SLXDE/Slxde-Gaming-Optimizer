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

function Get-SlxdeDnsBackupPath {
    $Folder = Join-Path $env:ProgramData "Slxde Gaming Optimizer\Network"
    New-Item -ItemType Directory -Path $Folder -Force | Out-Null
    return (Join-Path $Folder "dns-backup.json")
}

function Get-SlxdeActiveInternetAdapter {
    $Configurations = @(Get-NetIPConfiguration -ErrorAction SilentlyContinue |
        Where-Object { $_.NetAdapter.Status -eq 'Up' -and $_.IPv4DefaultGateway })

    foreach ($Configuration in $Configurations) {
        $Adapter = Get-NetAdapter -InterfaceIndex $Configuration.InterfaceIndex -ErrorAction SilentlyContinue
        if ($Adapter -and $Adapter.HardwareInterface) { return $Adapter }
    }

    return (Get-ActiveAdapterInfo)
}

function Invoke-GuiOptimiseDns {
    if (!(Assert-Admin)) { return "Failed - run the app as Administrator" }

    $DnsChanged = $false
    try {
        $Adapter = Get-SlxdeActiveInternetAdapter
        if (!$Adapter) { return "Failed: no active internet adapter was found." }

        $BackupPath = Get-SlxdeDnsBackupPath
        if (!(Test-Path $BackupPath)) {
            $CurrentDns = Get-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 -ErrorAction Stop
            $InterfaceGuid = [Guid]([string]$Adapter.InterfaceGuid)
            $Guid = $InterfaceGuid.ToString('B')
            $RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$Guid"
            $ManualNameServer = (Get-ItemProperty -LiteralPath $RegistryPath -Name NameServer -ErrorAction SilentlyContinue).NameServer

            [pscustomobject]@{
                InterfaceGuid = $InterfaceGuid.ToString()
                InterfaceAlias = $Adapter.Name
                WasAutomatic = [string]::IsNullOrWhiteSpace([string]$ManualNameServer)
                ServerAddresses = @($CurrentDns.ServerAddresses)
                SavedAt = (Get-Date).ToString('o')
            } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $BackupPath -Encoding UTF8
        }

        $Providers = @(
            [pscustomobject]@{ Name = 'Cloudflare'; Primary = '1.1.1.1'; Addresses = @('1.1.1.1', '1.0.0.1') },
            [pscustomobject]@{ Name = 'Google'; Primary = '8.8.8.8'; Addresses = @('8.8.8.8', '8.8.4.4') },
            [pscustomobject]@{ Name = 'Quad9'; Primary = '9.9.9.9'; Addresses = @('9.9.9.9', '149.112.112.112') }
        )
        $TestNames = @('microsoft.com', 'cloudflare.com', 'github.com', 'activision.com')
        $Results = [System.Collections.Generic.List[object]]::new()

        foreach ($Provider in $Providers) {
            $Times = [System.Collections.Generic.List[double]]::new()
            foreach ($TestName in $TestNames) {
                try {
                    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    Resolve-DnsName -Name $TestName -Type A -Server $Provider.Primary -DnsOnly -NoHostsFile -QuickTimeout -ErrorAction Stop | Out-Null
                    $Stopwatch.Stop()
                    [void]$Times.Add($Stopwatch.Elapsed.TotalMilliseconds)
                }
                catch {}
            }

            if ($Times.Count -ge 3) {
                $Average = ($Times | Measure-Object -Average).Average
                [void]$Results.Add([pscustomobject]@{
                    Name = $Provider.Name
                    Addresses = $Provider.Addresses
                    Successes = $Times.Count
                    AverageMs = [Math]::Round([double]$Average, 1)
                })
            }
        }

        if ($Results.Count -eq 0) {
            return "Failed: none of the trusted DNS providers completed enough test lookups. Your current DNS was not changed."
        }

        $Winner = $Results | Sort-Object AverageMs | Select-Object -First 1
        Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $Winner.Addresses -ErrorAction Stop
        $DnsChanged = $true
        Clear-DnsClientCache -ErrorAction SilentlyContinue

        $AppliedDns = @(Get-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 -ErrorAction Stop).ServerAddresses
        foreach ($ExpectedAddress in $Winner.Addresses) {
            if ($AppliedDns -notcontains $ExpectedAddress) {
                throw "Windows did not retain the expected DNS server $ExpectedAddress."
            }
        }

        Resolve-DnsName -Name 'microsoft.com' -Type A -Server $Winner.Addresses[0] -DnsOnly -QuickTimeout -ErrorAction Stop | Out-Null

        $ResultLines = $Results | Sort-Object AverageMs | ForEach-Object {
            "$($_.Name): $($_.AverageMs) ms ($($_.Successes)/$($TestNames.Count) successful)"
        }

        Write-Log "DNS optimiser selected $($Winner.Name) on $($Adapter.Name)"
        return "DNS optimised successfully.`n`nAdapter: $($Adapter.Name)`nSelected: $($Winner.Name)`nServers: $($Winner.Addresses -join ', ')`n`nMeasured DNS lookup times:`n$($ResultLines -join "`n")`n`nYour previous DNS settings were saved and can be restored from the Network page."
    }
    catch {
        $FailureMessage = $_.Exception.Message
        if ($DnsChanged) {
            $RestoreResult = Restore-GuiDnsSettings
            Write-Log "DNS optimiser failed after changing DNS; rollback result: $RestoreResult" "ERROR"
            return "Failed: $FailureMessage`n`nThe previous DNS settings were restored automatically."
        }
        Write-Log "DNS optimiser failed before changing DNS: $FailureMessage" "ERROR"
        return "Failed: $FailureMessage`n`nYour DNS settings were not changed."
    }
}

function Restore-GuiDnsSettings {
    if (!(Assert-Admin)) { return "Failed - run the app as Administrator" }

    try {
        $BackupPath = Get-SlxdeDnsBackupPath
        if (!(Test-Path $BackupPath)) { return "No saved DNS settings were found." }

        $Backup = Get-Content -LiteralPath $BackupPath -Raw -ErrorAction Stop | ConvertFrom-Json
        $Adapter = Get-NetAdapter -ErrorAction SilentlyContinue |
            Where-Object { $_.InterfaceGuid.ToString() -eq [string]$Backup.InterfaceGuid } |
            Select-Object -First 1
        if (!$Adapter) {
            $Adapter = Get-NetAdapter -Name ([string]$Backup.InterfaceAlias) -ErrorAction SilentlyContinue
        }
        if (!$Adapter) { return "Failed: the adapter saved in the DNS backup is no longer available." }

        if ([bool]$Backup.WasAutomatic) {
            Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ResetServerAddresses -ErrorAction Stop
            $RestoredTo = 'Automatic (DHCP)'
        }
        else {
            $Addresses = @($Backup.ServerAddresses | Where-Object { $_ })
            if ($Addresses.Count -eq 0) {
                Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ResetServerAddresses -ErrorAction Stop
                $RestoredTo = 'Automatic (DHCP)'
            }
            else {
                Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $Addresses -ErrorAction Stop
                $RestoredTo = $Addresses -join ', '
            }
        }

        Clear-DnsClientCache -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $BackupPath -Force -ErrorAction SilentlyContinue
        Write-Log "Restored DNS settings on $($Adapter.Name)"
        return "DNS settings restored successfully.`n`nAdapter: $($Adapter.Name)`nRestored to: $RestoredTo"
    }
    catch {
        Write-Log "DNS restore failed: $($_.Exception.Message)" "ERROR"
        return "Failed: $($_.Exception.Message)"
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

    # v 0.9.65 safety: create a backup before grouped tweak actions where possible.
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
