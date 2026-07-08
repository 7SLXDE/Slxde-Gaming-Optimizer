# =====================================================
# BackupRestore.ps1
# Backup / Restore system for Slxde Gaming Optimizer
# =====================================================

function Get-SlxdeBackupRoot {
    $Root = Join-Path $env:ProgramData "Slxde Gaming Optimizer\Backups"

    if (!(Test-Path $Root)) {
        New-Item -Path $Root -ItemType Directory -Force | Out-Null
    }

    return $Root
}

function Get-SlxdeLatestBackup {
    $Root = Get-SlxdeBackupRoot

    $Latest = Get-ChildItem -Path $Root -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    return $Latest
}

function Export-SlxdeRegistryKey {
    param(
        [string]$RegPath,
        [string]$OutputFile
    )

    try {
        cmd /c "reg export `"$RegPath`" `"$OutputFile`" /y >nul 2>nul"
        if (Test-Path $OutputFile) {
            return "Success"
        }
        return "Skipped"
    }
    catch {
        return "Failed"
    }
}

function Backup-SlxdePowerPlan {
    param(
        [string]$BackupDir
    )

    try {
        $Active = powercfg /getactivescheme
        Set-Content -Path (Join-Path $BackupDir "active_power_plan.txt") -Value $Active -Encoding UTF8

        $SlxdeGuid = $null
        $Plans = powercfg /list
        $Line = ($Plans | Select-String "Optimal Power Plan" | Select-Object -First 1).Line

        if ($Line -match '([a-fA-F0-9\-]{36})') {
            $SlxdeGuid = $Matches[1]
            powercfg /export (Join-Path $BackupDir "SLXDE-PowerPlan.pow") $SlxdeGuid | Out-Null
        }

        return "Success"
    }
    catch {
        Write-Log "Power plan backup failed: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function New-SlxdeRestorePoint {
    if (!(Assert-Admin)) { return "Failed" }

    try {
        Checkpoint-Computer -Description "Before Slxde Gaming Optimizer changes" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Log "System restore point created"
        return "Success"
    }
    catch {
        Write-Log "Restore point skipped/failed: $($_.Exception.Message)" "WARN"
        return "Skipped"
    }
}

function New-SlxdeBackup {
    if (!(Assert-Admin)) { return "Failed" }

    try {
        $Root = Get-SlxdeBackupRoot
        $Stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $BackupDir = Join-Path $Root $Stamp

        New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null

        Write-Log "Creating backup at $BackupDir"

        $Results = [ordered]@{}

        $Results["RestorePoint"] = New-SlxdeRestorePoint
        $Results["PowerPlan"] = Backup-SlxdePowerPlan -BackupDir $BackupDir

        $RegistryDir = Join-Path $BackupDir "Registry"
        New-Item -Path $RegistryDir -ItemType Directory -Force | Out-Null

        $RegTargets = [ordered]@{
            "GameConfigStore.reg"       = "HKCU\System\GameConfigStore"
            "GameBar.reg"              = "HKCU\Software\Microsoft\GameBar"
            "GameDVR.reg"              = "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR"
            "GraphicsSettings.reg"     = "HKCU\Software\Microsoft\DirectX\UserGpuPreferences"
            "ExplorerAdvanced.reg"     = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            "Mouse.reg"                = "HKCU\Control Panel\Mouse"
            "MultimediaSystem.reg"     = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
            "Location.reg"             = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
        }

        foreach ($Name in $RegTargets.Keys) {
            $OutFile = Join-Path $RegistryDir $Name
            $Results[$Name] = Export-SlxdeRegistryKey -RegPath $RegTargets[$Name] -OutputFile $OutFile
        }

        $Info = [ordered]@{
            Created               = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            ComputerName          = $env:COMPUTERNAME
            User                  = $env:USERNAME
            OptimizerVersion      = "v 0.9.65"
            BackupPath            = $BackupDir
        }

        $Info | ConvertTo-Json | Set-Content -Path (Join-Path $BackupDir "backup-info.json") -Encoding UTF8
        $Results | ConvertTo-Json | Set-Content -Path (Join-Path $BackupDir "backup-results.json") -Encoding UTF8

        Write-Host ""
        Write-Host "Backup created:" -ForegroundColor Green
        Write-Host $BackupDir -ForegroundColor Cyan
        Write-Host ""

        Write-Log "Backup created: $BackupDir"
        return "Success"
    }
    catch {
        Write-Log "Backup failed: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Restore-SlxdeRegistryBackup {
    param(
        [string]$BackupDir
    )

    try {
        $RegistryDir = Join-Path $BackupDir "Registry"

        if (!(Test-Path $RegistryDir)) {
            Write-Log "No registry backup folder found"
            return "Skipped"
        }

        $RegFiles = Get-ChildItem -Path $RegistryDir -Filter *.reg -ErrorAction SilentlyContinue

        foreach ($RegFile in $RegFiles) {
            cmd /c "reg import `"$($RegFile.FullName)`" >nul 2>nul"
            Write-Log "Imported registry backup: $($RegFile.Name)"
        }

        return "Success"
    }
    catch {
        Write-Log "Registry restore failed: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Restore-SlxdePowerBackup {
    param(
        [string]$BackupDir
    )

    try {
        $PowerFile = Join-Path $BackupDir "SLXDE-PowerPlan.pow"

        if (Test-Path $PowerFile) {
            powercfg /import $PowerFile | Out-Null
            Write-Log "Imported SLXDE power plan backup"
        }

        return "Success"
    }
    catch {
        Write-Log "Power plan restore failed: $($_.Exception.Message)" "ERROR"
        return "Failed"
    }
}

function Restore-SlxdeLatestBackup {
    if (!(Assert-Admin)) { return "Failed" }

    $Latest = Get-SlxdeLatestBackup

    if (!$Latest) {
        Write-Host "No backups found." -ForegroundColor Red
        return "Not Found"
    }

    Show-Banner
    Write-Host "Restore Latest Backup" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Latest backup:" -ForegroundColor Gray
    Write-Host "  $($Latest.FullName)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This will import backed-up registry settings." -ForegroundColor Yellow
    Write-Host "A restart is recommended afterwards." -ForegroundColor Yellow
    Write-Host ""

    if (!(Confirm-Action "Continue restoring latest backup?")) {
        return "Cancelled"
    }

    $RegResult = Restore-SlxdeRegistryBackup -BackupDir $Latest.FullName
    $PowerResult = Restore-SlxdePowerBackup -BackupDir $Latest.FullName

    Write-Log "Latest backup restored from $($Latest.FullName)"
    return "Registry: $RegResult / Power: $PowerResult"
}

function Show-SlxdeBackups {
    $Root = Get-SlxdeBackupRoot

    Show-Banner
    Write-Host "Available Backups" -ForegroundColor Yellow
    Write-Host ""

    $Backups = Get-ChildItem -Path $Root -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending

    if (!$Backups) {
        Write-Host "No backups found." -ForegroundColor Red
        Pause-App
        return
    }

    foreach ($Backup in $Backups) {
        Write-Host "  $($Backup.Name)" -ForegroundColor Cyan
        Write-Host "    $($Backup.FullName)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Pause-App
}

function Open-SlxdeBackupFolder {
    $Root = Get-SlxdeBackupRoot
    Start-Process explorer.exe $Root
    Write-Log "Opened backup folder"
    return "Opened"
}

function Show-BackupRestoreMenu {
    while ($true) {
        Show-Banner
        Write-Host "Backup / Restore" -ForegroundColor Yellow
        Write-Host ""

        Write-Host "  1. Create Backup Now"
        Write-Host "  2. Restore Latest Backup"
        Write-Host "  3. Show Available Backups"
        Write-Host "  4. Open Backup Folder"
        Write-Host ""
        Write-Host "  0. Back"
        Write-Host ""

        $Choice = Read-Host "Select"

        switch ($Choice) {
            "1" { Write-Status "Create Backup" (New-SlxdeBackup) "Green"; Pause-App }
            "2" { Write-Status "Restore Latest Backup" (Restore-SlxdeLatestBackup) "Yellow"; Pause-App }
            "3" { Show-SlxdeBackups }
            "4" { Write-Status "Backup Folder" (Open-SlxdeBackupFolder) "Yellow"; Pause-App }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Pause-App }
        }
    }
}
