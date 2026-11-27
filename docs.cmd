@echo off
setlocal

rem Starts the VitePress dev server for the docs site. It reloads when a page in docs/ changes.
cd /d "%~dp0"

if not exist node_modules\.bin\vitepress.cmd (
    echo [docs] Installing the docs dependencies...
    call npm install
    if errorlevel 1 (
        echo [docs] npm install failed. Fix the error above and run again.
        pause
        exit /b 1
    )
)

call npm run docs:dev -- --open

rem Stay open after the server stops so an error stays readable.
echo [docs] The docs server stopped.
pause
