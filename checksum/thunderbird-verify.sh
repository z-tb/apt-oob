#!/bin/bash
VERSION="$1"
[ -z "$VERSION" ] && exit 1
URL="https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/${VERSION}/SHA512SUMS"
HASH=$(curl -sf "$URL" | grep "linux-x86_64/en-US/thunderbird-${VERSION}.tar.xz" | awk '{print $1}')
[ -z "$HASH" ] && exit 1
echo "sha512:${HASH}"
