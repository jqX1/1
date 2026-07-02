---
marp: true
theme: uncover
paginate: true
backgroundColor: #1a1a2e
color: #eee
---

# DeepSeek Vision Proxy

### 让纯文本大模型 "睁开眼睛"

---

## 问题：DeepSeek 是个"盲人"

![bg right:40% 80%](https://img.icons8.com/color/240/closed-eye--v1.png)

- DeepSeek API **不支持图片输入**
- 发图片就报错：`unknown variant image_url`
- 但日常工作经常需要：
  - 📸 截代码报错让 AI 分析
  - 🎨 上传设计图问修改意见
  - 📊 贴表格截图提取数据

---

## 方案：给 DeepSeek 配一双"眼睛"

```
┌──────────┐     图片 + 文字      ┌────────────────┐     纯文本      ┌──────────┐
│  你的 IDE  │ ──────────────────▶ │  Vision Proxy   │ ──────────────▶ │ DeepSeek │
│          │ ◀────────────────── │  :8080          │ ◀────────────── │ API      │
└──────────┘     纯文本回复        └───────┬────────┘    纯文本回复      └──────────┘
                                           │
                                   图片 base64
                                           ▼
                                   ┌───────────────┐
                                   │ Ollama 视觉模型 │
                                   │ (本地, 免费)    │
                                   └───────────────┘
```

**图片不出电脑，只有文字描述发给云端**

---

## 核心原理（30 秒看懂）

<!-- _class: invert -->

1. IDE 发出请求（含图片）→ 被代理拦截
2. 代理把图片发给本地 Ollama → 返回文字描述
3. 代理把「图片描述 + 用户问题」拼好 → 发给 DeepSeek
4. DeepSeek 基于文字描述回复 → 代理原样返回给 IDE

```
图片: 📸 → "一张电路板照片，上方有红色LED灯，左侧有R1电阻..."
问题: "这个电路怎么改？"
     ↓
DeepSeek 收到: "这个电路怎么改？[图片描述：一张电路板...]"
DeepSeek 回复: "建议把R1换成1kΩ电阻..."
```

---

## 为什么选这个方案

| 方案 | 成本 | 需要训练 | 图片隐私 | 效果 |
|------|------|----------|----------|------|
| 换个多模态模型 | 贵 | 否 | 上传云端 | 好 |
| 自训练视觉层 | 天价 | 是 | — | 未知 |
| **Agent 代理模式** | **免费** | **否** | **本地** | **好** |
| **(我们的方案)** | | | | |

**不需要改模型、不需要训练、不花一分钱。**

---

## 项目亮点

- 🎯 **单文件核心** — `vision_proxy_server.py` 仅 200 行
- 🔌 **即插即用** — 只改 IDE 的 Base URL
- 🛡️ **隐私安全** — 图片数据永不离开本机
- 🪶 **轻量依赖** — 仅 `flask` + `requests`
- 🌍 **跨平台** — Windows / macOS / Linux
- 🆓 **完全免费** — Ollama 开源、DeepSeek 低价
- 🧩 **模型可换** — 支持任意 Ollama 视觉模型

---

## 部署：4 步搞定

```bash
# 1. 克隆
git clone https://github.com/jqX1/1.git && cd 1

# 2. 装依赖（3 秒）
pip install -r requirements.txt

# 3. 拉模型（一次性，1.7GB）
ollama pull moondream:latest

# 4. 启动
python vision_proxy_server.py
```

### 然后改一个配置

> IDE Base URL → `http://localhost:8080`

---

## 配置 IDE

| 配置项 | 值 |
|--------|-----|
| **Base URL** | `http://localhost:8080` |
| API Key | 不变 |
| Model | 不变 |

### 支持所有 OpenAI 兼容客户端

<div style="display: flex; justify-content: center; gap: 40px;">

Codex &nbsp; Continue &nbsp; Cline &nbsp; Cursor &nbsp; Aider

</div>

---

## 视觉模型可选

| 模型 | 大小 | 特点 |
|------|------|------|
| `moondream:latest` | 1.7 GB | 轻量快速，入门首选 |
| `minicpm-v:latest` | 5.5 GB | 中文识别好 |
| `qwen2.5vl:7b` | 6.0 GB | **综合最强，推荐** |
| `llama3.2-vision` | 7.9 GB | Meta 出品 |

```bash
# 换模型一行命令
VP_VISION_MODEL=qwen2.5vl:7b python vision_proxy_server.py
```

---

## 效果对比

| | 之前 | 之后 |
|---|---|---|
| 发图片给 DeepSeek | ❌ `unknown variant image_url` | ✅ 正常识别回复 |
| 截图问代码报错 | ❌ 要手动打字描述 | ✅ 直接贴图 |
| 流程图问分析 | ❌ 不支持 | ✅ 描述+分析 |
| 表格截图提取 | ❌ 只能手动OCR | ✅ 自动识别 |

---

## 实际使用场景

- 🐛 **Debug** — 截图报错信息，AI 秒定位
- 📐 **设计评审** — 贴 UI 图问布局建议
- 📄 **文档提取** — 表格截图转 Markdown
- 🎓 **学习辅助** — 贴题目图问解题思路
- 📊 **数据分析** — 图表截图提取趋势

---

## 安全保证

- 🔒 图片**只发本地 Ollama**，不外传
- 🔑 API Key **不被代理存储**，只透传
- 💾 代理**无持久化存储**
- 📦 依赖仅 `flask` + `requests`，无供应链风险

---

## 技术栈

```
Flask (HTTP服务)
    +
Ollama API (视觉推理)
    +
DeepSeek API (文本生成)
    =
DeepSeek Vision Proxy
```

**Python >= 3.9 | Ollama | 任一视觉模型**

---

## 开源信息

- 📂 GitHub: https://github.com/jqX1/1
- 📄 许可证: MIT
- 📖 文档: 中英双语 README + 架构/部署/模型指南

---

## 感谢

> **200 行代码，让纯文本大模型拥有视觉能力。**

![w:400](https://img.icons8.com/color/96/open-source--v1.png)

### https://github.com/jqX1/1
