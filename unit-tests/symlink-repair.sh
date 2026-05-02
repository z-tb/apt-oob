#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# Setup: create a package with a versioned symlink path (like nextcloud-talk)
mkdir -p "${OOB_LIVE}/mypkg/app-v1.0.0/bin"
echo "binary" > "${OOB_LIVE}/mypkg/app-v1.0.0/bin/myapp"
chmod +x "${OOB_LIVE}/mypkg/app-v1.0.0/bin/myapp"

SYMLINK_DIR="${TEST_TMPDIR}/bin"
mkdir -p "$SYMLINK_DIR"

# Conf.d with relative path including version template
cat > "${OOB_CONF}/10-mypkg" <<EOF
NAME="mypkg"
DOWNLOAD="https://example.com/%VERSION%.tar.gz"
CHECKSUM="none"
VERSION_CHECK="mypkg-check.sh"
INSTALL_DIR="${OOB_LIVE}/mypkg"
SYMLINKS="myapp:app-v%VERSION%/bin/myapp"
SYMLINK_DIR="${SYMLINK_DIR}"
EOF

create_test_checkver "mypkg" "1.0.0"

# Create initial symlink and state (simulating a successful install)
ln -sf "${OOB_LIVE}/mypkg/app-v1.0.0/bin/myapp" "${SYMLINK_DIR}/myapp"
write_state "mypkg" "1.0.0" "${OOB_LIVE}/mypkg" "myapp:${SYMLINK_DIR}/myapp"

# Verify initial state is good
assert_link "${SYMLINK_DIR}/myapp" "initial symlink exists"
check_symlinks "mypkg" "myapp:${SYMLINK_DIR}/myapp" 0
assert_ok $? "initial symlinks OK"

# Break the symlink by removing the target
rm -rf "${OOB_LIVE}/mypkg/app-v1.0.0/bin/myapp"

# Check detects broken symlink (report only)
check_symlinks "mypkg" "myapp:${SYMLINK_DIR}/myapp" 0 2>/dev/null
assert_fail $? "detects broken symlink"

# Restore the target
echo "binary" > "${OOB_LIVE}/mypkg/app-v1.0.0/bin/myapp"
chmod +x "${OOB_LIVE}/mypkg/app-v1.0.0/bin/myapp"

# Delete the symlink entirely (simulating missing symlink)
rm -f "${SYMLINK_DIR}/myapp"

# Fix=1 should recreate from conf.d using relative path + version
NAME="mypkg"
check_symlinks "mypkg" "myapp:${SYMLINK_DIR}/myapp" 1 2>/dev/null
assert_link "${SYMLINK_DIR}/myapp" "symlink recreated"

# Verify the recreated symlink points to the correct target (relative path expanded)
target=$(readlink "${SYMLINK_DIR}/myapp")
assert_contains "$target" "app-v1.0.0/bin/myapp" "recreated symlink uses conf.d relative path with version"

# Verify it's not broken
assert_file_exists "${SYMLINK_DIR}/myapp" "recreated symlink target exists"

teardown
report "symlink-repair"
