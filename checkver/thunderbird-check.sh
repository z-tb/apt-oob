#!/bin/bash
curl -sf 'https://product-details.mozilla.org/1.0/thunderbird_versions.json' \
  | grep -oP '"LATEST_THUNDERBIRD_VERSION"\s*:\s*"\K[^"]+'
