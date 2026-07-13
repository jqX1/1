@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title DeepSeek Vision Proxy — 一键安装向导

cd /d "%~dp0"

:: ── 状态变量 ──
set "PYTHON_OK=0"
set "OLLAMA_OK=0"
set "DEPS_OK=0"
set "MODEL_OK=0"
set "SELECTED_MODEL=moondream:latest"

:: ═══════════════════════════════════════════
::  欢迎屏幕
:: ═══════════════════════════════════════════
cls
echo.
echo   ╔══════════════════════════════════════════════╗
echo   ║  DeepSeek Vision Proxy — 一键安装向导         ║
echo   ╠══════════════════════════════════════════════╣
echo   ║  让纯文本 LLM "看见"图片 — 零成本，纯本地      ║
echo   ╠══════════════════════════════════════════════╣
echo   ║  本向导将自动完成：                           ║
echo   ║  [1] 检测 Python                             ║
echo   ║  [2] 检测 Ollama                             ║
echo   ║  [3] 安装 Python 依赖                        ║
echo   ║  [4] 选择并下载视觉模型                      ║
echo   ║  [5] 设置开机自启 (可选)                     ║
echo   ║  [6] 启动代理服务                            ║
echo   ╚══════════════════════════════════════════════╝
echo.
echo   预计时间: 5-15 分钟 (取决于模型下载速度)
echo   可重复运行 - 已完成的步骤会自动跳过
echo.
echo   按任意键开始...
pause >nul

rem ═══════════════════════════════════════════
rem  步骤 1/6 - 检测 Python
rem ═══════════════════════════════════════════
:step_python
cls
echo.
echo ┌──────────────────────────────────────────────┐
echo │  [1/6] 检测 Python                            │
echo └──────────────────────────────────────────────┘
echo.

python --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo   [OK] %%v 已安装
    set "PYTHON_OK=1"
    goto :step_ollama
)

echo   [WARN] Python 未安装或未添加到 PATH
echo.
echo   请先安装 Python (需要 3.9 或更高版本):
echo   https://www.python.org/downloads/
echo.
echo   注意: 安装时请勾选 "Add Python to PATH"
echo.
choice /c yn /n /m "  安装完成后按 Y 重新检测，按 N 退出 [Y/N]: "
if !errorlevel! equ 2 exit /b 1
goto :step_python

rem ═══════════════════════════════════════════
rem  步骤 2/6 - 检测 Ollama
rem ═══════════════════════════════════════════
:step_ollama
cls
echo.
echo ┌──────────────────────────────────────────────┐
echo │  [2/6] 检测 Ollama                            │
echo └──────────────────────────────────────────────┘
echo.

powershell -Command "try { $r=Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -UseBasicParsing -TimeoutSec 5; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Ollama 服务运行中
    set "OLLAMA_OK=1"
    goto :step_deps
)

echo   [WARN] Ollama 未运行或未安装
echo.
echo   请先安装 Ollama:
echo   https://ollama.com/download
echo.
echo   安装后请启动 Ollama 桌面应用
echo.
choice /c yn /n /m "  Ollama 已启动后按 Y 重新检测，按 N 退出 [Y/N]: "
if !errorlevel! equ 2 exit /b 1
goto :step_ollama

rem ═══════════════════════════════════════════
rem  步骤 3/6 - 安装依赖
rem ═══════════════════════════════════════════
:step_deps
cls
echo.
echo ┌──────────────────────────────────────────────┐
echo │  [3/6] 安装 Python 依赖                       │
echo └──────────────────────────────────────────────┘
echo.

echo   正在安装 flask + requests...
pip install -r requirements.txt -q 2>&1
if %errorlevel% equ 0 (
    echo   [OK] 依赖安装完成
    set "DEPS_OK=1"
) else (
    echo   [WARN] 默认源失败，尝试镜像源...
    pip install -r requirements.txt -q -i https://pypi.tuna.tsinghua.edu.cn/simple 2>&1
    if !errorlevel! equ 0 (
        echo   [OK] 依赖安装完成 (清华镜像)
        set "DEPS_OK=1"
    ) else (
        echo   [ERROR] 依赖安装失败，请检查网络
        pause
        exit /b 1
    )
)

echo.
echo   按任意键继续...
pause >nul

rem ═══════════════════════════════════════════
rem  步骤 4/6 - 选择模型
rem ═══════════════════════════════════════════
:step_model
cls
echo.
echo ┌──────────────────────────────────────────────┐
echo │  [4/6] 视觉模型选择                           │
echo └──────────────────────────────────────────────┘
echo.
echo   请选择要使用的视觉模型:
echo.
echo   [1] moondream:latest         (~1.7 GB) 轻量快速
echo   [2] qwen2.5vl:7b             (~6.0 GB) 推荐，中英双语
echo   [3] minicpm-v:latest         (~5.5 GB) 中文最佳
echo   [4] llama3.2-vision:latest   (~7.9 GB) Meta 出品
echo   [5] 跳过 (稍后手动下载)
echo.
choice /c 12345 /n /m "  请输入选项 [1-5]: "

