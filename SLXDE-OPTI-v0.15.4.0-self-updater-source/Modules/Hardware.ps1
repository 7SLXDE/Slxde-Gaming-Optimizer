# =====================================================
# Hardware.ps1
# =====================================================

function Get-WindowsRelease {
    try {
        $CV = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        if ($CV.DisplayVersion) { return $CV.DisplayVersion }
        if ($CV.ReleaseId) { return $CV.ReleaseId }
        return "Unknown"
    }
    catch { return "Unknown" }
}

function Get-HardwareInfo {
    $OS = Get-CimInstance Win32_OperatingSystem
    $CPU = Get-CimInstance Win32_Processor
    $GPU = Get-CimInstance Win32_VideoController | Sort-Object AdapterRAM -Descending | Select-Object -First 1
    $RAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB,1)
    $Board = Get-CimInstance Win32_BaseBoard
    $BIOS = Get-CimInstance Win32_BIOS

    Write-Status "Windows" $OS.Caption "Green"
    Write-Status "Release" (Get-WindowsRelease) "Green"
    Write-Status "Version" $OS.Version "Green"
    Write-Status "CPU" $CPU.Name "Green"
    Write-Status "GPU" $GPU.Name "Green"
    Write-Status "RAM" "$RAM GB" "Green"
    Write-Status "Motherboard" $Board.Product "Green"
    Write-Status "BIOS" $BIOS.SMBIOSBIOSVersion "Green"

    Write-Log "Hardware info collected"
}
