#!/usr/bin/env bash
set -e

PATCH_FILE="$1"
MISSING_FILE="missing_files.txt"
ROOT="/mnt/c/Projects2025/atmasphere-llm-site"

if [[ -z "$PATCH_FILE" ]]; then
    echo "Usage: $0 <patch-file>"
    exit 1
fi

if [[ ! -f "$MISSING_FILE" ]]; then
    echo "❌ missing_files.txt not found. Run verify_atmasphere_install.sh first."
    exit 1
fi

echo "📁 Repo root: $ROOT"
echo "📄 Reading patch: $PATCH_FILE"
echo "📄 Installing only missing files from: $MISSING_FILE"
echo

# Convert missing_files into a lookup map
declare -A WANT
while read -r f; do
    [[ -n "$f" ]] && WANT["$f"]=1
done < "$MISSING_FILE"

TMP="/tmp/atmasphere_tmp.txt"
> "$TMP"

IN_BLOCK=0
TARGET=""
MODE=">"

process_block() {
    OUT="$ROOT/$TARGET"
    DIR=$(dirname "$OUT")

    mkdir -p "$DIR"

    if [[ "$MODE" == ">" ]]; then
        cp "$TMP" "$OUT"
    else
        touch "$OUT"
        cat "$TMP" >> "$OUT"
    fi

    echo "💾 Installed: $TARGET"
}

while IFS='' read -r line || [[ -n "$line" ]]; do

    #############################################################
    # Detect start of heredoc: cat > file << 'EOF'
    #############################################################
    if echo "$line" | grep -Eq "^cat[[:space:]]*>[[:space:]]+[^[:space:]]+[[:space:]]+<<[[:space:]]*'EOF'"; then
        TARGET=$(echo "$line" | awk '{print $3}')
        MODE=">"
        IN_BLOCK=0

        # Only start capturing if this target is wanted
        if [[ ${WANT["$TARGET"]+found} ]]; then
            IN_BLOCK=1
            > "$TMP"
            echo "✏️  Capturing block for: $TARGET"
        else
            IN_BLOCK=0
        fi
        continue
    fi

    #############################################################
    # Detect start of append heredoc: cat >> file << 'EOF'
    #############################################################
    if echo "$line" | grep -Eq "^cat[[:space:]]*>>[[:space:]]+[^[:space:]]+[[:space:]]+<<[[:space:]]*'EOF'"; then
        TARGET=$(echo "$line" | awk '{print $3}')
        MODE=">>"
        IN_BLOCK=0

        if [[ ${WANT["$TARGET"]+found} ]]; then
            IN_BLOCK=1
            > "$TMP"
            echo "✏️  Capturing APPEND block for: $TARGET"
        else
            IN_BLOCK=0
        fi
        continue
    fi

    #############################################################
    # End of heredoc
    #############################################################
    if [[ "$line" == "EOF" ]]; then
        if [[ "$IN_BLOCK" -eq 1 ]]; then
            process_block
        fi
        IN_BLOCK=0
        TARGET=""
        continue
    fi

    #############################################################
    # Capture lines inside a block
    #############################################################
    if [[ "$IN_BLOCK" -eq 1 ]]; then
        echo "$line" >> "$TMP"
    fi

done < "$PATCH_FILE"

echo
echo "✅ Selective patch application complete."
