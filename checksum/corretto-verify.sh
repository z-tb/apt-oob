#!/bin/bash
# Get sha256 checksum for the latest Corretto 26 linux-x64 tarball.
# Usage: corretto-verify.sh <version>
# Output: sha256:<hash>

VERSION="$1"
[ -z "$VERSION" ] && exit 1

HASH=$(curl -sf "https://corretto.aws/downloads/latest_sha256/amazon-corretto-26-x64-linux-jdk.tar.gz")

[ -z "$HASH" ] && exit 1
echo "sha256:${HASH}"
