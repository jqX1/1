# Changelog

## v1.1.0 (unreleased)

### Added
- **一键安装向导** (`setup.bat`): 双击运行，全自动完成 Python 检测、依赖安装、模型下载、开机自启、代理启动
- **GitHub Actions 自动发布** (`.github/workflows/release.yml`): 推送 tag 自动打包 ZIP 并创建 Release
- **PyPI 包支持** (`pyproject.toml`): 可直接 `pip install` 安装
- **开机自启脚本**: `auto-start.ps1`, `daemon.vbs`, `start-all.bat`, `setup-permanent.ps1`
- `__version__` 属性，方便版本追踪

### Changed
- `.gitignore` 添加 PyInstaller 构建产物

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
