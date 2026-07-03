"""
Vision Proxy — Let pure-text LLMs "see" images via local Ollama vision models.

How it works:
  IDE sends image + text → Proxy intercepts → Ollama describes image →
  Proxy rewrites message as pure text → Upstream LLM responds

Images never leave your machine. Only text descriptions are sent upstream.

Requirements: Python >= 3.9, Ollama running, a vision model pulled.
After starting, set your IDE's Base URL to http://localhost:8080
"""

import base64
import logging
import os
import pathlib

import requests as http_requests
from flask import Flask, Response, request, stream_with_context


# ─── .env file loader (standard library only, no python-dotenv needed) ───
def _load_dotenv():
    """Load .env file from project root. Skips comments and empty lines."""
    env_path = pathlib.Path(__file__).parent / ".env"
    if not env_path.exists():
        return
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


_load_dotenv()


# ─── Configuration (all overridable via environment variables) ───
OLLAMA_API   = os.environ.get("VP_OLLAMA_API",   "http://localhost:11434")
VISION_MODEL = os.environ.get("VP_VISION_MODEL", "moondream:latest")
UPSTREAM_API = os.environ.get("VP_UPSTREAM_API", "https://api.deepseek.com")
# If set, requests WITH images go here; requests WITHOUT images go to VP_UPSTREAM_API
UPSTREAM_VISION_API = os.environ.get("VP_UPSTREAM_VISION_API", "")
PORT         = int(os.environ.get("VP_PORT", "8080"))
LOG_LEVEL    = os.environ.get("VP_LOG_LEVEL", "INFO")

# DEEPSEEK_API kept as legacy alias for VP_UPSTREAM_API
DEEPSEEK_API = os.environ.get("VP_DEEPSEEK_API") or UPSTREAM_API

# Vision prompt — auto-detect language if not explicitly set
def _default_vision_prompt():
    """Pick a sensible default prompt based on upstream API language."""
    explicit = os.environ.get("VP_VISION_PROMPT")
    if explicit:
        return explicit
    # Chinese upstream → Chinese prompt (better for Chinese vision models)
    if any(k in UPSTREAM_API.lower() for k in ("deepseek", "qwen", "zhipu", "moonshot")):
        return (
            "请详细描述这张图片的内容。列出所有物体、人物、文字、颜色、"
            "动作、场景以及任何值得注意的细节。描述要详尽、具体。"
        )
    return (
        "Please describe this image in detail. List all objects, "
        "people, text, colors, actions, scene, and any noteworthy "
        "details. Be thorough and specific."
    )

VISION_PROMPT = _default_vision_prompt()

# Image error strategy: "skip" (continue), "placeholder" (static text), "fail" (raise)
VP_ON_IMAGE_ERROR = os.environ.get("VP_ON_IMAGE_ERROR", "skip")
if VP_ON_IMAGE_ERROR not in ("skip", "placeholder", "fail"):
    logger = logging.getLogger("vision-proxy")  # noqa: F811  — not yet defined, handled below
    VP_ON_IMAGE_ERROR = "skip"


# ─── Logging ────────────────────────────────────────────────────
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL.upper(), logging.INFO),
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("vision-proxy")

# ─── Hop-by-hop headers that must not be forwarded to clients ───
HOP_BY_HOP = {
    "transfer-encoding",
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "upgrade",
}


# ─── Image loading ──────────────────────────────────────────────
def load_image_base64(image_source: str) -> str:
    """
    Convert any image source to a raw base64 string (no data URI prefix).
    Ollama's /api/chat expects this format.
    """
    # data URI: data:image/png;base64,xxxxx
    if image_source.startswith("data:"):
        return image_source.split(",", 1)[1]

    # HTTP(S) URL — download
    if image_source.startswith(("http://", "https://")):
        resp = http_requests.get(image_source, timeout=30)
        resp.raise_for_status()
        return base64.b64encode(resp.content).decode("utf-8")

    # Local file — use pathlib for cross-platform path handling
    path = pathlib.Path(image_source).resolve()
    if not path.exists():
        raise FileNotFoundError(f"Image not found: {path}")
    return base64.b64encode(path.read_bytes()).decode("utf-8")


# ─── Ollama vision model call ──────────────────────────────────
def describe_image_via_ollama(image_source: str) -> str:
    """
    Send the image to Ollama's vision model and get a text description.
    Falls back according to VP_ON_IMAGE_ERROR on failure.
    """
    try:
        b64_data = load_image_base64(image_source)

        body = {
            "model": VISION_MODEL,
            "messages": [
                {
                    "role": "user",
                    "content": VISION_PROMPT,
                    "images": [b64_data],
                }
            ],
            "stream": False,
        }

        resp = http_requests.post(
            f"{OLLAMA_API}/api/chat",
            json=body,
            timeout=120,
        )
        resp.raise_for_status()

        result = resp.json()
        description = result.get("message", {}).get("content", "").strip()
        if not description:
            return "[Vision model returned empty content, please retry]"
        return description

    except Exception as e:
        logger.error(f"Ollama vision model call failed: {e}")
        if VP_ON_IMAGE_ERROR == "fail":
            raise
        elif VP_ON_IMAGE_ERROR == "placeholder":
            return "[Image attached but could not be analyzed]"
        else:  # skip
            return None  # special sentinel — caller adds warning


