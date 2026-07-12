@echo off
chcp 65001 >nul
title Vision Proxy — 一键启动

cd /d "%~dp0.."

echo.
echo =============================================
echo   DeepSeek Vision Proxy — 一键启动
echo =============================================
echo.

:: ── 0. 设置 OLLAMA_MODELS 环境变量 ──
set "OLLAMA_MODELS=D:\ollama\models"

:: ── 1. Ollama ──
echo [1/2] Ollama...
powershell -Command "try { $r=Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -UseBasicParsing -TimeoutSec 3; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Ollama 已在运行
    goto :ollama_done
)

echo   正在启动 Ollama...
start "ollama-serve" /min ollama serve
echo   等待 Ollama 就绪（最多 15 秒）...

set /a _count=0
:ollama_poll
    timeout /t 1 /nobreak >nul
    powershell -Command "try { $r=Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -UseBasicParsing -TimeoutSec 2; exit 0 } catch { exit 1 }" >nul 2>&1
    if %errorlevel% equ 0 goto :ollama_ok
    set /a _count+=1
    <nul set /p "=."
    if %_count% lss 15 goto :ollama_poll

echo.
echo   [ERROR] Ollama 启动失败！请手动打开 Ollama 桌面应用后重试。
pause
exit /b 1

:ollama_ok
echo.
echo   [OK] Ollama 就绪
:ollama_done

:: ── 2. 代理 ──
echo.
echo [2/2] Vision Proxy...

powershell -Command "try { $r=Invoke-WebRequest -Uri 'http://localhost:8080/health' -UseBasicParsing -TimeoutSec 3; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] 代理已在运行
    goto :proxy_done
)

echo   正在启动代理 (localhost:8080)...
start "vision-proxy" /min python "%~dp0..\vision_proxy_server.py"

set /a _count=0
:proxy_poll
    timeout /t 1 /nobreak >nul
    powershell -Command "try { $r=Invoke-WebRequest -Uri 'http://localhost:8080/health' -UseBasicParsing -TimeoutSec 3; exit 0 } catch { exit 1 }" >nul 2>&1
    if %errorlevel% equ 0 goto :proxy_ok
    set /a _count+=1
    if %_count% lss 5 goto :proxy_poll
    echo   [WARN] 代理可能还在启动，稍等几秒...
    goto :proxy_done

:proxy_ok
echo   [OK] 代理启动成功
:proxy_done

:: ── 完成 ──
echo.
echo =============================================
echo   全部就绪！
echo.
echo   Ollama  : http://localhost:11434
echo   代理    : http://localhost:8080
echo   模型    : qwen2.5vl:7b
echo =============================================
echo.
echo   关闭此窗口不会影响后台服务。
echo.

timeout /t 5 /nobreak >nul
exit /b 0
