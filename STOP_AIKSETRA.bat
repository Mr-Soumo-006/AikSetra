@echo off
title Stop AikSetra Services
echo =====================================================================
echo Stopping AikSetra Backend and Ollama AI Engine...
echo =====================================================================
taskkill /f /im ollama.exe 2>nul
taskkill /f /im node.exe 2>nul
echo Done! All services stopped safely.
timeout /t 3 >nul
