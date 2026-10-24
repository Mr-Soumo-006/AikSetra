@echo off
call "%~dp0kill-port-4000.bat"
cd /d "%~dp0"
node dist/server.js