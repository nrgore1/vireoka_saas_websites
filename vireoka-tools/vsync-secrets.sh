#!/usr/bin/env bash
set -euo pipefail

# Loads secrets into env for the sync suite.
# Priority:
#   1) HashiCorp Vault (if VAULT_ADDR + VAULT_TOKEN and vault CLI present)
#   2) .env.vireoka (local file next to this script)
#   3) Existing environment variables

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

load_dotenv_file() {
  local f="$1"
  [ -f "$f" ] || return 0
  # shellcheck disable=SC1090
  set -a
  . "$f"
  set +a
}

# 1) Vault (optional)
if command -v vault >/dev/null 2>&1 && [ -n "${VAULT_ADDR:-}" ] && [ -n "${VAULT_TOKEN:-}" ]; then
  # Configure what to read from Vault:
  # Example: secret/vireoka/sync => keys: REMOTE_HOST, REMOTE_USER, REMOTE_PORT
  VAULT_SECRET_PATH="${VAULT_SECRET_PATH:-secret/vireoka/sync}"

  echo "🔐 Loading secrets from Vault: $VAULT_SECRET_PATH"
  # These are safe best-effort; missing keys won't fail hard
  export REMOTE_HOST="${REMOTE_HOST:-$(vault kv get -field=REMOTE_HOST "$VAULT_SECRET_PATH" 2>/dev/null || true)}"
  export REMOTE_USER="${REMOTE_USER:-$(vault kv get -field=REMOTE_USER "$VAULT_SECRET_PATH" 2>/dev/null || true)}"
  export REMOTE_PORT="${REMOTE_PORT:-$(vault kv get -field=REMOTE_PORT "$VAULT_SECRET_PATH" 2>/dev/null || true)}"
  export WEBHOOK_URL="${WEBHOOK_URL:-$(vault kv get -field=WEBHOOK_URL "$VAULT_SECRET_PATH" 2>/dev/null || true)}"
fi

# 2) Local dotenv fallback
ENV_FILE="${VIREOKA_ENV_FILE:-$BASE_DIR/.env.vireoka}"
if [ -f "$ENV_FILE" ]; then
  echo "🔐 Loading secrets from: $ENV_FILE"
  load_dotenv_file "$ENV_FILE"
fi

# 3) Sanity output (do not print secrets)
echo "🔒 Secrets loaded (redacted). Remote user/host set: ${REMOTE_USER:-unset}@${REMOTE_HOST:-unset}:${REMOTE_PORT:-unset}"
