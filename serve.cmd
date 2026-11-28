@echo off
setlocal

rem Clean full build, so every start begins from fresh output.
if exist dist rmdir /s /q dist
if exist .larvae\build-cache.json del /q .larvae\build-cache.json

larvae process
if errorlevel 1 (
    echo [serve] larvae process failed. Fix the error above and run again.
    pause
    exit /b 1
)

rem The Luau LSP in the editor reads sourcemap.json in the repo root, and misses new files until it is rebuilt.
rem Build it from default.project.json, which maps src/ as written, then keep it current in the background.
argon sourcemap default.project.json --output sourcemap.json
if errorlevel 1 (
    echo [serve] argon sourcemap failed. Fix the error above and run again.
    pause
    exit /b 1
)
start "" /b argon sourcemap default.project.json --output sourcemap.json --watch

rem The watcher rewrites .larvae\build.project.json when it starts, and Argon reports "Top level project
rem file was deleted" and skips changes if that happens while it runs. So remove the file, start the
rem watcher in the background of this same window, and start Argon only once the file is back.
del /q .larvae\build.project.json
start "" /b larvae process --watch

set /a waited=0
:wait_for_project
if exist .larvae\build.project.json goto serve
if %waited% geq 30 goto wait_failed
%SystemRoot%\System32\ping.exe -n 2 127.0.0.1 >nul
set /a waited+=1
goto wait_for_project

:wait_failed
echo [serve] The larvae watcher did not write .larvae\build.project.json within 30 seconds. Check the output above.
pause
exit /b 1

:serve
rem Let the watcher finish writing the file.
%SystemRoot%\System32\ping.exe -n 2 127.0.0.1 >nul

argon serve .larvae/build.project.json

rem The watcher shares this window, so closing the window (or Ctrl-C) stops it too. Stay open so an Argon
rem error stays readable.
echo [serve] Argon stopped. Close this window to stop the Larvae watcher.
pause
