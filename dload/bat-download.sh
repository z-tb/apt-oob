#!/bin/bash
VERSION="$1"
[ -z "$VERSION" ] && exit 1
echo "https://github.com/sharkdp/bat/releases/download/v${VERSION}/bat-v${VERSION}-x86_64-unknown-linux-gnu.tar.gz"
