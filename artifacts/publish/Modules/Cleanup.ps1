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

function Show-SfcWarning {
    Show-Banner
    Write-Host "System File Check" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This will run:" -ForegroundColor Gray
    Write-Host "  sfc /scannow" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "What to expect:" -ForegroundColor Yellow
    Write-Host "  - Usually takes 5-20 minutes"
    Write-Host "  - May pause before showing progress"
    Write-Host "  - Checks and repairs Windows system files"
    Write-Host "  - A new command window will open"
    Write-Host ""
    return Confirm-Action "Continue with System File Check?"
}

function Show-DismWarning {
    Show-Banner
    Write-Host "Windows Image Check and Repair" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This will run:" -ForegroundColor Gray
    Write-Host "  DISM /Online /Cleanup-Image /RestoreHealth" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "What to expect:" -ForegroundColor Yellow
    Write-Host "  - Usually takes 10-30+ minutes"
    Write-Host "  - Can look stuck at certain percentages"
    Write-Host "  - Do not close it just because the percent has not moved"
    Write-Host "  - Internet may be needed to download repair files"
    Write-Host "  - A new command window will open"
    Write-Host ""
    Write-Host "Only close it if it has been stuck for a very long time." -ForegroundColor Red
    Write-Host ""
    return Confirm-Action "Continue with Windows Image Check and Repair?"
}

function Start-RepairCommandWindow {
    param(
        [string]$Title,
        [string]$Command,
        [string]$ExtraMessage = ""
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
"@

        if ($ExtraMessage -ne "") {
            $Script += @"

echo $ExtraMessage
"@
        }

        $Script += @"

echo.
$Command
echo.
echo ============================================================
echo Finished.
echo If Windows repaired anything, restart your PC.
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
    if (!(Show-SfcWarning)) { return "Cancelled" }

    return Start-RepairCommandWindow `
        -Title "SLXDE OPTI - System File Check" `
        -Command "sfc /scannow" `
        -ExtraMessage "SFC may pause before showing progress."
}

function Invoke-WindowsImageRepair {
    if (!(Show-DismWarning)) { return "Cancelled" }

    return Start-RepairCommandWindow `
        -Title "SLXDE OPTI - Windows Image Repair" `
        -Command "DISM /Online /Cleanup-Image /RestoreHealth" `
        -ExtraMessage "DISM can look stuck at certain percentages. Let it run."
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
