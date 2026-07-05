# =====================================================
# Display.ps1
# Console UI helpers
# =====================================================

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host "                 Slxde Gaming Optimizer v0.5.2" -ForegroundColor Green
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Section {
    param([string]$Title)

    Write-Host ""
    Write-Host $Title -ForegroundColor Yellow
    Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray
}

function Write-Status {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Colour = "White"
    )

    Write-Host ("{0,-34}" -f $Name) -NoNewline

    switch ($Colour) {
        "Green"  { Write-Host $Status -ForegroundColor Green }
        "Red"    { Write-Host $Status -ForegroundColor Red }
        "Yellow" { Write-Host $Status -ForegroundColor Yellow }
        "Cyan"   { Write-Host $Status -ForegroundColor Cyan }
        default  { Write-Host $Status }
    }
}

function Show-Warning {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Show-ErrorMessage {
    param([string]$Message)
    Write-Host "[X] $Message" -ForegroundColor Red
}
