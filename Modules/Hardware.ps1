# =====================================================
# Hardware.ps1
# =====================================================

function Get-WindowsRelease {
    try {
        $Release = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "DisplayVersion" -ErrorAction Stop
        return $Release
    }
    catch {
        return "Unknown"
    }
}

function Get-HardwareInfo {
    try {
        $OS = Get-CimInstance Win32_OperatingSystem
        $CPU = Get-CimInstance Win32_Processor
        $GPU = Get-CimInstance Win32_VideoController | Select-Object -First 1
        $RAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB,1)
        $Board = Get-CimInstance Win32_BaseBoard
        $BIOS = Get-CimInstance Win32_BIOS
        $Release = Get-WindowsRelease

        Write-Status "Windows" $OS.Caption "Green"
        Write-Status "Release" $Release "Green"
        Write-Status "Version" $OS.Version "Green"
        Write-Status "CPU" $CPU.Name "Green"
        Write-Status "GPU" $GPU.Name "Green"
        Write-Status "RAM" "$RAM GB" "Green"
        Write-Status "Motherboard" $Board.Product "Green"
        Write-Status "BIOS" $BIOS.SMBIOSBIOSVersion "Green"

        Write-Log "Hardware info collected"
    }
    catch {
        Write-Log "Failed to collect hardware info: $($_.Exception.Message)" "ERROR"
        Write-Host "Failed to collect hardware info." -ForegroundColor Red
    }
}
