@echo off
title TalentMatchIA - Backend Server
color 0A
echo ================================
echo   TalentMatchIA Backend Server
echo ================================
echo.
echo Verificando processos Node.js...
taskkill /F /IM node.exe 2>nul
timeout /t 2 /nobreak >nul
echo.
echo Iniciando servidor na porta 4000...
echo.
cd /d "%~dp0"
node server.js
echo.
echo ================================
echo Servidor parou!
echo ================================
pause
