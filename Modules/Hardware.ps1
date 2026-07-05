# =====================================================
# Hardware.ps1
# Hardware detection
# =====================================================

function Get-HardwareInfo {
    try {
        $OS = Get-CimInstance Win32_OperatingSystem
        $CPU = Get-CimInstance Win32_Processor | Select-Object -First 1
        $GPU = Get-CimInstance Win32_VideoController | Sort-Object AdapterRAM -Descending | Select-Object -First 1
        $RAMBytes = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
        $RAM = [math]::Round($RAMBytes / 1GB, 1)
        $Board = Get-CimInstance Win32_BaseBoard
        $BIOS = Get-CimInstance Win32_BIOS

        Write-Status "Windows" $OS.Caption "Green"
        Write-Status "Version" $OS.Version "Green"
        Write-Status "CPU" $CPU.Name "Green"
        Write-Status "GPU" $GPU.Name "Green"
        Write-Status "RAM" "$RAM GB" "Green"
        Write-Status "Motherboard" $Board.Product "Green"
        Write-Status "BIOS" $BIOS.SMBIOSBIOSVersion "Green"
    }
    catch {
        Write-Status "Hardware Info" "Detection failed" "Red"
        Write-Log "Hardware detection failed: $($_.Exception.Message)" "ERROR"
    }
}
