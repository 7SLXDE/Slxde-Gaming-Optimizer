# =====================================================
# Display.ps1
# =====================================================

function Write-Status {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Colour = "White"
    )
    Write-Host ("{0,-30}" -f $Name) -NoNewline
    Write-Host $Status -ForegroundColor $Colour
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host $Title -ForegroundColor Yellow
    Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray
}
