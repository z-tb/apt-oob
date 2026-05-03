#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# Create a test package
create_test_conf "mypkg"

# Verify it starts enabled
assert_file_exists "${OOB_CONF}/mypkg" "conf exists before disable"

# Disable it
TARGET_NAME="mypkg"
cmd_disable 2>&1
assert_ok $? "disable succeeds"
assert_file_exists "${OOB_CONF}/mypkg.disabled" "disabled file exists"
assert_file_not_exists "${OOB_CONF}/mypkg" "enabled file removed"

# Disable again should be a no-op
cmd_disable 2>&1
assert_ok $? "disable already-disabled succeeds"

# Enable it
cmd_enable 2>&1
assert_ok $? "enable succeeds"
assert_file_exists "${OOB_CONF}/mypkg" "enabled file restored"
assert_file_not_exists "${OOB_CONF}/mypkg.disabled" "disabled file removed"

# Enable again should be a no-op
cmd_enable 2>&1
assert_ok $? "enable already-enabled succeeds"

# Disable/enable with unknown package should fail
TARGET_NAME="nonexistent"
cmd_disable 2>&1
assert_fail $? "disable unknown package fails"
cmd_enable 2>&1
assert_fail $? "enable unknown package fails"

teardown
report "enable-disable"
