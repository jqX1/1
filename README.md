# DeepSeek Vision Proxy

> **Let pure-text DeepSeek API "see" images — zero cost, fully local, one file.**

DeepSeek's API is text-only and rejects `image_url` content with an error. This proxy intercepts your requests, converts images to text descriptions using a **local Ollama vision model**, then forwards pure text to DeepSeek. Images never leave your machine.

## How It Works

```
You send image+text → Proxy (localhost:8080) → Ollama describes image
                                              → Rewrites message as text
                                              → DeepSeek responds in text
```

## Quick Start

### Prerequisites

- **Python >= 3.9**
- **Ollama** ([download](https://ollama.com/download)) — running

### 3 Steps

```bash
# 1. Clone & install
git clone https://github.com/jqX1/1.git
cd DeepSeek-Vision-Proxy
pip install -r requirements.txt

# 2. Pull a vision model (one-time, ~1.7 GB)
ollama pull moondream:latest

# 3. Start the proxy
python vision_proxy_server.py
```

### Configure Your IDE

Change **only one setting** — the Base URL:

| Setting | Value |
|---|---|
| **Base URL** | `http://localhost:8080` |
| API Key | Unchanged |
| Model | Unchanged |

Works with **Codex, Continue, Cline, Cursor, Aider** — any OpenAI-compatible client.

## Configuration

All settings via environment variables. Sensible defaults for everything.

| Variable | Default | Description |
|---|---|---|
| `VP_VISION_MODEL` | `moondream:latest` | Ollama vision model |
| `VP_VISION_PROMPT` | auto | Custom prompt for vision model (auto-detects CN/EN) |
| `VP_OLLAMA_API` | `http://localhost:11434` | Ollama API address |
| `VP_UPSTREAM_API` | `https://api.deepseek.com` | Upstream LLM API (OpenAI-compatible) |
| `VP_PORT` | `8080` | Proxy listen port |
| `VP_LOG_LEVEL` | `INFO` | `DEBUG`, `INFO`, `WARNING`, `ERROR` |
| `VP_ON_IMAGE_ERROR` | `skip` | `skip` (warn+continue) / `placeholder` / `fail` |

You can also create a `.env` file instead of setting env vars every time.

Example — use a stronger model on port 9090:

```bash
VP_VISION_MODEL=qwen2.5vl:7b VP_PORT=9090 python vision_proxy_server.py
```

See [docs/model_guide.md](docs/model_guide.md) for model comparisons.

## Platform Support

| Platform | Launcher | Auto-start Guide |
|---|---|---|
| Windows | `scripts\start.bat` | [docs/deployment.md](docs/deployment.md#windows-task-scheduler) |
| macOS | `scripts/start.sh` | [docs/deployment.md](docs/deployment.md#macos-launchagent) |
| Linux | `scripts/start.sh` | [docs/deployment.md](docs/deployment.md#linux-systemd) |

## Project Structure

```
DeepSeek-Vision-Proxy/
├── vision_proxy_server.py   ← The whole proxy, single file
├── requirements.txt          ← Only flask + requests
├── scripts/                  ← Platform launchers
├── tests/                    ← Self-check scripts
└── docs/                     ← Architecture, deployment, model guide
```

## Supported Vision Models

| Model | Size | Best For |
|---|---|---|
| `moondream:latest` | ~1.7 GB | Lightweight, fast (default) |
| `minicpm-v:latest` | ~5.5 GB | Chinese text recognition |
| `qwen2.5vl:7b` | ~6.0 GB | Strongest visual understanding |
| `llama3.2-vision:latest` | ~7.9 GB | General purpose, Meta ecosystem |

See [docs/model_guide.md](docs/model_guide.md) for detailed comparison and switching instructions.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Connection refused` localhost:8080 | Proxy not started | Run `python vision_proxy_server.py` |
| `Ollama not reachable` | Ollama not running | Start Ollama app or `ollama serve` |
| `401 Authentication Fails` | Missing API key | Configure API key in your IDE |
| Bad image descriptions | Model too weak | Set `VP_VISION_MODEL=qwen2.5vl:7b` |
| Port 8080 in use | Conflict | Set `VP_PORT=9090` |

Run the self-check to verify everything is working:

```bash
python tests/test_proxy.py
```

## FAQ

**Q: Does this only work with DeepSeek?**
A: It works with any text-only OpenAI-compatible API. Set `VP_DEEPSEEK_API` to your provider's URL.

**Q: Do images leave my computer?**
A: No. Images are sent only to your local Ollama instance. Only the text description goes to DeepSeek.

**Q: What about latency?**
A: The vision model call adds 2-10 seconds per image depending on model size and hardware. Pure-text requests have zero overhead.

**Q: Can I use this without Ollama?**
A: No. Ollama is the vision inference engine. But it's free, local, and easy to install.

## License

MIT — see [LICENSE](LICENSE).

---

[中文文档](README_zh.md)
