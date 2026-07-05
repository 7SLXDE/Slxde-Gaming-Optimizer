# =====================================================
# Core.ps1
# Shared functions
# =====================================================

function Test-Administrator {
    $CurrentUser = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )

    return $CurrentUser.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Pause-App {
    Write-Host ""
    Read-Host "Press ENTER to continue"
}

function Get-SafeRegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )

    try {
        return Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop
    }
    catch {
        return $null
    }
}
