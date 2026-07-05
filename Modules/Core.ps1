# =====================================================
# Core.ps1
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

function Get-WindowsReleaseName {
    try {
        $DisplayVersion = Get-ItemPropertyValue `
            -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" `
            -Name "DisplayVersion" `
            -ErrorAction Stop

        return $DisplayVersion
    }
    catch {
        try {
            $ReleaseId = Get-ItemPropertyValue `
                -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" `
                -Name "ReleaseId" `
                -ErrorAction Stop

            return $ReleaseId
        }
        catch {
            return "Unknown"
        }
    }
}
