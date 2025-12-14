#!/usr/bin/env python3
import os, sys, json, time
from pathlib import Path
from datetime import datetime, timezone

def utc_now():
    return datetime.now(timezone.utc).isoformat()

def try_playwright(urls, out_dir: Path):
    try:
        from playwright.sync_api import sync_playwright
    except Exception as e:
        return False, f"playwright not available: {e}"

    shots = []
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": 1440, "height": 900})
        for u in urls:
            fn = out_dir / (u.replace("https://", "").replace("http://", "").replace("/", "_").strip("_") + ".png")
            page.goto(u, wait_until="networkidle", timeout=60000)
            time.sleep(1.0)
            page.screenshot(path=str(fn), full_page=True)
            shots.append({"url": u, "file": fn.name})
        browser.close()
    return True, shots

def write_html(base, shots, out_dir: Path, note: str):
    html = ["<!doctype html><html><head><meta charset='utf-8'/>",
            "<meta name='viewport' content='width=device-width,initial-scale=1'/>",
            "<title>Vire V5 Screenshot Report</title>",
            "<style>body{font-family:Inter,system-ui,Segoe UI,Arial,sans-serif;background:#0A1A4A;color:#fff;margin:0} .wrap{max-width:1100px;margin:0 auto;padding:22px 14px} .card{background:rgba(27,34,53,.62);border:1px solid rgba(62,70,93,.75);border-radius:18px;padding:14px;margin:12px 0} img{max-width:100%;border-radius:12px;border:1px solid rgba(255,255,255,.12)}</style>",
            "</head><body><div class='wrap'>",
            f"<h1>Vire V5 — Screenshot Report</h1><p>Base: {base}<br/>Generated: {utc_now()}</p>",
            f"<div class='card'><strong>Note:</strong> {note}</div>"]
    for s in shots:
        html.append("<div class='card'>")
        html.append(f"<div><a style='color:#3AF4D3' href='{s['url']}'>{s['url']}</a></div>")
        html.append(f"<img src='{s['file']}' alt='screenshot'/>")
        html.append("</div>")
    html.append("</div></body></html>")
    (out_dir / "report.html").write_text("\n".join(html), encoding="utf-8")

def main():
    if len(sys.argv) < 3:
        print("Usage: screenshot_report.py <base_url> <out_dir>")
        return 1

    base = sys.argv[1].rstrip("/")
    out_dir = Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)

    urls = [
        base + "/",
        base + "/products/",
        base + "/atmasphere-llm/",
        base + "/dating-platform-builder/",
        base + "/quantum-secure-finance/",
    ]

    ok, result = try_playwright(urls, out_dir)
    if ok:
        write_html(base, result, out_dir, "Screenshots captured with Playwright.")
        print("✅ report.html written:", out_dir / "report.html")
        return 0

    # Fallback: no screenshots, but still output a report
    write_html(base, [], out_dir, "Playwright not installed; no screenshots captured. Install with: pip install playwright && playwright install chromium")
    print("⚠️ report.html written without screenshots:", out_dir / "report.html")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
