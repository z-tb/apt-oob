#!/bin/bash
# Fetch SHA512SUMS for the given version and extract the hash for the linux-x86_64 en-US tar.xz
VERSION="$1"
[ -z "$VERSION" ] && exit 1
URL="https://download-installer.cdn.mozilla.net/pub/firefox/releases/${VERSION}/SHA512SUMS"
HASH=$(curl -sf "$URL" | grep "linux-x86_64/en-US/firefox-${VERSION}.tar.xz" | awk '{print $1}')
[ -z "$HASH" ] && exit 1
echo "sha512:${HASH}"
