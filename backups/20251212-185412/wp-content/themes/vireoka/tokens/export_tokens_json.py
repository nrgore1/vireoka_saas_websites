import json, re, pathlib

css_path = pathlib.Path(__file__).parent / "design-tokens.css"
text = css_path.read_text(encoding="utf-8")

# Capture --var: value; inside :root
root_block = re.search(r":root\\s*\\{([\\s\\S]*?)\\}", text)
vars_dict = {}
if root_block:
  for m in re.finditer(r"--([a-zA-Z0-9\\-]+)\\s*:\\s*([^;]+);", root_block.group(1)):
    vars_dict[m.group(1)] = m.group(2).strip()

out = {
  "name": "Vireoka Elite Neural Luxe Tokens",
  "source": "design-tokens.css",
  "tokens": vars_dict
}

out_path = pathlib.Path(__file__).parent / "design-tokens.figma.json"
out_path.write_text(json.dumps(out, indent=2), encoding="utf-8")
print(f"Wrote: {out_path}")
