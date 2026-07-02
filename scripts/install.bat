@echo off
chcp 65001 >nul
title DeepSeek Vision Proxy — Installer

cd /d "%~dp0.."

echo =============================================
echo   DeepSeek Vision Proxy — Installer
echo =============================================
echo.

:: 1. Check Python
echo [1/4] Checking Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] Python not found. Please install Python >= 3.9
    echo   Download: https://www.python.org/downloads/
    pause
    exit /b 1
)
python --version
echo   [OK]

:: 2. Install Python dependencies
echo.
echo [2/4] Installing Python dependencies...
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo   [ERROR] Failed to install dependencies
    pause
    exit /b 1
)
echo   [OK]

:: 3. Check Ollama
echo.
echo [3/4] Checking Ollama...
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
    echo   [WARN] Ollama is not running. Please:
    echo     1. Install Ollama from https://ollama.com/download
    echo     2. Start the Ollama application
    echo     3. Run this installer again
    pause
    exit /b 1
)
echo   [OK] Ollama is running

:: 4. Pull vision model
echo.
echo [4/4] Pulling vision model (moondream:latest)...
echo   This is a one-time download (~1.7 GB). Please wait...
ollama pull moondream:latest
if %errorlevel% neq 0 (
    echo   [WARN] Model pull may have failed. You can pull manually:
    echo   ollama pull moondream:latest
)
echo   [OK]

echo.
echo =============================================
echo   Installation complete!
echo.
echo   Start the proxy: scripts\start.bat
echo   Or: python vision_proxy_server.py
echo =============================================
pause
