#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
echo "Build options:"
echo "  1) HTML (open investor-memo.html)"
echo "  2) LaTeX (pdflatex investor-memo.tex) if pdflatex exists"
if command -v pdflatex >/dev/null 2>&1; then
  pdflatex -interaction=nonstopmode investor-memo.tex >/dev/null
  echo "Built: investor-memo.pdf"
else
  echo "pdflatex not found (install texlive-full if you want PDF build)."
fi
