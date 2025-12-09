#!/usr/bin/env python3
# atmasphere_patcher.py

import os
import re
import json
import hashlib
import argparse
import sys
import shutil
import difflib
import subprocess
from datetime import datetime
from typing import Dict, Tuple, List, Optional

# -----------------------------
# Color Codes
# -----------------------------
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BLUE = "\033[94m"
RESET = "\033[0m"

# -----------------------------
# Utility: print colored
# -----------------------------
def info(msg: str) -> None:
    print(f"{BLUE}ℹ️  {msg}{RESET}")

def ok(msg: str) -> None:
    print(f"{GREEN}✔ {msg}{RESET}")

def warn(msg: str) -> None:
    print(f"{YELLOW}⚠️  {msg}{RESET}")

def err(msg: str) -> None:
    print(f"{RED}❌ {msg}{RESET}")

# -----------------------------
# Utility: run shell commands
# -----------------------------
def run_cmd(cmd: List[str], cwd: Optional[str] = None, allow_fail: bool = False) -> subprocess.CompletedProcess:
    """Run a shell command with basic logging."""
    info(f"Running: {' '.join(cmd)} (cwd={cwd or os.getcwd()})")
    result = subprocess.run(cmd, cwd=cwd, text=True, capture_output=True)
    if result.returncode != 0:
        if not allow_fail:
            err(f"Command failed ({result.returncode}): {' '.join(cmd)}")
            if result.stdout:
                print(result.stdout)
            if result.stderr:
                print(result.stderr, file=sys.stderr)
            raise RuntimeError("Command failed")
        else:
            warn(f"Command failed but tolerated ({result.returncode}): {' '.join(cmd)}")
            if result.stdout:
                print(result.stdout)
            if result.stderr:
                print(result.stderr, file=sys.stderr)
    return result

