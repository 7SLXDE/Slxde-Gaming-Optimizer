# =====================================================
# Logger.ps1
# =====================================================

$script:LogFolder = Join-Path $PSScriptRoot "..\Logs"
$script:LogFile = Join-Path $script:LogFolder "$(Get-Date -Format 'yyyy-MM-dd').log"

function Initialize-Logger {
    if (!(Test-Path $script:LogFolder)) {
        New-Item -ItemType Directory -Path $script:LogFolder | Out-Null
    }

    if (!(Test-Path $script:LogFile)) {
        New-Item -ItemType File -Path $script:LogFile | Out-Null
    }
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    try {
        $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $script:LogFile -Value "[$Time] [$Level] $Message"
    }
    catch {
        # Logging should never crash the app.
    }
}

function Show-Logs {
    Show-Banner
    Show-Section "Latest Log"

    if (Test-Path $script:LogFile) {
        Get-Content $script:LogFile -Tail 25
    }
    else {
        Write-Host "No log file found." -ForegroundColor Yellow
    }

    Pause-App
}
