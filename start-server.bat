@echo off
title AikSetra Core UPI Switch & Banking Server
echo Checking for previous instances on port 4000...
for /f "tokens=5" %%a in ('netstat -aon ^| find ":4000" ^| find "LISTENING"') do (
    taskkill /F /PID %%a 2>nul
)
if exist "%~dp0backend\dist\server.js" (
    cd /d "%~dp0backend"
) else (
    cd /d "C:\Users\Soumo Naskar\.gemini\antigravity\scratch\AikSetra\backend"
)
echo ==========================================================
echo Starting AikSetra NPCI UPI 2.0 Core Switch
echo Bound on 0.0.0.0:4000 (Local Wi-Fi + Emulator reachable)
echo ==========================================================
node dist/server.js
pause
