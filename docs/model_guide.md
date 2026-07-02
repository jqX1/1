# Vision Model Guide

DeepSeek Vision Proxy works with **any Ollama vision model**. Here's a comparison to help you choose.

## Recommended Models

| Model | Size | Speed | Quality | Best For |
|---|---|---|---|---|
| `moondream:latest` | ~1.7 GB | Fast | Basic | Quick descriptions, low-resource machines |
| `minicpm-v:latest` | ~5.5 GB | Medium | Good (Chinese) | Chinese text in images |
| `llama3.2-vision:latest` | ~7.9 GB | Medium | Good | General purpose, Meta ecosystem |
| `qwen2.5vl:7b` | ~6.0 GB | Medium | Excellent | Strongest visual understanding, bilingual |
| `llava:13b` | ~7.4 GB | Slower | Good | Detailed multi-object scenes |

> Sizes are approximate. Actual disk usage depends on quantization level.

## Switching Models

### One-time switch

```bash
# Pull the new model
ollama pull qwen2.5vl:7b

# Start proxy with new model
# Windows
set VP_VISION_MODEL=qwen2.5vl:7b
python vision_proxy_server.py

# macOS / Linux
VP_VISION_MODEL=qwen2.5vl:7b python vision_proxy_server.py
```

### Permanent switch

Set the environment variable system-wide or in your shell profile:

```bash
# Add to ~/.bashrc or ~/.zshrc
export VP_VISION_MODEL=qwen2.5vl:7b
```

## Model Quality Notes

### moondream (1.8B)
- **Pros**: Tiny, fast, works on CPU-only machines
- **Cons**: Basic descriptions, misses fine details, English-biased
- **Good for**: Getting started, testing, low-resource environments

### qwen2.5vl (7B)
- **Pros**: Excellent detail recognition, bilingual (CN/EN), strong at reading text in images
- **Cons**: Larger model, needs ~8GB VRAM for best performance
- **Good for**: Production use, detailed technical images, diagrams, screenshots with text

### llama3.2-vision (11B)
- **Pros**: Strong general vision, good reasoning about scenes
- **Cons**: Very large (~8GB), slow on consumer GPUs
- **Good for**: Complex multi-object scenes, when detail matters most

### minicpm-v
- **Pros**: Optimized for Chinese text recognition
- **Cons**: Weaker on non-text visual details
- **Good for**: Screenshots of Chinese UI, documents with Chinese text

## Testing a Model

Use the included test script to evaluate a model before switching:

```bash
# Test the default model
python tests/test_vision_model.py

# Test a specific model
VP_VISION_MODEL=qwen2.5vl:7b python tests/test_vision_model.py
```

This sends a test image to the model and prints its description, so you can judge the quality before committing.

## Managing Disk Space

Vision models can be large. To see what you have installed:

```bash
ollama list
```

To remove a model you no longer need:

```bash
ollama rm moondream:latest
```
