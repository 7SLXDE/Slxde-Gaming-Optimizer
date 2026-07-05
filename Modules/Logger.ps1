# =====================================================
# Logger.ps1
# =====================================================

$script:LogFolder = Join-Path $PSScriptRoot "..\Logs"
$script:LogFile = Join-Path $script:LogFolder "$(Get-Date -Format 'yyyy-MM-dd').log"

function Initialize-Logger {
    if (!(Test-Path $script:LogFolder)) {
        New-Item -ItemType Directory -Path $script:LogFolder -Force | Out-Null
    }
    if (!(Test-Path $script:LogFile)) {
        New-Item -ItemType File -Path $script:LogFile -Force | Out-Null
    }
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    Initialize-Logger
    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $script:LogFile -Value "[$Time] [$Level] $Message"
}

function Show-LatestLog {
    Show-Banner
    Initialize-Logger
    Write-Host ""
    Write-Host "Latest Log" -ForegroundColor Yellow
    Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray
    Get-Content $script:LogFile -Tail 25
    Pause-App
}

Initialize-Logger