# ─── Message rewriting ──────────────────────────────────────────
def rewrite_messages(messages: list) -> list:
    """
    Walk through all messages. Replace image_url content arrays
    with plain text that includes the vision model's description.
    Pure-text messages pass through unchanged.
    """
    new_msgs = []
    img_count = 0
    failed_count = 0

    for msg in messages:
        content = msg.get("content", "")

        # Plain string — pass through
        if isinstance(content, str):
            new_msgs.append(msg)
            continue

        # Array — check for image_url parts
        if isinstance(content, list):
            text_parts = []
            has_image = False
            msg_failed = 0

            for part in content:
                if part.get("type") == "text":
                    text_parts.append(part["text"])
                elif part.get("type") == "image_url":
                    has_image = True
                    img_count += 1
                    img_url = part["image_url"]["url"]
                    logger.info(
                        f"  [IMAGE #{img_count}] Calling Ollama ({VISION_MODEL})..."
                    )
                    desc = describe_image_via_ollama(img_url)

                    if desc is None:
                        # Image was skipped due to error
                        failed_count += 1
                        msg_failed += 1
                        text_parts.append(
                            "\n[WARNING: 1 image failed to process — "
                            "the model's response may be incomplete.]\n"
                        )
                        logger.warning(
                            f"  [SKIP] Image #{img_count} skipped due to error"
                        )
                    else:
                        text_parts.append(
                            "\n[The user uploaded an image. Below is a description "
                            "generated by a local vision model. Please base your "
                            f"answer on this description.]\n{desc}\n"
                        )
                        logger.info(
                            f"  [OK] Image #{img_count} described: {desc[:60]}..."
                        )

            if has_image:
                new_msgs.append({**msg, "content": "\n".join(text_parts)})
            else:
                new_msgs.append(msg)

    if img_count > 0:
        logger.info(
            f"Processed {img_count} image(s) in this request"
            + (f" ({failed_count} failed)" if failed_count else "")
        )
    return new_msgs, img_count > 0


# ─── Flask application ─────────────────────────────────────────
app = Flask(__name__)


@app.route("/v1/chat/completions", methods=["POST"])
def chat_completions():
    body = request.get_json(force=True)

    # Rewrite messages: image → text description
    has_images = False
    if "messages" in body:
        body["messages"], has_images = rewrite_messages(body["messages"])

    # Pick upstream: images → vision API; text-only → default API
    target_api = DEEPSEEK_API
    if has_images and UPSTREAM_VISION_API:
        target_api = UPSTREAM_VISION_API
        logger.info(f"  Routing to vision API: {target_api}")

    # Forward auth header as-is
    headers = {
        "Authorization": request.headers.get("Authorization", ""),
        "Content-Type": "application/json",
    }

    stream = body.get("stream", False)

    resp = http_requests.post(
        f"{target_api}/v1/chat/completions",
        json=body,
        headers=headers,
        stream=stream,
        timeout=120,
    )

    if stream:
        safe_headers = {
            k: v
            for k, v in resp.headers.items()
            if k.lower() not in HOP_BY_HOP
        }
        return Response(
            stream_with_context(resp.iter_content(chunk_size=None)),
            status=resp.status_code,
            headers=safe_headers,
        )
    else:
        try:
            return resp.json(), resp.status_code
        except Exception:
            return Response(
                resp.text,
                status=resp.status_code,
                content_type="application/json",
            )


@app.route("/v1/models", methods=["GET"])
def list_models():
    """Passthrough: list models from upstream API."""
    resp = http_requests.get(
        f"{DEEPSEEK_API}/v1/models",
        headers={"Authorization": request.headers.get("Authorization", "")},
        timeout=30,
    )
    return resp.json(), resp.status_code


@app.route("/health", methods=["GET"])
def health():
    """Health check — verifies Ollama connectivity."""
    ollama_ok = False
    try:
        r = http_requests.get(f"{OLLAMA_API}/api/tags", timeout=5)
        ollama_ok = r.status_code == 200
    except Exception:
        pass

    return {
        "status": "ok",
        "vision_model": VISION_MODEL,
        "ollama_api": OLLAMA_API,
        "ollama_reachable": ollama_ok,
    }


# ─── Entry point ────────────────────────────────────────────────
def main():
    """Run the proxy server."""
    print("=" * 55)
    print("  Vision Proxy (Ollama)")
    print(f"  Vision model : {VISION_MODEL}")
    print(f"  Listen       : http://localhost:{PORT}")
    print(f"  Text API     : {DEEPSEEK_API}")
    if UPSTREAM_VISION_API:
        print(f"  Vision API   : {UPSTREAM_VISION_API}  (image requests)")
    if VP_ON_IMAGE_ERROR == "skip":
        print(f"  On img error : skip (with warning)")
    print("=" * 55)
    print()
    app.run(host="0.0.0.0", port=PORT, debug=False)


if __name__ == "__main__":
    main()
