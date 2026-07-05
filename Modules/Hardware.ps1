# =====================================================
# Hardware.ps1
# =====================================================

function Get-HardwareInfo {
    try {
        $OS = Get-CimInstance Win32_OperatingSystem
        $CPU = Get-CimInstance Win32_Processor | Select-Object -First 1
        $GPU = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch "Basic Display" } | Select-Object -First 1
        $RAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
        $Board = Get-CimInstance Win32_BaseBoard
        $BIOS = Get-CimInstance Win32_BIOS
        $Release = Get-WindowsReleaseName

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
        Write-Status "Hardware Info" "Error" "Red"
        Write-Log "Hardware info failed: $($_.Exception.Message)" "ERROR"
    }
}
