# =====================================================
# Display.ps1
# =====================================================

function Write-Status {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Colour = "White"
    )

    Write-Host ("{0,-28}" -f $Name) -NoNewline

    switch ($Colour) {
        "Green"  { Write-Host $Status -ForegroundColor Green }
        "Red"    { Write-Host $Status -ForegroundColor Red }
        "Yellow" { Write-Host $Status -ForegroundColor Yellow }
        "Cyan"   { Write-Host $Status -ForegroundColor Cyan }
        Default  { Write-Host $Status }
    }
}

function Show-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host $Title -ForegroundColor Yellow
    Write-Host ("-" * 58) -ForegroundColor DarkGray
}
