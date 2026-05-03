#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# Create two packages: one active, one disabled
create_test_conf "active"
create_test_conf "skipped"
mv "${OOB_CONF}/skipped" "${OOB_CONF}/skipped.disabled"

# cmd_list should only show the active package
FLAG_QUIET=0
output=$(cmd_list 2>&1)
FLAG_QUIET=1
assert_contains "$output" "active" "active package listed"
# Verify disabled package appears as disabled
if echo "$output" | grep -q "skipped.*disabled"; then
    TEST_PASS=$((TEST_PASS + 1))
else
    TEST_FAIL=$((TEST_FAIL + 1))
    echo "  FAIL: disabled package should appear as disabled in list"
fi

# find_conf_by_name should not find the disabled package
find_conf_by_name "skipped" >/dev/null 2>&1
assert_fail $? "find_conf_by_name ignores .disabled"

# find_conf_by_name should still find the active package
find_conf_by_name "active" >/dev/null 2>&1
assert_ok $? "find_conf_by_name finds active conf"

# cmd_update should skip disabled package
create_test_checkver "active" "1.0.0"
FLAG_QUIET=0
output=$(cmd_update 2>&1)
FLAG_QUIET=1
assert_contains "$output" "active" "update shows active package"
if echo "$output" | grep -q "skipped"; then
    TEST_FAIL=$((TEST_FAIL + 1))
    echo "  FAIL: update should skip disabled package"
else
    TEST_PASS=$((TEST_PASS + 1))
fi

teardown
report "disabled"
