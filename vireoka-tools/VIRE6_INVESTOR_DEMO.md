# Vire 6 — Investor Demo Pack (Vireoka LLC)

## One-liner
**Vire** is a governed AI DevOps agent for WordPress that syncs environments safely, explains conflicts in plain English, produces an auditable resolution plan, and can auto-apply only low-risk changes under policy.

## Why it matters
- WordPress powers a huge share of startup and SMB sites.
- DevOps + content changes create constant drift.
- AI without governance is dangerous; Vire 6 is **autonomy-with-brakes**.

## Demo Flow (3 minutes)
1) Run sync (as usual):
   - `./vsync.sh all`
2) Simulate:
   - `./vsync.sh simulate`
3) Plan:
   - `./vsync.sh plan`
4) Explain (LLM-backed if OPENAI_API_KEY is set; fallback otherwise):
   - `./vsync.sh explain`
5) Apply-safe:
   - `./vsync.sh apply-safe`

## Artifacts produced
- `_sync_status/status.json`
- `_sync_status/conflicts.json`
- `_sync_status/resolution_plan.json`
- `_sync_status/vire6_conflicts_explained.md`
- `_sync_status/decisions.log` (append-only audit)

## Governance advantage
- `vire_policy/vire_policy.yaml` is human-reviewable and git-tracked.
- Only **LOW risk + policy allowed** changes can be auto-applied.
- Everything else is escalated to manual review.

## Next upgrade (enterprise)
- Slack approvals for HIGH risk changes
- Signed release bundles for theme/plugin updates
- SBOM + malware scan hooks
