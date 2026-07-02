#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "============================================="
echo "  DeepSeek Vision Proxy — Installer"
echo "============================================="
echo ""

# 1. Check Python
echo "[1/4] Checking Python..."
if command -v python3 &> /dev/null; then
    PYTHON=python3
elif command -v python &> /dev/null; then
    PYTHON=python
else
    echo "  [ERROR] Python not found. Please install Python >= 3.9"
    echo "  Download: https://www.python.org/downloads/"
    exit 1
fi
$PYTHON --version
echo "  [OK]"

# 2. Install Python dependencies
echo ""
echo "[2/4] Installing Python dependencies..."
$PYTHON -m pip install -r requirements.txt
echo "  [OK]"

# 3. Check Ollama
echo ""
echo "[3/4] Checking Ollama..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "  [OK] Ollama is running"
else
    echo "  [WARN] Ollama is not running. Please:"
    echo "    1. Install Ollama from https://ollama.com/download"
    echo "    2. Start the Ollama application"
    echo "    3. Run this installer again"
    exit 1
fi

# 4. Pull vision model
echo ""
echo "[4/4] Pulling vision model (moondream:latest)..."
echo "  This is a one-time download (~1.7 GB). Please wait..."
ollama pull moondream:latest
echo "  [OK]"

echo ""
echo "============================================="
echo "  Installation complete!"
echo ""
echo "  Start the proxy: scripts/start.sh"
echo "  Or: python vision_proxy_server.py"
echo "============================================="
