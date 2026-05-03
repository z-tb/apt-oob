#!/bin/bash
# live-update.sh - push local repo files to a live oob installation.
#
# Development tool for syncing code changes to a running system without
# a full reinstall. Copies bin, scripts, and configs via rsync.
# Configs that are .disabled on the target are skipped to preserve
# the target's package selection.
#
# Usage:
#   ./live-update.sh /usr/local/apt-oob
#   ./live-update.sh root@remote:/usr/local/apt-oob

set -euo pipefail

DEST="${1:?Usage: live-update.sh <dest>}"

rsync -av bin/       "$DEST/bin/"
rsync -av checkver/  "$DEST/checkver/"
rsync -av checksum/  "$DEST/checksum/"
rsync -av dload/     "$DEST/dload/"
rsync -av keys/      "$DEST/keys/"

# conf.d: skip files that are disabled on the target
if [[ "$DEST" == *:* ]]; then
    HOST="${DEST%%:*}"
    RPATH="${DEST#*:}"
    REMOTE_LS="ssh $HOST ls ${RPATH}/conf.d/ 2>/dev/null"
else
    REMOTE_LS="ls ${DEST}/conf.d/ 2>/dev/null"
fi

EXCLUDES=()
for f in $(eval "$REMOTE_LS" || true); do
    if [[ "$f" == *.disabled ]]; then
        EXCLUDES+=(--exclude="${f%.disabled}")
    fi
done

rsync -av "${EXCLUDES[@]}" conf.d/ "$DEST/conf.d/"

# Fix permissions after sync
if [[ "$DEST" == *:* ]]; then
    HOST="${DEST%%:*}"
    RPATH="${DEST#*:}"
    ssh "$HOST" "chown -R root:root ${RPATH} && find ${RPATH} -type d -exec chmod 755 {} + && find ${RPATH} -name '*.sh' -o -path '*/bin/oob' | xargs chmod 755 && find ${RPATH}/conf.d -type f ! -name '*.sh' -exec chmod 644 {} +"
else
    chown -R root:root "$DEST"
    find "$DEST" -type d -exec chmod 755 {} +
    find "$DEST" \( -name '*.sh' -o -path '*/bin/oob' \) -exec chmod 755 {} +
    find "$DEST/conf.d" -type f ! -name '*.sh' -exec chmod 644 {} +
fi
echo "permissions fixed"
