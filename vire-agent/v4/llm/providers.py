#!/usr/bin/env python3
import os, json, urllib.request

class ProviderError(Exception):
    pass

def _post_json(url, payload, headers=None, timeout=30):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers or {}, method="POST")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))

class AtmaSphereProvider:
    """
    Expects env:
      ATMASPHERE_URL (e.g. http://localhost:9009/v1/generate)
      ATMASPHERE_API_KEY (optional)
    Payload shape can be adapted later—keep minimal now.
    """
    def generate(self, prompt):
        url = os.getenv("ATMASPHERE_URL", "").strip()
        if not url:
            raise ProviderError("ATMASPHERE_URL not set")
        headers = {"Content-Type": "application/json"}
        key = os.getenv("ATMASPHERE_API_KEY", "").strip()
        if key:
            headers["Authorization"] = f"Bearer {key}"
        payload = {"prompt": prompt, "max_tokens": 700}
        out = _post_json(url, payload, headers=headers, timeout=60)
        # expected: {"text":"..."} (adjust if your API differs)
        text = out.get("text") or out.get("output") or ""
        if not text:
            raise ProviderError("AtmaSphere returned empty text")
        return text

class OpenAIProvider:
    """
    Minimal placeholder. Wire to your gateway later.
    Expects:
      OPENAI_GATEWAY_URL (your proxy, not the public OpenAI endpoint)
      OPENAI_API_KEY
    """
    def generate(self, prompt):
        url = os.getenv("OPENAI_GATEWAY_URL", "").strip()
        if not url:
            raise ProviderError("OPENAI_GATEWAY_URL not set")
        key = os.getenv("OPENAI_API_KEY", "").strip()
        if not key:
            raise ProviderError("OPENAI_API_KEY not set")
        headers = {"Content-Type": "application/json", "Authorization": f"Bearer {key}"}
        payload = {"prompt": prompt, "max_tokens": 700}
        out = _post_json(url, payload, headers=headers, timeout=60)
        text = out.get("text") or out.get("output") or ""
        if not text:
            raise ProviderError("OpenAI gateway returned empty text")
        return text

class LocalTemplateProvider:
    """Deterministic fallback; no network."""
    def generate(self, prompt):
        return (
            "Founder’s Note: Vireoka is built by a small team with an agent-first philosophy—"
            "shipping fast, measuring truthfully, and designing for enterprise-grade reliability.\n\n"
            "Summary:\n"
            f"{prompt}\n\n"
            "This page is generated deterministically (no external model)."
        )

def pick_provider():
    # Priority: AtmaSphere -> OpenAI gateway -> deterministic local
    if os.getenv("ATMASPHERE_URL", "").strip():
        return AtmaSphereProvider()
    if os.getenv("OPENAI_GATEWAY_URL", "").strip() and os.getenv("OPENAI_API_KEY", "").strip():
        return OpenAIProvider()
    return LocalTemplateProvider()
