# Vision Proxy Auto-Start — 静默、零交互
# 用法：powershell -ExecutionPolicy Bypass -File scripts/auto-start.ps1
# 可安全重复运行（已运行的服务不会重复启动）

$ErrorActionPreference = "SilentlyContinue"

# 项目根目录（脚本所在目录的上一级）
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$ProxyScript = Join-Path $ProjectRoot "vision_proxy_server.py"

# 颜色输出
function Green  { Write-Host $args -ForegroundColor Green }
function Yellow { Write-Host $args -ForegroundColor Yellow }
function Red    { Write-Host $args -ForegroundColor Red }
function Cyan   { Write-Host $args -ForegroundColor Cyan }

Cyan "=== Vision Proxy Auto-Start ==="

# ── 0. 确保 OLLAMA_MODELS 已设置 ──
$env:OLLAMA_MODELS = "D:\ollama\models"

# ── 1. 检测 Ollama ──
$ollamaRunning = $false
try {
    $r = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing -TimeoutSec 3
    if ($r.StatusCode -eq 200) {
        $models = ($r.Content | ConvertFrom-Json).models
        Green "  [OK] Ollama 运行中 ($($models.Count) 个模型)"
        $ollamaRunning = $true
    }
} catch {}

if (-not $ollamaRunning) {
    Yellow "  启动 Ollama..."
    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Minimized
    # 等待就绪（最多 20 秒）
    $waited = 0
    while ($waited -lt 20) {
        Start-Sleep 1
        $waited++
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing -TimeoutSec 2
            if ($r.StatusCode -eq 200) {
                Green "  [OK] Ollama 就绪 ($waited 秒)"
                $ollamaRunning = $true
                break
            }
        } catch {}
    }
    if (-not $ollamaRunning) {
        Red "  [ERROR] Ollama 启动失败"
    }
}

# ── 2. 检测代理 ──
$proxyRunning = $false
try {
    $r = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 3
    if ($r.StatusCode -eq 200) {
        $health = $r.Content | ConvertFrom-Json
        Green "  [OK] 代理运行中 (模型: $($health.vision_model))"
        $proxyRunning = $true
    }
} catch {}

if (-not $proxyRunning) {
    Yellow "  启动代理 (localhost:8080)..."
    $proc = Start-Process "python" -ArgumentList $ProxyScript -WindowStyle Minimized -PassThru
    # 等待就绪（最多 8 秒）
    $waited = 0
    while ($waited -lt 8) {
        Start-Sleep 1
        $waited++
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 2
            if ($r.StatusCode -eq 200) {
                Green "  [OK] 代理就绪 ($waited 秒)"
                $proxyRunning = $true
                break
            }
        } catch {}
    }
    if (-not $proxyRunning) {
        Yellow "  [WARN] 代理可能仍在启动中..."
    }
}

# ── 完成 ──
Cyan "=== 全部就绪 ==="
