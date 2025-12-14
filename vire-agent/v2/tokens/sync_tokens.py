#!/usr/bin/env python3
import json, pathlib

src = pathlib.Path(__file__).parent / "figma_tokens.json"
out = pathlib.Path(__file__).parent / "figma_tokens.css"

colors = json.loads(src.read_text())["colors"]
css = ":root{\n" + "\n".join(
    f"  --v2-{k}:{v};" for k,v in colors.items()
) + "\n}"

out.write_text(css)
print("✅ Tokens synced")
