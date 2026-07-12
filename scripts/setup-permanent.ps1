# Vision Proxy 永久部署脚本 — 开机自启，进程守护
# 以管理员身份运行此脚本一次即可
# 用法: powershell -ExecutionPolicy Bypass -File scripts/setup-permanent.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$ProxyScript = Join-Path $ProjectRoot "vision_proxy_server.py"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Vision Proxy 永久部署" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. 永久设置 OLLAMA_MODELS ──
Write-Host "[1/3] 设置 OLLAMA_MODELS 环境变量..." -ForegroundColor Yellow
$targetPath = "D:\ollama\models"

# 用户级
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", $targetPath, "User")
Write-Host "  [OK] 用户级环境变量已设置: OLLAMA_MODELS=$targetPath" -ForegroundColor Green

# 尝试系统级（需要管理员权限）
try {
    [Environment]::SetEnvironmentVariable("OLLAMA_MODELS", $targetPath, "Machine")
    Write-Host "  [OK] 系统级环境变量已设置" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] 系统级需要管理员权限，跳过（用户级已设置）" -ForegroundColor Yellow
}

# 当前进程
$env:OLLAMA_MODELS = $targetPath

# ── 2. 配置 Ollama 开机自启 ──
Write-Host ""
Write-Host "[2/3] 配置 Ollama 开机自启..." -ForegroundColor Yellow

# 检查 Ollama 是否已在启动项中
$startupDir = [Environment]::GetFolderPath("Startup")
$ollamaShortcut = Join-Path $startupDir "Ollama.lnk"

if (Test-Path $ollamaShortcut) {
    Write-Host "  [OK] Ollama 已在启动文件夹中" -ForegroundColor Green
} else {
    # 找到 Ollama 可执行文件
    $ollamaPaths = @(
        "$env:LOCALAPPDATA\Programs\Ollama\ollama app.exe",
        "$env:PROGRAMFILES\Ollama\ollama app.exe"
    )
    $found = $false
    foreach ($p in $ollamaPaths) {
        if (Test-Path $p) {
            $WshShell = New-Object -ComObject WScript.Shell
            $shortcut = $WshShell.CreateShortcut($ollamaShortcut)
            $shortcut.TargetPath = $p
            $shortcut.WorkingDirectory = Split-Path $p
            $shortcut.WindowStyle = 7  # Minimized
            $shortcut.Save()
            Write-Host "  [OK] Ollama 已添加到启动文件夹" -ForegroundColor Green
            $found = $true
            break
        }
    }
    if (-not $found) {
        Write-Host "  [WARN] 未找到 Ollama 安装路径，请手动设置开机自启" -ForegroundColor Yellow
    }
}

# ── 3. 创建代理守护任务 ──
Write-Host ""
Write-Host "[3/3] 创建代理守护任务（登录时自动启动）..." -ForegroundColor Yellow

$taskName = "VisionProxyDaemon"
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($taskExists) {
    Write-Host "  正在删除旧任务..."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# 创建触发器：用户登录时 + 系统启动时
$trigger = New-ScheduledTaskTrigger -AtLogOn

# 创建动作：静默启动代理
$action = New-ScheduledTaskAction -Execute "pythonw" `
    -Argument "`"$ProxyScript`"" `
    -WorkingDirectory $ProjectRoot

# 任务配置
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 999 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Days 365)

# 以当前用户身份运行
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

Register-ScheduledTask -TaskName $taskName `
    -Trigger $trigger `
    -Action $action `
    -Settings $settings `
    -Principal $principal `
    -Description "DeepSeek Vision Proxy — 自动启动并守护进程" `
    -Force | Out-Null

Write-Host "  [OK] 守护任务已创建: $taskName" -ForegroundColor Green
Write-Host "       触发: 用户登录时" -ForegroundColor Gray
Write-Host "       守护: 崩溃后 1 分钟自动重启" -ForegroundColor Gray
Write-Host "       实例: 始终隐藏运行（无窗口）" -ForegroundColor Gray

# ── 立即启动 ──
Write-Host ""
Write-Host "正在立即启动代理..." -ForegroundColor Yellow
Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 3

# 验证
try {
    $r = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "  [OK] 代理启动成功！" -ForegroundColor Green
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  部署完成！" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  - Ollama:     开机自启"
    Write-Host "  - OLLAMA_MODELS: 已永久设置"
    Write-Host "  - 代理:       登录时自动启动 + 崩溃守护"
    Write-Host "  - 下次重启电脑一切自动运行"
    Write-Host "============================================" -ForegroundColor Cyan
} catch {
    Write-Host "  [WARN] 代理可能还没启动完，登录时会自动重试" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
