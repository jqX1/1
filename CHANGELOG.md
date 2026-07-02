# Changelog

## v1.0.0 (2026-07-02)

### Added
- Initial release: Flask proxy that converts `image_url` to text descriptions via Ollama vision models
- Environment variable configuration (`VP_*` prefix)
- Support for data URIs, HTTP URLs, and local file paths as image sources
- Streaming and non-streaming response passthrough from DeepSeek
- Health check endpoint (`/health`) with Ollama connectivity status
- Cross-platform launcher scripts: `start.bat` (Windows), `start.sh` (macOS/Linux)
- One-click installer scripts: `install.bat`, `install.sh`
- Self-check test suite (`tests/test_proxy.py`)
- Vision model quality test (`tests/test_vision_model.py`)
- Documentation: architecture, deployment guide, model selection guide
- MIT License