if !errorlevel! equ 5 goto :step_autostart
if !errorlevel! equ 4 set "SELECTED_MODEL=llama3.2-vision:latest"
if !errorlevel! equ 3 set "SELECTED_MODEL=minicpm-v:latest"
if !errorlevel! equ 2 set "SELECTED_MODEL=qwen2.5vl:7b"
if !errorlevel! equ 1 set "SELECTED_MODEL=moondream:latest"

echo.
echo   正在下载模型: !SELECTED_MODEL!
echo   这可能需要几分钟，请耐心等待...
echo.
ollama pull !SELECTED_MODEL!

if %errorlevel% equ 0 (
    echo.
    echo   [OK] 模型下载完成: !SELECTED_MODEL!
    set "MODEL_OK=1"
) else (
    echo.
    echo   [WARN] 模型下载失败，稍后可手动运行:
    echo   ollama pull !SELECTED_MODEL!
)

echo.
echo   按任意键继续...
pause >nul

rem ═══════════════════════════════════════════
rem  步骤 5/6 - 开机自启
rem ═══════════════════════════════════════════
:step_autostart
cls
echo.
echo ┌──────────────────────────────────────────────┐
echo │  [5/6] 开机自启                               │
echo └──────────────────────────────────────────────┘
echo.
echo   是否在 Windows 登录时自动启动代理？
echo.
choice /c yn /n /m "  设置开机自启? [Y/N]: "
if !errorlevel! equ 2 goto :step_launch

rem 设置 OLLAMA_MODELS
powershell -Command "[Environment]::SetEnvironmentVariable('OLLAMA_MODELS', 'D:\\ollama\\models', 'User')" 2>nul
echo   [OK] OLLAMA_MODELS 已设置

rem 创建启动文件
set "STARTUP_BAT=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\vision-proxy-startup.bat"
(
echo @echo off
echo set OLLAMA_MODELS=D:\ollama\models
echo cd /d "%~dp0"
echo start "" /min pythonw vision_proxy_server.py
) > "%STARTUP_BAT%"

if exist "%STARTUP_BAT%" (
    echo   [OK] 开机自启已配置
    echo.
    echo   代理将在登录时静默启动
    echo   取消方法: 删除启动文件夹中的 vision-proxy-startup.bat
) else (
    echo   [WARN] 配置失败 (权限不足?)
)

echo.
echo   按任意键继续...
pause >nul

rem ═══════════════════════════════════════════
rem  步骤 6/6 - 启动
rem ═══════════════════════════════════════════
:step_launch
cls
echo.
echo ┌──────────────────────────────────────────────┐
echo │  [6/6] 启动 Vision Proxy                      │
echo └──────────────────────────────────────────────┘
echo.

rem 检查已在运行?
powershell -Command "try { $r=Invoke-WebRequest -Uri 'http://localhost:8080/health' -UseBasicParsing -TimeoutSec 3; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] 代理已在运行 (localhost:8080)
    goto :success
)

echo   正在启动代理...
start "vision-proxy" /min python vision_proxy_server.py

echo   等待代理就绪...
set /a _cnt=0
:wait_proxy
timeout /t 1 /nobreak >nul
set /a _cnt+=1
powershell -Command "try { $r=Invoke-WebRequest -Uri 'http://localhost:8080/health' -UseBasicParsing -TimeoutSec 2; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 goto :success
if !_cnt! lss 8 goto :wait_proxy

echo   [WARN] 启动超时，可能仍在加载中...

rem ═══════════════════════════════════════════
rem  完成
rem ═══════════════════════════════════════════
:success
echo.
echo ╔══════════════════════════════════════════════╗
echo ║                                              ║
echo ║   ★ 全部完成！                               ║
echo ║                                              ║
echo ║   代理   : http://localhost:8080              ║
echo ║   Ollama : http://localhost:11434             ║
echo ║   模型   : !SELECTED_MODEL!                   ║
echo ║                                              ║
echo ║   ▸ 在 IDE 中将 Base URL 改为:               ║
echo ║     http://localhost:8080                    ║
echo ║     (API Key 和 Model 保持不变)              ║
echo ║                                              ║
echo ║   ▸ 手动启动: scripts\start-all.bat          ║
echo ║   ▸ 如果已设开机自启则无需手动操作           ║
echo ║                                              ║
echo ╚══════════════════════════════════════════════╝
echo.
echo   按任意键退出。代理在后台运行中。
pause >nul
exit /b 0
