#!/usr/bin/env bash
set -euo pipefail
echo "✅ Vire 6 Quickstart"
echo
echo "1) Normal sync:"
echo "   ./vsync.sh all"
echo
echo "2) Simulate:"
echo "   ./vsync.sh simulate"
echo
echo "3) Plan:"
echo "   ./vsync.sh plan"
echo
echo "4) Explain (LLM if OPENAI_API_KEY set; fallback otherwise):"
echo "   ./vsync.sh explain"
echo
echo "5) Apply-safe (guarded):"
echo "   ./vsync.sh apply-safe"
echo
echo "Policy file:"
echo "   vire_policy/vire_policy.yaml"
echo
