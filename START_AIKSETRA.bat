@echo off
title AikSetra AI Core Banking & Assistant Launcher
color 0A
cls
echo =====================================================================
echo              AIKSETRA - LOCAL AI & BANKING CORE SERVER
echo =====================================================================
echo [1/3] Setting D: Drive Environment Variables...
set "OLLAMA_MODELS=D:\Ollama\models"
set "PATH=D:\Ollama\program;%PATH%"

echo [2/3] Checking / Starting Ollama AI Engine (RTX GPU Accelerated)...
tasklist /fi "imagename eq ollama.exe" 2>NUL | find /i /n "ollama.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo       Ollama daemon is already active!
) else (
    echo       Launching Ollama daemon from D:\Ollama\program...
    start "Ollama Engine" /min "D:\Ollama\program\ollama.exe" serve
    timeout /t 3 /nobreak >nul
)

echo [3/3] Starting AikSetra Core Banking & AI Switch Server...
cd /d "D:\AikSetra\backend"
echo.
echo =====================================================================
echo  STATUS:
echo   - AI LLM Model:       Llama 3.2 (3B) with CUDA Acceleration (RTX 3050)
echo   - Stock Market Engine: Momentum Breakouts, Value Screener & Targets
echo   - Storage Location:   D:\Ollama\models (Zero space used on C:)
echo   - Backend Server:     http://localhost:4000
echo   - Developer Console:  http://localhost:4000/console
echo   - Mobile App Link:    Ready to connect from Flutter app
echo =====================================================================
echo.
echo Press Ctrl+C at any time to stop the server.
echo.
npm run dev
pause
