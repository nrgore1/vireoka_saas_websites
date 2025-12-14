#!/usr/bin/env bash
set -euo pipefail

# Prints sha256 of stdin or a file.
# Usage:
#   ./vsync-hash.sh < file
#   ./vsync-hash.sh path/to/file

hash_stdin() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    python3 - <<'PY'
import hashlib, sys
h=hashlib.sha256()
h.update(sys.stdin.buffer.read())
print(h.hexdigest())
PY
  fi
}

hash_file() {
  local f="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  else
    python3 - <<PY
import hashlib
p=r"""$f"""
h=hashlib.sha256()
with open(p,"rb") as fp: h.update(fp.read())
print(h.hexdigest())
PY
  fi
}

if [ $# -eq 0 ]; then
  hash_stdin
else
  hash_file "$1"
fi
