#!/bin/bash
source "$(dirname "$0")/helpers.sh"
setup

# --- Setup: create bat package config with local tarball ---

# Create a fake bat binary inside a versioned directory (mimics real tarball structure)
FAKE_VERSION="0.99.0"
mkdir -p "${TEST_TMPDIR}/src/bat-v${FAKE_VERSION}-x86_64-unknown-linux-gnu"
echo '#!/bin/bash' > "${TEST_TMPDIR}/src/bat-v${FAKE_VERSION}-x86_64-unknown-linux-gnu/bat"
echo "echo bat ${FAKE_VERSION}" >> "${TEST_TMPDIR}/src/bat-v${FAKE_VERSION}-x86_64-unknown-linux-gnu/bat"
chmod +x "${TEST_TMPDIR}/src/bat-v${FAKE_VERSION}-x86_64-unknown-linux-gnu/bat"

# Create tarball
tar czf "${TEST_TMPDIR}/bat-v${FAKE_VERSION}.tar.gz" -C "${TEST_TMPDIR}/src" "bat-v${FAKE_VERSION}-x86_64-unknown-linux-gnu"

# Create dload script returning local file URL
cat > "${OOB_DLOAD}/bat-download.sh" <<EOF
#!/bin/bash
echo "file://${TEST_TMPDIR}/bat-v${FAKE_VERSION}.tar.gz"
EOF
chmod +x "${OOB_DLOAD}/bat-download.sh"

# Create checkver script
cat > "${OOB_CHECKVER}/bat-check.sh" <<EOF
#!/bin/bash
echo "${FAKE_VERSION}"
EOF
chmod +x "${OOB_CHECKVER}/bat-check.sh"

# Create checksum script
EXPECTED_SHA256=$(sha256sum "${TEST_TMPDIR}/bat-v${FAKE_VERSION}.tar.gz" | awk '{print $1}')
cat > "${OOB_CHECKSUM}/bat-verify.sh" <<EOF
#!/bin/bash
echo "sha256:${EXPECTED_SHA256}"
EOF
chmod +x "${OOB_CHECKSUM}/bat-verify.sh"

# Create conf.d entry with versioned symlink path
mkdir -p "${TEST_TMPDIR}/bin"
cat > "${OOB_CONF}/40-bat" <<EOF
NAME="bat"
DOWNLOAD="bat-download.sh"
CHECKSUM="bat-verify.sh"
VERSION_CHECK="bat-check.sh"
INSTALL_DIR="${OOB_LIVE}/bat"
SYMLINKS="bat:bat-v%VERSION%-x86_64-unknown-linux-gnu/bat"
SYMLINK_DIR="${TEST_TMPDIR}/bin"
EOF

# --- Test: install ---
TARGET_NAME="bat"
cmd_install 2>/dev/null
assert_ok $? "install bat succeeds"
assert_file_exists "${OOB_STATE}/bat" "state file created"
assert_dir_exists "${OOB_LIVE}/bat" "install dir created"
assert_link "${TEST_TMPDIR}/bin/bat" "symlink created"

# Verify symlink target resolves through versioned directory
target=$(readlink "${TEST_TMPDIR}/bin/bat")
assert_contains "$target" "bat-v${FAKE_VERSION}" "symlink contains version in path"

# Verify binary works
output=$("${TEST_TMPDIR}/bin/bat" 2>&1)
assert_eq "bat ${FAKE_VERSION}" "$output" "binary runs correctly"

# --- Test: update (up to date) ---
FLAG_QUIET=0
output=$(cmd_update 2>&1)
FLAG_QUIET=1
assert_contains "$output" "up to date" "update shows up to date"

# --- Test: install skip (already current) ---
FLAG_QUIET=0
output=$(cmd_install 2>&1)
FLAG_QUIET=1
assert_contains "$output" "up to date" "install skips current version"

# --- Test: install --force ---
FLAG_FORCE=1
cmd_install 2>/dev/null
assert_ok $? "force reinstall succeeds"
assert_link "${TEST_TMPDIR}/bin/bat" "symlink still exists after force"
FLAG_FORCE=0

# --- Test: status ---
FLAG_QUIET=0
output=$(cmd_status 2>&1)
FLAG_QUIET=1
assert_contains "$output" "${FAKE_VERSION}" "status shows version"
assert_contains "$output" "up to date" "status shows up to date"

# --- Test: list ---
FLAG_QUIET=0
output=$(cmd_list 2>&1)
FLAG_QUIET=1
assert_contains "$output" "bat" "list includes bat"
assert_contains "$output" "${FAKE_VERSION}" "list shows version"

# --- Test: integrity check (stale state) ---
rm -rf "${OOB_LIVE}/bat"
check_integrity "bat" "${OOB_LIVE}/bat"
assert_eq "stale_state" "$INTEGRITY" "detects stale state"

# --- Test: install recovers from stale state ---
cmd_install 2>/dev/null
assert_ok $? "install recovers from stale state"
assert_dir_exists "${OOB_LIVE}/bat" "install dir recreated"

# --- Test: remove implies disable ---
FLAG_FORCE=1
cmd_remove 2>/dev/null
assert_ok $? "remove succeeds"
assert_file_not_exists "${OOB_STATE}/bat" "state removed"
assert_file_not_exists "${TEST_TMPDIR}/bin/bat" "symlink removed"
assert_file_exists "${OOB_CONF}/40-bat.disabled" "config disabled after remove"
FLAG_FORCE=0

# --- Test: list shows disabled ---
FLAG_QUIET=0
output=$(cmd_list 2>&1)
FLAG_QUIET=1
assert_contains "$output" "bat" "list includes disabled bat"
assert_contains "$output" "disabled" "list shows disabled status"

# --- Test: enable after remove ---
cmd_enable 2>/dev/null
assert_ok $? "enable after remove succeeds"
assert_file_exists "${OOB_CONF}/40-bat" "config re-enabled"
assert_file_not_exists "${OOB_CONF}/40-bat.disabled" "disabled file gone"

# --- Test: disable ---
cmd_disable 2>/dev/null
assert_ok $? "disable succeeds"
assert_file_exists "${OOB_CONF}/40-bat.disabled" "config disabled"

# --- Test: upgrade skips disabled ---
cmd_upgrade 2>/dev/null
assert_file_not_exists "${OOB_STATE}/bat" "upgrade skips disabled package"

# --- Test: integrity check (orphaned) ---
# Re-enable, reinstall, then delete state
cmd_enable 2>/dev/null
cmd_install 2>/dev/null
rm -f "${OOB_STATE}/bat"
check_integrity "bat" "${OOB_LIVE}/bat"
assert_eq "orphaned" "$INTEGRITY" "detects orphaned install"

teardown
report "integration-bat"
