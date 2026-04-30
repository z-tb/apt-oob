#!/bin/bash
# Get sha256 checksum for the Nextcloud Talk linux-x64.zip asset.
# Usage: nextcloud-talk-verify.sh <version>
# Output: sha256:<hash>

VERSION="$1"
[ -z "$VERSION" ] && exit 1

# Find the .zip asset and grab its digest
HASH=$(curl -sf "https://api.github.com/repos/nextcloud-releases/talk-desktop/releases/tags/v${VERSION}" \
  | jq -r '.assets[] | select(.name == "Nextcloud.Talk-linux-x64.zip") | .digest')

[ -z "$HASH" ] && exit 1
echo "$HASH"
