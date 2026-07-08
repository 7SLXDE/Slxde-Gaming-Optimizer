# =====================================================
# LaptopSafety.ps1
# Laptop / cooling safety warnings
# =====================================================

function Test-IsLaptop {
    try {
        $Chassis = Get-CimInstance -ClassName Win32_SystemEnclosure -ErrorAction SilentlyContinue
        $Types = @($Chassis.ChassisTypes)

        # Common laptop/mobile chassis values:
        # 8 Portable, 9 Laptop, 10 Notebook, 14 Sub Notebook, 30 Tablet, 31 Convertible, 32 Detachable
        foreach ($Type in $Types) {
            if ($Type -in @(8,9,10,14,30,31,32)) {
                return $true
            }
        }

        $Battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
        if ($Battery) { return $true }

        return $false
    }
    catch {
        return $false
    }
}

function Write-LaptopCoolingTopNote {
    Write-Host "Laptop / Cooling Warning" -ForegroundColor Yellow
    Write-Host "  Performance tweaks can increase heat, fan noise and power draw." -ForegroundColor DarkGray
    Write-Host "  Be careful on gaming laptops, small-form-factor PCs, dusty systems," -ForegroundColor DarkGray
    Write-Host "  stock coolers, or PCs with poor airflow. Use Balanced if temps are high." -ForegroundColor DarkGray
    Write-Host ""
}

function Show-LaptopSafetyWarning {
    Show-Banner
    Write-Host "Laptop / Cooling Safety Warning" -ForegroundColor Yellow
    Write-Host ""

    $IsLaptop = Test-IsLaptop

    if ($IsLaptop) {
        Write-Host "This PC looks like a laptop or mobile device." -ForegroundColor Red
    }
    else {
        Write-Host "This PC does not look like a laptop, but cooling still matters." -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "Performance-focused tweaks can increase:" -ForegroundColor Yellow
    Write-Host "  - CPU/GPU boost behaviour"
    Write-Host "  - temperatures"
    Write-Host "  - fan noise"
    Write-Host "  - power draw"
    Write-Host "  - battery drain"
    Write-Host ""
    Write-Host "Be careful if you have:" -ForegroundColor Yellow
    Write-Host "  - a gaming laptop"
    Write-Host "  - a small-form-factor PC"
    Write-Host "  - a stock/basic CPU cooler"
    Write-Host "  - poor case airflow"
    Write-Host "  - dusty fans or vents"
    Write-Host "  - already high CPU/GPU temperatures"
    Write-Host ""
    Write-Host "Safer choice:" -ForegroundColor Green
    Write-Host "  Balanced Power Plan + Game Mode + basic cleanup"
    Write-Host ""
    Write-Host "Performance choice:" -ForegroundColor Red
    Write-Host "  Optimal Power Plan + all performance tweaks"
    Write-Host ""
    Write-Host "Recommended:" -ForegroundColor Yellow
    Write-Host "  - Use Optimal Power Plan only when plugged in"
    Write-Host "  - Monitor CPU/GPU temperatures after applying tweaks"
    Write-Host "  - Switch back to Balanced if temperatures or fan noise are too high"
    Write-Host "  - Do not block vents"
    Write-Host "  - Clean dust if the system is running hot"
    Write-Host ""

    Pause-App
}

function Confirm-LaptopPerformanceTweaks {
    $IsLaptop = Test-IsLaptop

    Show-Banner
    Write-Host "Cooling / Power Warning" -ForegroundColor Yellow
    Write-Host ""

    if ($IsLaptop) {
        Write-Host "This PC looks like a laptop or mobile device." -ForegroundColor Red
        Write-Host ""
    }

    Write-Host "This tweak is performance-focused and may increase:" -ForegroundColor Yellow
    Write-Host "  - temperatures"
    Write-Host "  - fan noise"
    Write-Host "  - power draw"
    Write-Host "  - battery drain on laptops"
    Write-Host ""
    Write-Host "Use with care on laptops or PCs with weak cooling." -ForegroundColor Yellow
    Write-Host "Use Balanced if temperatures are too high." -ForegroundColor Green
    Write-Host ""

    return Confirm-Action "Continue anyway?"
}

function Show-LaptopSafetyMenu {
    while ($true) {
        Show-Banner
        Write-Host "Laptop / Cooling Safety" -ForegroundColor Yellow
        Write-Host ""

        Write-Host "  1. Show Full Cooling Warning"
        Write-Host "  2. Check If This PC Looks Like A Laptop"
        Write-Host ""
        Write-Host "  0. Back"
        Write-Host ""

        $Choice = Read-Host "Select"

        switch ($Choice) {
            "1" { Show-LaptopSafetyWarning }
            "2" {
                if (Test-IsLaptop) {
                    Write-Host "Laptop/mobile device detected." -ForegroundColor Yellow
                }
                else {
                    Write-Host "Desktop/no battery detected." -ForegroundColor Green
                }
                Pause-App
            }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Pause-App }
        }
    }
}
