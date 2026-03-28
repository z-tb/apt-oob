#!/bin/bash
VERSION="$1"
[ -z "$VERSION" ] && exit 1
echo "https://github.com/nextcloud-releases/talk-desktop/releases/download/v${VERSION}/Nextcloud.Talk-linux-x64.zip"
