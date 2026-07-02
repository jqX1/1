# Deployment Guide

## Quick Start

### Prerequisites

- **Python >= 3.9** — [Download](https://www.python.org/downloads/)
- **Ollama** — [Download](https://ollama.com/download)

### Installation

```bash
# Clone
git clone https://github.com/<user>/DeepSeek-Vision-Proxy.git
cd DeepSeek-Vision-Proxy

# Install dependencies
pip install -r requirements.txt

# Pull a vision model (one-time, ~1.7 GB)
ollama pull moondream:latest

# Start the proxy
python vision_proxy_server.py
```

### Configure Your IDE

Change **only the Base URL** in your IDE's API settings:

| Setting | Value |
|---|---|
| Base URL | `http://localhost:8080` |
| API Key | Your DeepSeek API key (unchanged) |
| Model | Your preferred model (unchanged) |

Works with any OpenAI-compatible client: Codex, Continue, Cline, Cursor, Aider, etc.

---

## Platform-Specific Notes

### Windows

Double-click `scripts\start.bat` or run in terminal:

```cmd
cd DeepSeek-Vision-Proxy
python vision_proxy_server.py
```

For silent background startup:

```cmd
start /min pythonw vision_proxy_server.py
```

### macOS / Linux

```bash
cd DeepSeek-Vision-Proxy
python vision_proxy_server.py

# Or in background
nohup python vision_proxy_server.py > proxy.log 2>&1 &
```

---

## Auto-start on Boot

### Windows (Task Scheduler)

1. Open **Task Scheduler**
2. Create Basic Task → Name: "DeepSeek Vision Proxy"
3. Trigger: "When I log on"
4. Action: "Start a program"
   - Program: `pythonw`
   - Arguments: `C:\path\to\DeepSeek-Vision-Proxy\vision_proxy_server.py`
5. Check "Run with highest privileges" → Finish

### macOS (LaunchAgent)

Create `~/Library/LaunchAgents/com.vision-proxy.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.vision-proxy</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/path/to/DeepSeek-Vision-Proxy/vision_proxy_server.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

Load it:

```bash
launchctl load ~/Library/LaunchAgents/com.vision-proxy.plist
```

### Linux (systemd)

Create `/etc/systemd/system/vision-proxy.service`:

```ini
[Unit]
Description=DeepSeek Vision Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /path/to/DeepSeek-Vision-Proxy/vision_proxy_server.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable vision-proxy
sudo systemctl start vision-proxy
```

---

## Custom Configuration

Set environment variables before starting. See `.env.example` for all options.

Example — use a stronger vision model on a custom port:

```bash
# Windows (cmd)
set VP_VISION_MODEL=qwen2.5vl:7b
set VP_PORT=9090
python vision_proxy_server.py

# macOS / Linux
export VP_VISION_MODEL=qwen2.5vl:7b
export VP_PORT=9090
python vision_proxy_server.py
```

---

## Troubleshooting

| Symptom | Cause | Solution |
|---|---|---|
| `Connection refused` on :8080 | Proxy not running | `python vision_proxy_server.py` |
| `Ollama unreachable` in health check | Ollama not running | Start Ollama desktop app or run `ollama serve` |
| `401 Authentication Fails` from DeepSeek | Missing/invalid API key | Check your IDE's API key setting |
| Poor image descriptions | Vision model too weak | Switch to `qwen2.5vl:7b` or `llama3.2-vision` |
| Port 8080 already in use | Another process | Set `VP_PORT=9090` (or any free port) |
| `ollama: command not found` | Ollama not installed | Download from https://ollama.com |
