#!/bin/bash
VERSION="$1"
[ -z "$VERSION" ] && exit 1
HASH=$(curl -sf 'https://go.dev/dl/?mode=json' | python3 -c "
import json,sys
data=json.load(sys.stdin)
for r in data:
    if r['version'] == 'go${VERSION}':
        for f in r['files']:
            if f['os']=='linux' and f['arch']=='amd64' and f['kind']=='archive':
                print(f['sha256'])
                break
        break
")
[ -z "$HASH" ] && exit 1
echo "sha256:${HASH}"
