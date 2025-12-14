#!/usr/bin/env bash
set -euo pipefail

VAULT="vire-agent/v2/vault/.vault.env"
if [ -f "$VAULT" ]; then
  # shellcheck disable=SC1090
  set -a
  source "$VAULT"
  set +a
fi
