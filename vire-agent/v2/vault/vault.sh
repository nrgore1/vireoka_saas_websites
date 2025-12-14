#!/usr/bin/env bash
set -euo pipefail
VAULT=".vault.env"

case "${1:-}" in
  init)
    touch "$VAULT"
    chmod 600 "$VAULT"
    echo "✅ Vault initialized"
    ;;
  set)
    echo "$2=$3" >> "$VAULT"
    ;;
  print)
    cat "$VAULT"
    ;;
  *)
    echo "Usage: vault.sh {init|set|print}"
    ;;
esac
