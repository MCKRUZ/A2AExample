@echo off
REM Batch file wrapper for setup.ps1 - Automated setup for A2A Example project

echo.
echo 🚀 A2A Example - Automated Setup
echo =================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ This script must be run as Administrator!
    echo    Right-click on setup.bat and select "Run as administrator"
    pause
    exit /b 1
)

echo ✅ Running as Administrator
echo.

REM Check if PowerShell is available
where powershell.exe >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ PowerShell not found! This script requires PowerShell 5.1+
    pause
    exit /b 1
)

echo 📝 Launching PowerShell setup script...
echo.

REM Execute the PowerShell setup script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*

if %errorLevel% neq 0 (
    echo.
    echo ❌ Setup script encountered an error!
    echo    Check the output above for details.
    pause
    exit /b %errorLevel%
)

echo.
echo ✅ Setup complete! You can close this window.
pause