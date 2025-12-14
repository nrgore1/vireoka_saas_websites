#!/usr/bin/env bash
set -euo pipefail
# Requires a LaTeX install (or run inside a latex docker image)
pdflatex investor_memo.tex
pdflatex investor_memo.tex
echo "✅ Built investor_memo.pdf"
