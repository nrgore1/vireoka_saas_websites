#!/usr/bin/env python3
import pathlib, json, datetime

pages = list(pathlib.Path("vire-agent/export/pages").glob("*.html"))
html = f"<h1>Vire Dashboard</h1><p>Pages: {len(pages)}</p>"
out = pathlib.Path(__file__).parent / "dashboard.html"
out.write_text(html)
print("✅ Dashboard rendered")
