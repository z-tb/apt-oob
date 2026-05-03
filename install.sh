#!/bin/bash
set -euo pipefail

OOB_BASE="/usr/local/apt-oob"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
    echo "install.sh must be run as root"
    exit 1
fi

# Run oob init first (creates dirs, copies binary, writes config + hook)
"${SCRIPT_DIR}/bin/oob" init -f

# Copy package configs and scripts from repo
for dir in conf.d checkver checksum dload keys; do
    src="${SCRIPT_DIR}/${dir}"
    dest="${OOB_BASE}/${dir}"
    [[ -d "$src" ]] || continue
    # Only copy files that exist in the repo
    for f in "$src"/*; do
        [[ -f "$f" ]] || continue
        # Skip if repo lives inside OOB_BASE (source and dest are the same file)
        [[ "$(realpath "$f")" == "$(realpath "$dest/$(basename "$f")" 2>/dev/null)" ]] && continue
        cp "$f" "$dest/"
        chmod +x "$dest/$(basename "$f")" 2>/dev/null || true
        echo "  installed: ${dest}/$(basename "$f")"
    done
done

# Symlink oob into PATH
OOB_BIN="${OOB_BASE}/bin/oob"
if echo "$PATH" | tr ':' '\n' | grep -qx "/usr/local/bin"; then
    ln -sf "$OOB_BIN" /usr/local/bin/oob
    echo "  symlinked: /usr/local/bin/oob"
elif echo "$PATH" | tr ':' '\n' | grep -qx "/usr/bin"; then
    ln -sf "$OOB_BIN" /usr/bin/oob
    echo "  symlinked: /usr/bin/oob"
else
    ln -sf "$OOB_BIN" /bin/oob
    echo "  symlinked: /bin/oob"
fi

# Install man page
if [[ -f "${SCRIPT_DIR}/man/oob.1" ]]; then
    mkdir -p /usr/local/share/man/man1
    cp "${SCRIPT_DIR}/man/oob.1" /usr/local/share/man/man1/oob.1
    mandb -q 2>/dev/null || true
    echo "  installed: /usr/local/share/man/man1/oob.1"
fi

echo ""
echo "apt-oob installed to ${OOB_BASE}"
echo "run 'oob update' to see available packages"
