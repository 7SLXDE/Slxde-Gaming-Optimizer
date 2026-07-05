# =====================================================
# Cleanup.ps1
# Cleanup / Health Check
# =====================================================

function Clear-TempFiles {
    try {
        Write-Log "Clearing temp files"

        $Paths = @(
            "$env:TEMP\*",
            "$env:WINDIR\Temp\*"
        )

        foreach ($Path in $Paths) {
            Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
        }

        return "Success"
    }
    catch {
        Write-Log "Failed clearing temp files: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Clear-LogFiles {
    try {
        Write-Log "Clearing common log files"

        Remove-Item "$env:WINDIR\Logs\CBS\*.log" -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:WINDIR\Logs\DISM\*.log" -Force -ErrorAction SilentlyContinue

        return "Success"
    }
    catch {
        Write-Log "Failed clearing log files: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Clear-ShaderCaches {
    try {
        Write-Log "Clearing shader caches"

        $Paths = @(
            "$env:LOCALAPPDATA\D3DSCache\*",
            "$env:LOCALAPPDATA\NVIDIA\DXCache\*",
            "$env:LOCALAPPDATA\NVIDIA\GLCache\*",
            "$env:ProgramData\NVIDIA Corporation\NV_Cache\*",
            "$env:LOCALAPPDATA\AMD\DxCache\*",
            "$env:LOCALAPPDATA\AMD\GLCache\*"
        )

        foreach ($Path in $Paths) {
            Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
        }

        return "Success"
    }
    catch {
        Write-Log "Failed clearing shader caches: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Start-DiskCleanup {
    try {
        Start-Process cleanmgr.exe
        Write-Log "Disk Cleanup launched"
        return "Opened"
    }
    catch {
        Write-Log "Failed launching Disk Cleanup: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Start-RepairCommandWindow {
    param(
        [string]$Title,
        [string]$Command
    )

    if (!(Assert-Admin)) { return "Failed" }

    try {
        $Script = @"
title $Title
echo ============================================================
echo $Title
echo ============================================================
echo.
echo This can take several minutes.
echo Do not close this window until it finishes.
echo.
$Command
echo.
echo ============================================================
echo Finished.
echo ============================================================
pause
"@

        $TempFile = Join-Path $env:TEMP "SlxdeRepairCommand.cmd"
        Set-Content -Path $TempFile -Value $Script -Encoding ASCII

        Start-Process cmd.exe -ArgumentList "/k `"$TempFile`"" -Verb RunAs

        Write-Log "$Title launched in separate command window"
        return "Opened"
    }
    catch {
        Write-Log "Failed launching $Title $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Invoke-SystemFileCheck {
    if (!(Confirm-Action "Run System File Check? This can take 10-20 minutes.")) { return "Cancelled" }

    return Start-RepairCommandWindow `
        -Title "Slxde Optimizer - System File Check" `
        -Command "sfc /scannow"
}

function Invoke-WindowsImageRepair {
    if (!(Confirm-Action "Run Windows Image Repair? This can take 10-30 minutes.")) { return "Cancelled" }

    return Start-RepairCommandWindow `
        -Title "Slxde Optimizer - Windows Image Repair" `
        -Command "DISM /Online /Cleanup-Image /RestoreHealth"
}

function Show-CleanupMenu {
    while ($true) {
        Show-Banner
        Write-Host "Cleanup / Health Check" -ForegroundColor Yellow
        Write-Host ""

        Write-Host "  1. Delete Temp Files"
        Write-Host "  2. Delete Log Files"
        Write-Host "  3. Open Disk Cleanup"
        Write-Host "  4. Clear Shader Caches"
        Write-Host "  5. System File Check"
        Write-Host "  6. Windows Image Check and Repair"
        Write-Host ""
        Write-Host "  0. Back"
        Write-Host ""

        $Choice = Read-Host "Select"

        switch ($Choice) {
            "1" { Write-Status "Temp Files" (Clear-TempFiles) "Green"; Pause-App }
            "2" { Write-Status "Log Files" (Clear-LogFiles) "Green"; Pause-App }
            "3" { Write-Status "Disk Cleanup" (Start-DiskCleanup) "Yellow"; Pause-App }
            "4" { Write-Status "Shader Caches" (Clear-ShaderCaches) "Green"; Pause-App }
            "5" { Write-Status "System File Check" (Invoke-SystemFileCheck) "Yellow"; Pause-App }
            "6" { Write-Status "Windows Image Repair" (Invoke-WindowsImageRepair) "Yellow"; Pause-App }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Pause-App }
        }
    }
}
