#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# Setup installed package
create_test_conf "rmpkg"
mkdir -p "${OOB_LIVE}/rmpkg/rmpkg/bin"
echo "bin" > "${OOB_LIVE}/rmpkg/rmpkg/bin/rmpkg"
mkdir -p "${TEST_TMPDIR}/bin"
ln -sf "${OOB_LIVE}/rmpkg/rmpkg/bin/rmpkg" "${TEST_TMPDIR}/bin/rmpkg"
write_state "rmpkg" "1.0.0" "${OOB_LIVE}/rmpkg" "rmpkg:${TEST_TMPDIR}/bin/rmpkg"

# dry-run
TARGET_NAME="rmpkg"
FLAG_DRYRUN=1
output=$(cmd_remove 2>&1)
assert_ok $? "dry-run succeeds"
assert_file_exists "${OOB_STATE}/rmpkg" "state still exists after dry-run"
assert_dir_exists "${OOB_LIVE}/rmpkg" "live still exists after dry-run"
FLAG_DRYRUN=0

# force remove (skip prompt)
FLAG_FORCE=1
cmd_remove
assert_ok $? "force remove succeeds"
assert_file_not_exists "${OOB_STATE}/rmpkg" "state removed"
assert_file_not_exists "${TEST_TMPDIR}/bin/rmpkg" "symlink removed"
assert_file_exists "${OOB_CONF}/rmpkg.disabled" "config disabled after remove"
assert_file_not_exists "${OOB_CONF}/rmpkg" "enabled config removed after remove"

# remove non-existent
TARGET_NAME="nonexistent"
cmd_remove 2>/dev/null
assert_fail $? "remove nonexistent fails"

teardown
report "remove"
