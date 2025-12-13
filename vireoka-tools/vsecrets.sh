#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

# Order of precedence:
# 1) Exported env vars (REMOTE_HOST, REMOTE_USER, REMOTE_PORT, etc.)
# 2) HashiCorp Vault (if enabled and vault CLI exists)
# 3) Local .env.secrets file (not committed)
#
# This script exports variables into the current shell context.
# Use it like:
#   source ./vsecrets.sh

load_dotenv() {
  local f="$1"
  [ -f "$f" ] || return 0
  # shellcheck disable=SC2046
  export $(grep -v '^\s*#' "$f" | grep -E '^[A-Za-z_][A-Za-z0-9_]*=' | xargs -d '\n') || true
}

try_vault() {
  # Requires:
  #   VAULT_ADDR, VAULT_TOKEN (or VAULT_NAMESPACE etc.)
  #   VSECRETS_VAULT_ENABLED=true
  #   VSECRETS_VAULT_PATH like: secret/data/vireoka/sync
  #
  # Expected keys (example):
  #   REMOTE_HOST, REMOTE_USER, REMOTE_PORT
  command -v vault >/dev/null 2>&1 || return 1
  [ "${VSECRETS_VAULT_ENABLED:-false}" = "true" ] || return 1
  [ -n "${VSECRETS_VAULT_PATH:-}" ] || return 1

  # kv v2 returns data.data.<key>. We use jq if present, else crude parsing.
  if command -v jq >/dev/null 2>&1; then
    local json
    json="$(vault kv get -format=json "$VSECRETS_VAULT_PATH" 2>/dev/null || true)"
    [ -n "$json" ] || return 1
    export REMOTE_HOST="${REMOTE_HOST:-$(echo "$json" | jq -r '.data.data.REMOTE_HOST // empty')}"
    export REMOTE_USER="${REMOTE_USER:-$(echo "$json" | jq -r '.data.data.REMOTE_USER // empty')}"
    export REMOTE_PORT="${REMOTE_PORT:-$(echo "$json" | jq -r '.data.data.REMOTE_PORT // empty')}"
    export WEBHOOK_URL="${WEBHOOK_URL:-$(echo "$json" | jq -r '.data.data.WEBHOOK_URL // empty')}"
    export OPENAI_API_KEY="${OPENAI_API_KEY:-$(echo "$json" | jq -r '.data.data.OPENAI_API_KEY // empty')}"
  else
    # Minimal fallback if jq not installed (Vault CLI still useful for raw output)
    # Recommend installing jq for clean parsing.
    local raw
    raw="$(vault kv get "$VSECRETS_VAULT_PATH" 2>/dev/null || true)"
    [ -n "$raw" ] || return 1
  fi

  return 0
}

# Load .env.secrets (optional), then try Vault to fill missing, then confirm minimal set.
load_dotenv "$BASE_DIR/.env.secrets"
try_vault || true

# If vconfig has literals, env vars may already be set via vconfig.sh.
# We do not override existing values unless they are empty.

: "${REMOTE_HOST:=${REMOTE_HOST:-}}"
: "${REMOTE_USER:=${REMOTE_USER:-}}"
: "${REMOTE_PORT:=${REMOTE_PORT:-}}"

# Print summary (safe)
echo "🔐 Secrets loaded (safe summary):"
echo "  REMOTE_HOST=${REMOTE_HOST:-<unset>}"
echo "  REMOTE_USER=${REMOTE_USER:-<unset>}"
echo "  REMOTE_PORT=${REMOTE_PORT:-<unset>}"
echo "  WEBHOOK_URL=${WEBHOOK_URL:+<set>}"
echo "  OPENAI_API_KEY=${OPENAI_API_KEY:+<set>}"
