#!/bin/bash
# Automated Vireoka file copier

WP_ROOT=$(pwd)

copy_file() {
    SRC="$1"
    DEST="$2"
    echo "Copying $SRC → $DEST"
    mkdir -p "$(dirname "$DEST")"
    cp "$SRC" "$DEST"
}

# Example usage:
#   ./copy_vireoka_files.sh file1.php wp-content/plugins/vireoka-home-builder/includes/file1.php

if [ "$#" -ne 2 ]; then
    echo "Usage: ./copy_vireoka_files.sh <local-file> <wp-path>"
    exit 1
fi

LOCAL="$1"
TARGET="$WP_ROOT/$2"

copy_file "$LOCAL" "$TARGET"
