#!/bin/bash
# Get sha256 digest for the linux-x64.zip asset from GitHub API
VERSION="$1"
[ -z "$VERSION" ] && exit 1
HASH=$(curl -sf "https://api.github.com/repos/nextcloud-releases/talk-desktop/releases/tags/v${VERSION}" \
  | grep -B5 "linux-x64.zip" \
  | grep -oP '"sha256:\K[^"]+')
[ -z "$HASH" ] && exit 1
echo "sha256:${HASH}"
