function Show-Banner {

    Clear-Host

    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host "                 Slxde Gaming Optimizer v0.4" -ForegroundColor Green
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""

}

function Pause-App {

    Write-Host ""
    Read-Host "Press ENTER to continue"

}

function Test-Administrator {

    $CurrentUser = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )

    return $CurrentUser.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

}

function Write-Status {

    param(
        [string]$Name,
        [string]$Status,
        [string]$Colour
    )

    Write-Host ("{0,-35}" -f $Name) -NoNewline

    switch ($Colour) {

        "Green" { Write-Host $Status -ForegroundColor Green }

        "Red" { Write-Host $Status -ForegroundColor Red }

        "Yellow" { Write-Host $Status -ForegroundColor Yellow }

        Default { Write-Host $Status }

    }

}