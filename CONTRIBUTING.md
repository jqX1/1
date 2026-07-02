# Contributing

Thanks for your interest in contributing!

## How to Contribute

### Report a Bug

1. Check [existing issues](https://github.com/<user>/DeepSeek-Vision-Proxy/issues) to avoid duplicates
2. Open a new issue with:
   - Your OS and Python version
   - Steps to reproduce
   - Expected vs actual behavior
   - Error logs (if any)

### Suggest a Feature

Open an issue with the `enhancement` label. Describe what you want and why it's useful.

### Submit a Pull Request

1. **Open an issue first** to discuss the change (avoids wasted work)
2. Fork the repo and create a branch
3. Keep changes focused — one PR = one feature or fix
4. Follow existing code style (PEP 8)
5. Test your changes: `python tests/test_proxy.py`
6. Submit the PR with a clear description

## Development Setup

```bash
git clone https://github.com/<user>/DeepSeek-Vision-Proxy.git
cd DeepSeek-Vision-Proxy
pip install -r requirements.txt
```

You'll also need Ollama running locally with a vision model:

```bash
ollama pull moondream:latest
```

## Code Style

- Follow [PEP 8](https://peps.python.org/pep-0008/)
- Keep the single-file philosophy — the core proxy should remain one self-contained file
- No new dependencies without strong justification (current deps: flask, requests)

## Testing

Run the self-check before submitting:

```bash
python tests/test_proxy.py
```

All 3 tests must pass.
