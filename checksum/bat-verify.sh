#!/bin/bash
VERSION="$1"
[ -z "$VERSION" ] && exit 1
ASSET="bat-v${VERSION}-x86_64-unknown-linux-gnu.tar.gz"
HASH=$(curl -sf "https://api.github.com/repos/sharkdp/bat/releases/tags/v${VERSION}" \
  | python3 -c "
import json,sys
data=json.load(sys.stdin)
for a in data['assets']:
    if a['name'] == '${ASSET}':
        print(a.get('digest','').replace('sha256:',''))
        break
")
[ -z "$HASH" ] && exit 1
echo "sha256:${HASH}"
