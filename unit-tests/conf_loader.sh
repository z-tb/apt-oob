#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# Valid conf
create_test_conf "mypkg"
load_conf "${OOB_CONF}/mypkg"
assert_ok $? "load valid conf"
assert_eq "mypkg" "$NAME" "NAME loaded"
assert_eq "none" "$CHECKSUM" "CHECKSUM defaults to none"

# Missing required fields
cat > "${OOB_CONF}/badpkg" <<'EOF'
NAME="badpkg"
EOF
load_conf "${OOB_CONF}/badpkg" 2>/dev/null
assert_fail $? "missing fields should fail"

# Omitted CHECKSUM warns (captured via _reset_conf setting it empty)
cat > "${OOB_CONF}/warnpkg" <<EOF
NAME="warnpkg"
DOWNLOAD="https://example.com/file.tar.gz"
VERSION_CHECK="warnpkg-check.sh"
INSTALL_DIR="${OOB_LIVE}/warnpkg"
SYMLINKS="warnpkg:warnpkg/bin/warnpkg"
SYMLINK_DIR="${TEST_TMPDIR}/bin"
EOF
mkdir -p "${TEST_TMPDIR}/bin"
load_conf "${OOB_CONF}/warnpkg" 2>/dev/null
assert_ok $? "omitted CHECKSUM should still load"
assert_eq "none" "$CHECKSUM" "omitted CHECKSUM becomes none"

# Reset between packages
create_test_conf "pkg1"
load_conf "${OOB_CONF}/pkg1"
create_test_conf "pkg2"
load_conf "${OOB_CONF}/pkg2"
assert_eq "pkg2" "$NAME" "conf reset between loads"

teardown
report "conf_loader"
