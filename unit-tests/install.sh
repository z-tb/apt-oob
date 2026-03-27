#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# Create a package with a local tar.gz to avoid network
mkdir -p "${TEST_TMPDIR}/src/testpkg/bin"
echo "binary" > "${TEST_TMPDIR}/src/testpkg/bin/testpkg"
tar czf "${TEST_TMPDIR}/testpkg-1.0.0.tar.gz" -C "${TEST_TMPDIR}/src" testpkg

# Create a dload script that returns local file URL
cat > "${OOB_DLOAD}/testpkg-download.sh" <<EOF
#!/bin/bash
echo "file://${TEST_TMPDIR}/testpkg-1.0.0.tar.gz"
EOF
chmod +x "${OOB_DLOAD}/testpkg-download.sh"

# Conf using dload script
cat > "${OOB_CONF}/10-testpkg" <<EOF
NAME="testpkg"
DOWNLOAD="testpkg-download.sh"
CHECKSUM="none"
VERSION_CHECK="testpkg-check.sh"
INSTALL_DIR="${OOB_LIVE}/testpkg"
SYMLINKS="testpkg:testpkg/bin/testpkg"
SYMLINK_DIR="${TEST_TMPDIR}/bin"
EOF
mkdir -p "${TEST_TMPDIR}/bin"
create_test_checkver "testpkg" "1.0.0"

# dry-run
FLAG_DRYRUN=1
TARGET_NAME="testpkg"
FLAG_QUIET=0
output=$(cmd_install 2>&1)
FLAG_QUIET=1
assert_ok $? "dry-run succeeds"
assert_contains "$output" "would install" "dry-run output"
assert_file_not_exists "${OOB_STATE}/testpkg" "no state after dry-run"
FLAG_DRYRUN=0

# Actual install — need curl to support file:// so use cp workaround
# Override resolve_download_url to just copy the file
# Actually, curl supports file:// so this should work
TARGET_NAME="testpkg"
cmd_install 2>&1
assert_ok $? "install succeeds"
assert_file_exists "${OOB_STATE}/testpkg" "state file created"
assert_link "${TEST_TMPDIR}/bin/testpkg" "symlink created"

# Skip if already current
FLAG_QUIET=0
output=$(cmd_install 2>&1)
FLAG_QUIET=1
assert_contains "$output" "already at version" "skip current version"

# Force reinstall
FLAG_FORCE=1
cmd_install 2>&1
assert_ok $? "force reinstall succeeds"
FLAG_FORCE=0

teardown
report "install"
