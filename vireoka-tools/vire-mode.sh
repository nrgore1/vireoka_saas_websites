#!/usr/bin/env bash
set -e

MODE="$1"

case "$MODE" in
  review)
    cat _sync_status/ai_conflicts_report.md
    ;;
  plan)
    cat _sync_status/resolution_plan.json | jq .
    ;;
  explain)
    cat _sync_status/ai_conflicts_report.md
    ;;
  *)
    echo "Usage: $0 {review|plan|explain}"
    exit 1
    ;;
esac
