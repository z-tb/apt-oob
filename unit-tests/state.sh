#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# Write and read state
write_state "testpkg" "1.0.0" "/tmp/test/live/testpkg" "testpkg:/tmp/bin/testpkg"
assert_file_exists "${OOB_STATE}/testpkg" "state file created"

read_state "testpkg"
assert_ok $? "read_state succeeds"
assert_eq "1.0.0" "$INSTALLED_VERSION" "version read back"
assert_contains "$INSTALL_PATH" "testpkg" "install path read back"

# Atomic write — temp file should not linger
local_count=$(ls "${OOB_STATE}"/.testpkg.* 2>/dev/null | wc -l)
assert_eq "0" "$local_count" "no temp files left"

# Missing state
read_state "nonexistent"
assert_fail $? "missing state returns non-zero"

teardown
report "state"
