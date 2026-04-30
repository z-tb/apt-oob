#!/bin/bash
# Get sha256 checksum for the bat linux-x86_64 tarball.
# Usage: bat-verify.sh <version>
# Output: sha256:<hash>

VERSION="$1"
[ -z "$VERSION" ] && exit 1

ASSET="bat-v${VERSION}-x86_64-unknown-linux-gnu.tar.gz"

# Find the matching asset and grab its digest
HASH=$(curl -sf "https://api.github.com/repos/sharkdp/bat/releases/tags/v${VERSION}" \
  | jq -r --arg name "$ASSET" '.assets[] | select(.name == $name) | .digest')

[ -z "$HASH" ] && exit 1
echo "$HASH"
