#!/bin/bash
# Run all unit tests
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_PASS=0
TOTAL_FAIL=0

echo "=== apt-oob unit tests ==="
echo ""

for test_file in "$SCRIPT_DIR"/*.sh; do
    [[ "$(basename "$test_file")" == "helpers.sh" ]] && continue
    [[ "$(basename "$test_file")" == "run.sh" ]] && continue
    bash "$test_file"
    rc=$?
    if [[ $rc -ne 0 ]]; then
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
    else
        TOTAL_PASS=$((TOTAL_PASS + 1))
    fi
done

echo ""
echo "=== Summary: ${TOTAL_PASS} suites passed, ${TOTAL_FAIL} suites failed ==="
exit $TOTAL_FAIL
