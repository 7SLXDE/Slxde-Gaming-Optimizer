# =====================================================
# Display.ps1
# =====================================================

function Show-Section {
    param([string]$Title)

    Write-Host ""
    Write-Host $Title -ForegroundColor Yellow
    Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray
}

function Write-Good {
    param([string]$Text)
    Write-Host "[OK] $Text" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Text)
    Write-Host "[!] $Text" -ForegroundColor Yellow
}

function Write-Bad {
    param([string]$Text)
    Write-Host "[X] $Text" -ForegroundColor Red
}
