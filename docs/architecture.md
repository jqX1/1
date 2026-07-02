# Architecture

## Overview

DeepSeek Vision Proxy is a **transparent HTTP proxy** that sits between your IDE (or any OpenAI-compatible client) and the DeepSeek API. It intercepts requests containing `image_url` content blocks, converts images to text descriptions using a local Ollama vision model, and forwards pure-text requests to DeepSeek.

## Data Flow

```
                     Image + Text
  ┌──────────┐  ──────────────────▶  ┌─────────────────┐
  │  Client  │                        │  Vision Proxy   │
  │ (IDE/API)│  ◀──────────────────  │  :8080 (Flask)  │
  └──────────┘     Text Response      └──────┬──────────┘
                                              │
                     ┌────────────────────────┼────────────────────────┐
                     │                        │                        │
               Image │ base64          Pure Text              Pure Text
                     ▼                                           ▼
              ┌──────────┐                              ┌──────────────┐
              │  Ollama  │                              │  DeepSeek    │
              │ :11434   │                              │  API (Cloud) │
              │ Vision   │                              │  Text-only   │
              │ Model    │                              │  LLM         │
              └────┬─────┘                              └──────┬───────┘
                   │                                           │
                   │ "A cat sitting on a couch..."              │
                   │                                           │
                   └──────────── Text Description ──────────────┘
                                  (appended to message)
```

## Key Components

### 1. Message Rewriter (`rewrite_messages`)

Walks through every message in the request. Two cases:

| Content Type | Action |
|---|---|
| `str` (plain text) | Pass through unchanged |
| `list` with `image_url` parts | Extract each image → call Ollama → replace with text description |
| `list` without images | Pass through unchanged |

The rewritten message looks like:

```
What's in this image?

[The user uploaded an image. Below is a description generated
by a local vision model. Please base your answer on this description.]

The image shows a close-up of a circuit board with a large
green PCB and several silver capacitors...
```

### 2. Image Loader (`load_image_base64`)

Handles three image sources uniformly:

| Source | Format | Example |
|---|---|---|
| Data URI | `data:image/png;base64,...` | Inline base64 from client |
| HTTP URL | `https://...` | Downloaded at proxy time |
| File path | `/path/to/image.png` | Local filesystem |

All are converted to raw base64 strings for Ollama's `/api/chat` endpoint.

### 3. Vision Model Call (`describe_image_via_ollama`)

Sends the image to Ollama with a fixed prompt asking for detailed description. The prompt is **always the same** — the user's actual question is never sent to the vision model. This keeps the vision model's job simple: "describe what you see."

### 4. DeepSeek Forwarder (`chat_completions`)

Takes the rewritten messages (with image descriptions instead of image URLs) and forwards them to DeepSeek's standard `/v1/chat/completions` endpoint. Supports both streaming and non-streaming responses.

## Configuration

All settings are read from environment variables with `VP_` prefix. See `.env.example` for the complete list.

No config file, no CLI flags — just environment variables. This follows the [12-factor app](https://12factor.net/config) methodology.

## Security

- **Images never leave your machine.** Only text descriptions are sent to DeepSeek.
- **API key is never stored.** The proxy reads `Authorization` from the incoming request header and forwards it as-is.
- **No persistent storage.** The proxy holds nothing on disk.

## Dependencies

- **Python packages** (2): `flask` (HTTP server) + `requests` (HTTP client)
- **External**: Ollama (must be installed separately) + a vision model (pulled via `ollama pull`)
- **No**: PyTorch, transformers, CUDA, or any ML libraries in the proxy itself. The ML happens inside Ollama.
