@echo off
setlocal
cd /d "%~dp0"
title SLXDE OPTI Setup Builder

echo Building the SLXDE OPTI installer...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Installer\Build-Setup.ps1" -InstallInnoSetup

if errorlevel 1 (
    echo.
    echo The installer could not be built. Send a screenshot of the error above.
    echo.
    pause
    exit /b 1
)

echo.
echo Finished. Your installer is in:
echo artifacts\installer\SLXDE-OPTI-Setup.exe
echo.
start "" "%~dp0artifacts\installer"
pause
endlocal
