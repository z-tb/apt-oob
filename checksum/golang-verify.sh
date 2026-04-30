#!/bin/bash
# Get the sha256 checksum for a Go linux/amd64 release tarball.
# Usage: golang-verify.sh <version>
# Output: sha256:<hash>

VERSION="$1"
[ -z "$VERSION" ] && exit 1

# The Go download page provides a known checksum file for each release
HASH=$(curl -sf "https://dl.google.com/go/go${VERSION}.linux-amd64.tar.gz.sha256")

[ -z "$HASH" ] && exit 1
echo "sha256:${HASH}"
