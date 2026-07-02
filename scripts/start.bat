@echo off
chcp 65001 >nul
title Vision Proxy

:: Navigate to project root (one level up from scripts/)
cd /d "%~dp0.."

echo =============================================
echo   Vision Proxy
echo =============================================
echo.

:: 1. Check Ollama (using PowerShell, no curl dependency)
echo [1/3] Checking Ollama...
powershell -Command "try { $r=Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -UseBasicParsing -TimeoutSec 5; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    echo   [WARN] Ollama is not running. Please start Ollama first.
    echo   Download: https://ollama.com/download
    pause
    exit /b 1
)
echo   [OK] Ollama is running

:: 2. Start proxy
echo [2/3] Starting vision proxy (localhost:8080)...
start "vision-proxy" /min python "%~dp0..\vision_proxy_server.py"
timeout /t 3 /nobreak >nul

powershell -Command "try { $r=Invoke-WebRequest -Uri 'http://localhost:8080/health' -UseBasicParsing -TimeoutSec 3; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Vision proxy started
) else (
    echo   [WARN] Proxy may still be starting, please wait...
    timeout /t 3 /nobreak >nul
)

echo.
echo =============================================
echo   Proxy is running at http://localhost:8080
echo   Set your IDE Base URL to the address above
echo =============================================
timeout /t 3 /nobreak >nul

:: 3. (Optional) Launch IDE — uncomment and edit path
:: start "" "D:\YourIDE\ide.exe"
