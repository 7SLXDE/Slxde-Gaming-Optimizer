# =====================================================
# Core.ps1
# =====================================================

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host "                 Slxde Gaming Optimizer v0.7" -ForegroundColor Green
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

function Assert-Admin {
    if (!(Test-Administrator)) {
        Write-Host "This action needs Administrator rights." -ForegroundColor Red
        Write-Host "Run PowerShell as Administrator and try again." -ForegroundColor Yellow
        return $false
    }
    return $true
}
