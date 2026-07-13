# DeepSeek Vision Proxy

> **让纯文本的 DeepSeek API "看见"图片 — 零成本，纯本地，一个文件搞定。**

DeepSeek API 是纯文本模型，直接发图片会报错 `unknown variant image_url`。这个代理拦截你的请求，先用**本地 Ollama 视觉模型**把图片转成文字描述，再把纯文本发给 DeepSeek。图片数据全程不离开你的电脑。

## 原理

```
你发送图片+文字 → 代理(:8080) → Ollama 描述图片
                              → 改写消息（图片→文字）
                              → DeepSeek 基于文字回复
```

- 🖼️ 图片只发给本地 Ollama，不出电脑
- 📝 只有文字描述发给 DeepSeek
- ⚡ 纯文字请求零损耗直通

## 一键部署（Windows）

[![Download](https://img.shields.io/badge/下载-最新版本-blue?style=flat-square&logo=github)](https://github.com/jqX1/1/releases)

1. 从 [Releases](https://github.com/jqX1/1/releases) 下载 `DeepSeek-Vision-Proxy.zip`
2. 解压到任意目录
3. 双击 `setup.bat`
4. 按向导提示操作 → 完成！

向导会自动处理 Python 检测、依赖安装、模型下载、开机自启和代理启动。

> 其他安装方式见下方。开发者可用 `pip install deepseek-vision-proxy`。

## 手动安装

### 前提

- **Python >= 3.9**
- **Ollama**（[下载](https://ollama.com/download)）— 运行中

### 三步走

```bash
# 1. 克隆并安装
git clone https://github.com/jqX1/1.git
cd DeepSeek-Vision-Proxy
pip install -r requirements.txt

# 2. 拉取视觉模型（一次性，约 1.7 GB）
ollama pull moondream:latest

# 3. 启动代理
python vision_proxy_server.py
```

### 配置 IDE

**只改一个地方** — Base URL：

| 配置项 | 值 |
|---|---|
| **Base URL** | `http://localhost:8080` |
| API Key | 不变 |
| Model | 不变 |

适用于 **Codex、Continue、Cline、Cursor、Aider** 等所有 OpenAI 兼容客户端。

## 配置

全部通过环境变量设置，所有变量都有合理默认值。

| 变量 | 默认值 | 说明 |
|---|---|---|
| `VP_VISION_MODEL` | `moondream:latest` | Ollama 视觉模型 |
| `VP_VISION_PROMPT` | 自动 | 自定义视觉提示词（自动识别中/英文） |
| `VP_OLLAMA_API` | `http://localhost:11434` | Ollama 地址 |
| `VP_UPSTREAM_API` | `https://api.deepseek.com` | 上游 LLM API（OpenAI 兼容） |
| `VP_PORT` | `8080` | 代理监听端口 |
| `VP_LOG_LEVEL` | `INFO` | 日志级别 |
| `VP_ON_IMAGE_ERROR` | `skip` | 图片出错：`skip`（警告继续）/ `placeholder` / `fail` |

也可以创建 `.env` 文件，不用每次手打环境变量。

示例 — 用更强的模型，换端口：

```bash
# Windows
set VP_VISION_MODEL=qwen2.5vl:7b
python vision_proxy_server.py

# macOS / Linux
VP_VISION_MODEL=qwen2.5vl:7b python vision_proxy_server.py
```

## 平台支持

| 平台 | 启动方式 | 开机自启 |
|---|---|---|
| Windows | `scripts\start.bat` | [任务计划程序](docs/deployment.md#windows-task-scheduler) |
| macOS | `scripts/start.sh` | [LaunchAgent](docs/deployment.md#macos-launchagent) |
| Linux | `scripts/start.sh` | [systemd](docs/deployment.md#linux-systemd) |

## 项目结构

```
DeepSeek-Vision-Proxy/
├── vision_proxy_server.py   ← 核心代理，单文件 200+ 行
├── requirements.txt          ← 仅 flask + requests
├── scripts/                  ← 各平台启动/安装脚本
├── tests/                    ← 自检脚本
└── docs/                     ← 架构、部署、模型选择文档
```

## 可选视觉模型

| 模型 | 大小 | 特点 |
|---|---|---|
| `moondream:latest` | ~1.7 GB | 轻量快速（默认） |
| `minicpm-v:latest` | ~5.5 GB | 中文识别好 |
| `qwen2.5vl:7b` | ~6.0 GB | **综合最强，推荐** |
| `llama3.2-vision:latest` | ~7.9 GB | Meta 出品，通用 |

详见 [docs/model_guide.md](docs/model_guide.md) — 包含切换方法和模型对比。

## 常见问题

| 现象 | 原因 | 解决 |
|---|---|---|
| `Connection refused` | 代理未启动 | `python vision_proxy_server.py` |
| `Ollama not reachable` | Ollama 未运行 | 打开 Ollama 桌面应用 |
| `401 Authentication Fails` | 未配置 API Key | 在 IDE 中配置 DeepSeek API Key |
| 图片描述不准确 | 模型能力不足 | 换 `qwen2.5vl:7b` |
| 端口 8080 被占用 | 冲突 | 设 `VP_PORT=9090` |

运行自检确认一切正常：

```bash
python tests/test_proxy.py
```

## 常见问题

**Q: 只能用于 DeepSeek 吗？**
A: 不，任何纯文本 OpenAI 兼容 API 都行。设 `VP_DEEPSEEK_API` 为你要用的地址即可。

**Q: 图片会离开我的电脑吗？**
A: 不会。图片只发给本地 Ollama，只有文字描述发给 DeepSeek。

**Q: 延迟如何？**
A: 每张图片增加 2-10 秒（取决于模型和硬件）。纯文字请求零额外延迟。

**Q: 必须装 Ollama 吗？**
A: 是的。Ollama 是视觉推理引擎，免费、本地、一键安装。

## 许可证

MIT — 详见 [LICENSE](LICENSE)。

---

[English README](README.md)
