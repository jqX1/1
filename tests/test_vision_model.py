"""Test different Ollama vision models for image description quality."""
import base64
import os
import sys

import requests

OLLAMA_URL = os.environ.get("VP_TEST_OLLAMA_URL", "http://localhost:11434")
TEST_MODEL = os.environ.get("VP_VISION_MODEL",    "moondream:latest")

# Generate a minimal 1x1 test PNG
img = (
    b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01'
    b'\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f'
    b'\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82'
)
b64 = base64.b64encode(img).decode()


def log(msg: str):
    print(msg, flush=True)


def test_model(model: str, prompt: str, timeout: int = 120) -> str | None:
    """Call a vision model and return its description, or None on failure."""
    try:
        r = requests.post(f"{OLLAMA_URL}/api/chat", json={
            "model": model,
            "messages": [{"role": "user", "content": prompt, "images": [b64]}],
            "stream": False,
        }, timeout=timeout)
        r.raise_for_status()
        return r.json().get("message", {}).get("content", "").strip()
    except Exception as e:
        log(f"  [ERROR] {e}")
        return None


def main():
    log(f"Testing vision model: {TEST_MODEL}")
    log("=" * 50)
    log("")

    # Test 1: Short description
    log("[1] Short description (Chinese)")
    desc = test_model(TEST_MODEL, "请用中文描述这张图片")
    if desc:
        log(f"    {desc[:200]}")
        log(f"    [OK] {len(desc)} chars")
    else:
        log("    [FAIL]")
        sys.exit(1)

    log("")

    # Test 2: Detailed description
    log("[2] Detailed description")
    desc2 = test_model(TEST_MODEL,
        "Please describe this image in detail. List all objects, people, "
        "text, colors, actions, scene, and any noteworthy details. "
        "Be thorough and specific."
    )
    if desc2:
        log(f"    {desc2[:200]}")
        log(f"    [OK] {len(desc2)} chars")
    else:
        log("    [FAIL]")
        sys.exit(1)

    log("")
    log("=" * 50)
    log(f"Model {TEST_MODEL} is working correctly.")


if __name__ == "__main__":
    main()
