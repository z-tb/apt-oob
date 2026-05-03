#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# --- Single package status (existing behavior) ---
create_test_conf "mypkg"
create_test_checkver "mypkg" "2.0.0"
mkdir -p "${OOB_LIVE}/mypkg"
write_state "mypkg" "1.0.0" "${OOB_LIVE}/mypkg" "mypkg:${TEST_TMPDIR}/bin/mypkg"

TARGET_NAME="mypkg"
FLAG_QUIET=0
output=$(cmd_status 2>&1)
FLAG_QUIET=1
assert_ok $? "status succeeds"
assert_contains "$output" "1.0.0" "shows installed version"
assert_contains "$output" "2.0.0" "shows available version"

# Not installed
create_test_conf "newpkg"
create_test_checkver "newpkg" "1.0.0"
TARGET_NAME="newpkg"
FLAG_QUIET=0
output=$(cmd_status 2>&1)
FLAG_QUIET=1
assert_ok $? "status for uninstalled"
assert_contains "$output" "not installed" "shows not installed"

# --- System-wide status (no args) ---
# Add a disabled package
create_test_conf "offpkg"
mv "${OOB_CONF}/offpkg" "${OOB_CONF}/offpkg.disabled"

TARGET_NAME=""
FLAG_QUIET=0
output=$(cmd_status 2>&1)
FLAG_QUIET=1
assert_ok $? "system status succeeds"
assert_contains "$output" "apt hook" "shows apt hook status"
assert_contains "$output" "enabled" "shows enabled count"
assert_contains "$output" "disabled" "shows disabled count"
assert_contains "$output" "mypkg" "lists installed package"
assert_contains "$output" "offpkg" "lists disabled package"

teardown
report "status"
