@echo off
for /f "tokens=5" %%a in ('netstat -aon ^| find ":4000" ^| find "LISTENING"') do (
    taskkill /F /PID %%a 2>nul
)
cd /d "C:\Users\Soumo Naskar\.gemini\antigravity\scratch\AikSetra\backend"
echo ==========================================================
echo AikSetra Core Banking Service
echo ==========================================================
node dist/server.js
pause
