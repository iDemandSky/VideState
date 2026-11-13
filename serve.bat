@echo off
setlocal
cd /d "%~dp0"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve-loop.ps1"
set "serveExitCode=%ERRORLEVEL%"

if not "%serveExitCode%"=="0" (
    echo.
    echo [VideState] Serve supervisor exited with code %serveExitCode%.
    pause
)

exit /b %serveExitCode%
