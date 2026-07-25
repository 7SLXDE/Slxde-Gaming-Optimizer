@echo off
setlocal
cd /d "%~dp0"
title SLXDE OPTI Launcher

where dotnet.exe >nul 2>nul
if errorlevel 1 (
    echo.
    echo SLXDE OPTI could not find the .NET SDK.
    echo Install the .NET 8 SDK, then run this launcher again.
    echo https://dotnet.microsoft.com/download/dotnet/8.0
    echo.
    pause
    exit /b 1
)

if not exist "%~dp0Gui\SlxdeOptimizer.App\SlxdeOptimizer.App.csproj" (
    echo.
    echo The SLXDE OPTI project files are missing.
    echo Extract the complete ZIP before running this launcher.
    echo.
    pause
    exit /b 1
)

set "SLXDE_PROJECT=%~dp0Gui\SlxdeOptimizer.App\SlxdeOptimizer.App.csproj"
set "SLXDE_APP=%~dp0Gui\SlxdeOptimizer.App\bin\Release\net8.0-windows\SlxdeOptimizer.App.exe"

echo Preparing SLXDE OPTI...
dotnet build "%SLXDE_PROJECT%" -c Release --nologo --verbosity minimal

if errorlevel 1 (
    echo.
    echo SLXDE OPTI did not start. Send a screenshot of the error above.
    echo.
    pause
    exit /b 1
)

if not exist "%SLXDE_APP%" (
    echo.
    echo The build completed but the SLXDE OPTI app was not found.
    echo Send a screenshot of this window.
    echo.
    pause
    exit /b 1
)

echo Launching SLXDE OPTI...
start "" "%SLXDE_APP%"

endlocal