# -----------------------------
# Compute SHA256
# -----------------------------
def sha256_of(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()

def hmac_sha256(key: str, payload: str) -> str:
    # Simple HMAC-like derivation using sha256(key || payload)
    return hashlib.sha256((key + payload).encode("utf-8")).hexdigest()

# -----------------------------
# Load checksums safely (handles legacy, empty, HMAC)
# -----------------------------
def load_checksums(checksum_file: str, checksum_key: Optional[str], lockdown: bool) -> Tuple[Dict[str, str], Dict]:
    """
    Returns (files_checksums, meta_info).
    Supports:
      - legacy: {"file": "hash", ...}
      - new: {"version": 1, "files": {...}, "hmac": "..."}
    """
    if not os.path.exists(checksum_file):
        warn("No checksum file found — starting fresh.")
        return {}, {}

    try:
        with open(checksum_file, "r", encoding="utf-8") as f:
            raw = f.read().strip()
        if not raw:
            warn("Checksum file is empty — resetting.")
            return {}, {}

        data = json.loads(raw)
    except Exception as e:
        warn(f"Failed to load checksum file ({e}) — starting fresh.")
        return {}, {}

    # Legacy format: simple mapping
    if isinstance(data, dict) and "files" not in data:
        return data, {}

    # New format with HMAC
    files = data.get("files", {})
    stored_hmac = data.get("hmac")
    meta = {"version": data.get("version", 1), "hmac": stored_hmac}

    if checksum_key and stored_hmac:
        payload = json.dumps(files, sort_keys=True)
        expected = hmac_sha256(checksum_key, payload)
        if expected != stored_hmac:
            err("Checksum HMAC mismatch! Checksum file may have been tampered with.")
            if lockdown:
                err("Lockdown mode enabled — aborting due to checksum tampering.")
                sys.exit(1)
            else:
                warn("Continuing despite HMAC mismatch (lockdown disabled).")

    return files, meta

# -----------------------------
# Save checksums (with optional HMAC)
# -----------------------------
def save_checksums(checksum_file: str, checksums: Dict[str, str], checksum_key: Optional[str]) -> None:
    os.makedirs(os.path.dirname(checksum_file), exist_ok=True)
    # Try to put checksum file in repo root; if dirname is empty, just use file
    checksum_dir = os.path.dirname(checksum_file)
    if checksum_dir and not os.path.exists(checksum_dir):
        os.makedirs(checksum_dir, exist_ok=True)

    if checksum_key:
        payload = json.dumps(checksums, sort_keys=True)
        sig = hmac_sha256(checksum_key, payload)
        data = {"version": 1, "files": checksums, "hmac": sig}
    else:
        data = checksums

    with open(checksum_file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    ok(f"Checksums updated → {checksum_file}")

# -----------------------------
# Parse patch file
# Supports:
#   1) === FILE: path ===
#   2) cat << 'EOF' > path ... EOF
# -----------------------------
def parse_patch(patch_file: str) -> List[Tuple[str, str]]:
    blocks: List[Tuple[str, str]] = []

    with open(patch_file, "r", encoding="utf-8") as f:
        text = f.read()

    # Mode 1: === FILE: path === blocks
    pattern_file = re.compile(r"=== FILE: (.*?) ===")
    parts = pattern_file.split(text)
    if len(parts) > 1:
        # parts = [before, fname1, content1, fname2, content2, ...]
        for i in range(1, len(parts), 2):
            fname = parts[i].strip()
            if i + 1 < len(parts):
                content = parts[i + 1]
            else:
                content = ""
            blocks.append((fname, content))
        info(f"Found {len(blocks)} patch blocks using '=== FILE:' format.")
        return blocks

    # Mode 2: cat << 'EOF' > path ... EOF (Option A strict mode)
    pattern_cat = re.compile(
        r"cat\s+<<\s*'EOF'\s*>\s*(.+?)\s*[\r\n]+(.*?)[\r\n]+EOF",
        re.DOTALL,
    )
    for m in pattern_cat.finditer(text):
        fname = m.group(1).strip()
        content = m.group(2)
        # Normalise to end with newline
        if not content.endswith("\n"):
            content = content + "\n"
        blocks.append((fname, content))

    if blocks:
        info(f"Detected {len(blocks)} cat-EOF blocks (Option A strict mode).")
    else:
        warn("No recognizable patch blocks found in patch file.")

    return blocks

# -----------------------------
# Backup before write
# -----------------------------
def backup_file(full_path: str, backup_dir: str) -> Optional[str]:
    if os.path.exists(full_path):
        os.makedirs(backup_dir, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_name = f"{os.path.basename(full_path)}.{timestamp}.bak"
        backup_path = os.path.join(backup_dir, backup_name)
        shutil.copy(full_path, backup_path)
        info(f"Backup saved → {backup_path}")
        return backup_path
    return None

# -----------------------------
# Check for patch conflicts
# -----------------------------
def detect_conflict(filename: str, existing_content: str, new_content: str) -> bool:
    if existing_content.strip() and existing_content.strip() != new_content.strip():
        return True
    return False

# -----------------------------
# Diff viewer
# -----------------------------
def show_diff(filename: str, old: str, new: str) -> None:
    diff = difflib.unified_diff(
        old.splitlines(keepends=True),
        new.splitlines(keepends=True),
        fromfile=f"{filename} (old)",
        tofile=f"{filename} (new)",
    )
    print("".join(diff))

# -----------------------------
# YAML validation (optional)
# -----------------------------
def validate_yaml_if_needed(filename: str, content: str) -> None:
    if not filename.endswith((".yml", ".yaml")):
        return
    try:
        import yaml  # type: ignore
    except ImportError:
        warn(f"YAML validation skipped for {filename} (PyYAML not installed).")
        return
    try:
        yaml.safe_load(content)
        ok(f"YAML validated → {filename}")
    except Exception as e:
        warn(f"YAML parse error in {filename}: {e}")

# -----------------------------
# Apply patch
# -----------------------------
def apply_patch(
    root: str,
    blocks: List[Tuple[str, str]],
    checksums: Dict[str, str],
    mode: str,
    dry_run: bool,
    verbose: bool,
    interactive: bool,
    show_diffs: bool,
    lockdown: bool,
) -> Dict[str, int]:
    summary = {
        "created": 0,
        "updated": 0,
        "appended": 0,
        "unchanged": 0,
        "blocked": 0,
        "conflicts": 0,
    }

    backup_dir = os.path.join(root, ".atmasphere", "backups")

    total = len(blocks)
    print(f"{BLUE}Applying patch ({total} files)…{RESET}")

    for idx, (filename, new_content) in enumerate(blocks, start=1):
        full_path = os.path.join(root, filename)
        os.makedirs(os.path.dirname(full_path), exist_ok=True)

        new_hash = sha256_of(new_content)
        old_hash = checksums.get(filename)

        # Progress
        progress = f"[{idx}/{total}]"
        print(f"{BLUE}{progress}{RESET} {filename}")

        existing_content = ""
        file_exists = os.path.exists(full_path)

        if file_exists:
            with open(full_path, "r", encoding="utf-8") as f:
                existing_content = f.read()

            # Integrity lock: if content differs from recorded checksum, block
            if lockdown and old_hash is not None:
                current_hash = sha256_of(existing_content)
                if current_hash != old_hash:
                    err(f"Integrity lock: {filename} content differs from recorded checksum — skipping.")
                    summary["blocked"] += 1
                    continue

            if detect_conflict(filename, existing_content, new_content):
                warn(f"Conflict detected → {filename}")
                summary["conflicts"] += 1

        # Determine if unchanged
        if old_hash == new_hash and file_exists:
            summary["unchanged"] += 1
            if verbose:
                info(f"Unchanged: {filename}")
            continue

        # Optional diff printing
        if show_diffs and file_exists and existing_content != new_content:
            show_diff(filename, existing_content, new_content)

        # Interactive mode
        if interactive and (not file_exists or existing_content != new_content):
            while True:
                choice = input(
                    f"[{filename}] Apply change? [y]es / [n]o / [d]iff / [q]uit: "
                ).strip().lower()
                if choice == "d":
                    show_diff(filename, existing_content, new_content)
                elif choice == "y":
                    break
                elif choice == "n":
                    warn(f"Skipped by user → {filename}")
                    summary["blocked"] += 1
                    filename_hash = checksums.get(filename)
                    # Do not update checksum; treat as unchanged in DB
                    break  # skip write
                elif choice == "q":
                    warn("User aborted in interactive mode.")
                    return summary
                else:
                    print("Please enter y / n / d / q.")
            # If user chose 'n', we already incremented blocked and continue
            if choice == "n":
                continue

        # Append mode
        if file_exists and mode == "append":
            summary["appended"] += 1
            if not dry_run:
                backup_file(full_path, backup_dir)
                with open(full_path, "a", encoding="utf-8") as f:
                    f.write("\n" + new_content)
                with open(full_path, "r", encoding="utf-8") as f2:
                    final_content = f2.read()
                checksums[filename] = sha256_of(final_content)
                validate_yaml_if_needed(filename, final_content)
            ok(f"Appended → {filename}")
            continue

        # Overwrite or create
        action = "created" if not file_exists else "updated"
        summary[action] += 1

        if not dry_run:
            backup_file(full_path, backup_dir)
            with open(full_path, "w", encoding="utf-8") as f:
                f.write(new_content)
            checksums[filename] = new_hash
            validate_yaml_if_needed(filename, new_content)

        ok(f"{action.capitalize()} → {filename}")

    return summary

# -----------------------------
# mkdocs bootstrap
# -----------------------------
def ensure_mkdocs(root: str, docs_related: bool, dry_run: bool) -> None:
    if not docs_related or dry_run:
        return

    mkdocs_path = os.path.join(root, "mkdocs.yml")
    docs_dir = os.path.join(root, "docs")
    index_path = os.path.join(docs_dir, "index.md")

    if not os.path.exists(mkdocs_path):
        info("mkdocs.yml not found — creating a minimal AtmaSphere config.")
        os.makedirs(docs_dir, exist_ok=True)
        mkdocs_content = """site_name: AtmaSphere LLM Docs
site_description: "Documentation for the AtmaSphere-LLM conscious stack"
nav:
  - Home: index.md
theme:
  name: material
"""
        with open(mkdocs_path, "w", encoding="utf-8") as f:
            f.write(mkdocs_content)
        ok("Created mkdocs.yml")

    if not os.path.exists(index_path):
        info("docs/index.md not found — creating a starter page.")
        os.makedirs(docs_dir, exist_ok=True)
        index_content = """# AtmaSphere-LLM Documentation

Welcome to the AtmaSphere-LLM docs.

This site covers:

- Architecture of the conscious LLM stack
- RAG services
- Alignment and council orchestration
- Governance, safety, and evaluation
"""
        with open(index_path, "w", encoding="utf-8") as f:
            f.write(index_content)
        ok("Created docs/index.md")

# -----------------------------
# Docker build/push for docs
# -----------------------------
def build_and_push_docs_image(root: str) -> None:
    docs_dir = os.path.join(root, "docs")
    dockerfile_path = os.path.join(docs_dir, "Dockerfile")
    if not os.path.exists(dockerfile_path):
        warn("Docs Dockerfile not found at docs/Dockerfile — skipping Docker image build.")
        return

    image_name = os.environ.get("ATMASPHERE_DOCS_IMAGE", "nrgore1/atmasphere-docs:latest")
    docker_user = os.environ.get("DOCKERHUB_USERNAME")
    docker_token = os.environ.get("DOCKERHUB_TOKEN")

    try:
        # Optional login
        if docker_user and docker_token:
            run_cmd(["docker", "login", "-u", docker_user, "--password-stdin"], cwd=root, allow_fail=False).stdin
        else:
            warn("DOCKERHUB_USERNAME/DOCKERHUB_TOKEN not set — will build locally but not push.")

        # Build
        run_cmd(["docker", "build", "-t", image_name, "."], cwd=docs_dir, allow_fail=False)
        ok(f"Docker image built → {image_name}")

        # Push if credentials available
        if docker_user and docker_token:
            run_cmd(["docker", "push", image_name], cwd=docs_dir, allow_fail=False)
            ok(f"Docker image pushed → {image_name}")
        else:
            info("Skipping docker push (no registry credentials).")
    except Exception as e:
        warn(f"Docs image build/push failed: {e}")

# -----------------------------
# Git auto-commit + push
# -----------------------------
def git_commit_and_push(root: str, summary: Dict[str, int], no_git_push: bool) -> None:
    try:
        # Any changes?
        result = run_cmd(["git", "status", "--porcelain"], cwd=root, allow_fail=True)
        if result.returncode != 0:
            warn("git status failed — skipping auto-commit.")
            return
        if not result.stdout.strip():
            info("No git changes to commit.")
            return

        run_cmd(["git", "add", "."], cwd=root, allow_fail=False)
        msg = f"AtmaSphere patch applied ({datetime.now().isoformat(timespec='seconds')})"
        commit_res = run_cmd(["git", "commit", "-m", msg], cwd=root, allow_fail=True)
        if commit_res.returncode != 0:
            if "nothing to commit" in (commit_res.stderr or ""):
                info("Nothing to commit after patch.")
                return
            else:
                warn("git commit failed — skipping push.")
                return
        ok("Git commit created.")

        if not no_git_push:
            try:
                run_cmd(["git", "push"], cwd=root, allow_fail=False)
                ok("Git push completed.")
            except Exception as e:
                warn(f"Git push failed: {e}")
    except Exception as e:
        warn(f"Git auto-commit/push encountered an error: {e}")

# -----------------------------
# Cloudflare Zero-Trust preflight (placeholder)
# -----------------------------
def cloudflare_preflight_placeholder() -> None:
    """
    Placeholder for future Cloudflare Zero-Trust preflight checks.

    Uses environment variables:
      CF_ACCOUNT_ID
      CF_ZONE_ID
      CF_API_TOKEN

    Currently: only checks for presence and prints guidance.
    """
    cf_account = os.environ.get("CF_ACCOUNT_ID", "")
    cf_zone = os.environ.get("CF_ZONE_ID", "")
    cf_token = os.environ.get("CF_API_TOKEN", "")

    if not (cf_account or cf_zone or cf_token):
        info("Cloudflare preflight skipped (CF_ACCOUNT_ID / CF_ZONE_ID / CF_API_TOKEN not set).")
        return

    if not (cf_account and cf_zone and cf_token):
        warn("Cloudflare vars partially set — please configure CF_ACCOUNT_ID, CF_ZONE_ID, CF_API_TOKEN for full checks.")
        return

    info("Cloudflare Zero-Trust preflight placeholder:")
    info(f"  CF_ACCOUNT_ID = {cf_account}")
    info(f"  CF_ZONE_ID    = {cf_zone}")
    info("  CF_API_TOKEN  = *** (hidden)")
    info("No API calls are made yet; this is a stub for future hardening.")

# -----------------------------
# Checksum validation mode (CI/CD)
# -----------------------------
def validate_checksums_only(root: str, checksum_file: str, checksum_key: Optional[str], lockdown: bool) -> int:
    checksums, meta = load_checksums(checksum_file, checksum_key, lockdown)
    if not checksums:
        warn("No checksums to validate (file missing or empty).")
        return 0

    invalid = 0
    for filename, recorded_hash in checksums.items():
        full_path = os.path.join(root, filename)
        if not os.path.exists(full_path):
            err(f"Missing file recorded in checksums: {filename}")
            invalid += 1
            continue
        try:
            with open(full_path, "r", encoding="utf-8") as f:
                content = f.read()
        except Exception as e:
            err(f"Failed to read {filename}: {e}")
            invalid += 1
            continue
        current_hash = sha256_of(content)
        if current_hash != recorded_hash:
            err(f"Checksum mismatch: {filename}")
            invalid += 1

    if invalid == 0:
        ok("All files match their recorded checksums.")
    else:
        err(f"{invalid} file(s) failed checksum validation.")
    return invalid

# -----------------------------
# Main
# -----------------------------
def main() -> None:
    parser = argparse.ArgumentParser(description="AtmaSphere Patch Tool (Enhanced)")

    parser.add_argument("--patch", required=True, help="Path to patch.txt file")
    parser.add_argument("--root", required=True, help="Repo root to apply patch")
    parser.add_argument("--mode", choices=["overwrite", "append"], default="overwrite")
    parser.add_argument("--dry-run", action="store_true", help="Do not write any files")
    parser.add_argument("--verbose", action="store_true", help="Verbose logging")
    parser.add_argument("--force", action="store_true", help="Run even if root is not a git repo")
    parser.add_argument("--interactive", action="store_true", help="Ask before modifying each file")
    parser.add_argument("--show-diff", action="store_true", help="Print unified diff for changed files")
    parser.add_argument("--lockdown", action="store_true", help="Refuse to modify files whose content differs from recorded checksums")
    parser.add_argument("--validate-only", action="store_true", help="Only validate checksums; do not apply patches")
    parser.add_argument("--no-git-commit", action="store_true", help="Disable auto git commit after patch")
    parser.add_argument("--no-git-push", action="store_true", help="Disable auto git push after patch")
    parser.add_argument("--build-docs-image", action="store_true", help="Build (and optionally push) docs Docker image after patch")
    parser.add_argument("--cloudflare-preflight", action="store_true", help="Run Cloudflare Zero-Trust preflight placeholder")

    args = parser.parse_args()

    # Guard 1: ensure root is a git repo unless forced
    if not os.path.exists(os.path.join(args.root, ".git")) and not args.force:
        err("Refusing to run: target directory is not a Git repository.")
        print("Use --force if you really want to run it.")
        sys.exit(1)

    checksum_file = os.path.join(args.root, "atmasphere_checksums.json")
    checksum_key = os.environ.get("ATMASPHERE_CHECKSUM_KEY")

    # Validate-only mode (no patches)
    if args.validate_only:
        rc = validate_checksums_only(args.root, checksum_file, checksum_key, args.lockdown)
        sys.exit(1 if rc else 0)

    # Load checksums
    checksums, meta = load_checksums(checksum_file, checksum_key, args.lockdown)

    # Parse patch
    blocks = parse_patch(args.patch)
    info(f"Found {len(blocks)} patch blocks total.")

    if not blocks:
        warn("No blocks parsed from patch file — nothing to do.")
        sys.exit(0)

    docs_related = any(b[0].startswith("docs/") for b in blocks)

    # Apply patch
    summary = apply_patch(
        args.root,
        blocks,
        checksums,
        args.mode,
        args.dry_run,
        args.verbose,
        args.interactive,
        args.show_diff,
        args.lockdown,
    )

    # Ensure mkdocs bootstrap if docs touched
    ensure_mkdocs(args.root, docs_related, args.dry_run)

    # Save checksum file unless dry-run
    if not args.dry_run:
        save_checksums(checksum_file, checksums, checksum_key)

    # Optionally build/push docs Docker image
    if args.build_docs_image and not args.dry_run:
        build_and_push_docs_image(args.root)

    # Cloudflare Zero-Trust preflight (placeholder)
    if args.cloudflare_preflight:
        cloudflare_preflight_placeholder()

    # Auto git commit/push
    if not args.dry_run and not args.no_git_commit:
        git_commit_and_push(args.root, summary, args.no_git_push)

    # Summary
    print("\n" + BLUE + "────────── PATCH RESULT SUMMARY ──────────" + RESET)
    for k, v in summary.items():
        print(f"{k:12}: {v}")
    print(BLUE + "──────────────────────────────────────────" + RESET)


if __name__ == "__main__":
    main()
