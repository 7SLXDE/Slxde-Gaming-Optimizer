# =====================================================
# Core.ps1
# =====================================================

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host "              Slxde Gaming Optimizer v0.6.1" -ForegroundColor Green
    Write-Host "=============================================================" -ForegroundColor Cyan
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
