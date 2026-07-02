#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "============================================="
echo "  DeepSeek Vision Proxy"
echo "============================================="
echo ""

# 1. Check Ollama
echo "[1/3] Checking Ollama..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "  [OK] Ollama is running"
else
    echo "  [WARN] Ollama is not running. Please start Ollama first."
    echo "  Install: https://ollama.com/download"
    exit 1
fi

# 2. Start proxy
echo "[2/3] Starting vision proxy (localhost:8080)..."
python vision_proxy_server.py &
PROXY_PID=$!
sleep 3

if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "  [OK] Vision proxy started (PID: $PROXY_PID)"
else
    echo "  [WARN] Proxy may still be starting..."
    sleep 3
fi

echo ""
echo "============================================="
echo "  Proxy is running at http://localhost:8080"
echo "  Set your IDE Base URL to the address above"
echo "============================================="
echo ""
echo "Press Ctrl+C to stop the proxy"

# Wait for proxy process
wait $PROXY_PID
