"""End-to-end self-check for DeepSeek Vision Proxy."""
import base64
import os
import sys

import requests

# Config — override via environment variables
PROXY_URL  = os.environ.get("VP_TEST_PROXY_URL",  "http://localhost:8080")
OLLAMA_URL = os.environ.get("VP_TEST_OLLAMA_URL", "http://localhost:11434")
TEST_MODEL = os.environ.get("VP_VISION_MODEL",    "moondream:latest")

# Generate a minimal 1x1 test PNG (no real images needed)
img = (
    b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01'
    b'\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f'
    b'\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82'
)
b64_data_uri = "data:image/png;base64," + base64.b64encode(img).decode()
b64_raw      = base64.b64encode(img).decode()

errors = []


def log(msg: str):
    print(msg, flush=True)


# ─── Test 1: Proxy health ──────────────────────────────────────
log("=" * 50)
log("[1/3] Proxy health check")
try:
    r = requests.get(f"{PROXY_URL}/health", timeout=10)
    data = r.json()
    assert data["status"] == "ok", "status not ok"
    assert data["ollama_reachable"], "Ollama not reachable"
    log(f"  PASS: status={data['status']}, model={data['vision_model']}, "
        f"ollama={data['ollama_reachable']}")
except Exception as e:
    errors.append(f"Test 1 failed: {e}")
    log(f"  FAIL: {e}")

# ─── Test 2: Ollama vision model direct call ────────────────────
log("")
log(f"[2/3] Ollama vision model direct test ({TEST_MODEL})")
try:
    r = requests.post(f"{OLLAMA_URL}/api/chat", json={
        "model": TEST_MODEL,
        "messages": [{"role": "user",
                       "content": "What do you see?",
                       "images": [b64_raw]}],
        "stream": False,
    }, timeout=60)
    assert r.status_code == 200, f"HTTP {r.status_code}"
    desc = r.json().get("message", {}).get("content", "")
    assert desc, "empty response"
    log(f"  PASS: {desc[:80]}...")
except Exception as e:
    errors.append(f"Test 2 failed: {e}")
    log(f"  FAIL: {e}")

# ─── Test 3: Proxy message rewriting ────────────────────────────
log("")
log("[3/3] Proxy forwarding with image")
try:
    r = requests.post(f"{PROXY_URL}/v1/chat/completions", json={
        "model": "deepseek-chat",
        "messages": [{"role": "user", "content": [
            {"type": "text", "text": "What is in the image?"},
            {"type": "image_url", "image_url": {"url": b64_data_uri}},
        ]}],
        "stream": False,
        "max_tokens": 50,
    }, timeout=180)
    # 401 is expected (no API key in test environment)
    assert r.status_code in (200, 401), f"unexpected status {r.status_code}"
    if r.status_code == 401:
        log(f"  PASS: HTTP {r.status_code} (expected — no API key in test)")
    else:
        log(f"  PASS: HTTP {r.status_code}")
except Exception as e:
    errors.append(f"Test 3 failed: {e}")
    log(f"  FAIL: {e}")

# ─── Summary ────────────────────────────────────────────────────
log("")
log("=" * 50)
if errors:
    log(f"FAILED: {len(errors)} test(s)")
    for e in errors:
        log(f"  - {e}")
    sys.exit(1)
else:
    log("All 3 tests passed!")
    sys.exit(0)
