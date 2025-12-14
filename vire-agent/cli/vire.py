#!/usr/bin/env python3
import json, sys, subprocess, pathlib

if len(sys.argv) < 2:
    print("Usage: vire <site.json>")
    sys.exit(1)

spec_path = pathlib.Path(sys.argv[1])
if not spec_path.exists():
    raise SystemExit("❌ Spec file not found")

spec = json.load(open(spec_path))
site_id = spec.get("site_id", "site")

print(f"🧠 Generating site: {site_id}")

out = pathlib.Path("site.json")
out.write_text(json.dumps(spec, indent=2))

print("📦 Exporting static pages...")
subprocess.run(["python3", "vire-agent/export/wp_static_export.py"], check=True)

print("🎉 Site generation complete")
