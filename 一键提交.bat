@echo off
cd /d "%~dp0"
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS%" set "PS=powershell"
set "SCRIPT="
for %%f in ("%~dp0*.ps1") do set "SCRIPT=%%~ff"
if not defined SCRIPT (
  echo [ERROR] No .ps1 script found next to this file.
  echo.
  pause
  exit /b 1
)
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
echo.
pause