#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# Create a fake installed binary
mkdir -p "${OOB_LIVE}/testpkg/testpkg/bin"
echo "binary" > "${OOB_LIVE}/testpkg/testpkg/bin/testpkg"
SYMLINK_DIR="${TEST_TMPDIR}/bin"
mkdir -p "$SYMLINK_DIR"
NAME="testpkg"

# Create symlinks
resolved=$(create_symlinks "${OOB_LIVE}/testpkg" "$SYMLINK_DIR" "testpkg:testpkg/bin/testpkg")
assert_link "${SYMLINK_DIR}/testpkg" "symlink created"
assert_contains "$resolved" "testpkg:${SYMLINK_DIR}/testpkg" "resolved path"

# Remove symlinks
remove_symlinks "$resolved"
assert_file_not_exists "${SYMLINK_DIR}/testpkg" "symlink removed"

teardown
report "symlinks"
