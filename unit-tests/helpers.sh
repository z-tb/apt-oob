#!/bin/bash
# Shared test helpers — source this at the top of each test file

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

TEST_PASS=0
TEST_FAIL=0
TEST_NAME=""

# Setup temp OOB_BASE so tests never touch real system
setup() {
    export TEST_TMPDIR
    TEST_TMPDIR=$(mktemp -d "/tmp/oob-test.XXXXXX")
    export OOB_BASE="$TEST_TMPDIR/apt-oob"
    export LOG_FILE="$TEST_TMPDIR/oob.log"
    export OOB_SOURCED=1

    mkdir -p "$OOB_BASE"/{conf.d,checkver,dload,checksum,keys,live,state,bin}

    # Source oob functions (OOB_BASE/LOG_FILE already exported, so defaults won't override)
    source "$REPO_DIR/bin/oob"

    # Disable strict error mode for tests (we test expected failures)
    set +e
    set +u

    # Override APT_HOOK to test path
    APT_HOOK="$TEST_TMPDIR/99-apt-oob"
    export OOB_CONF_FILE="$TEST_TMPDIR/apt-oob.conf"

    # Reset flags
    FLAG_FORCE=0; FLAG_DRYRUN=0; FLAG_VERBOSE=0; FLAG_QUIET=1
    COMMAND=""; TARGET_NAME=""
}

teardown() {
    [[ -d "${TEST_TMPDIR:-}" ]] && rm -rf "$TEST_TMPDIR"
}

assert_eq() {
    local expected="$1" actual="$2" msg="${3:-}"
    if [[ "$expected" == "$actual" ]]; then
        TEST_PASS=$((TEST_PASS + 1))
    else
        TEST_FAIL=$((TEST_FAIL + 1))
        echo "  FAIL: ${msg:-assertion}"
        echo "    expected: $expected"
        echo "    actual:   $actual"
    fi
}

assert_ok() {
    local exit_code="$1" msg="${2:-}"
    if [[ "$exit_code" -eq 0 ]]; then
        TEST_PASS=$((TEST_PASS + 1))
    else
        TEST_FAIL=$((TEST_FAIL + 1))
        echo "  FAIL: ${msg:-expected exit 0, got $exit_code}"
    fi
}

assert_fail() {
    local exit_code="$1" msg="${2:-}"
    if [[ "$exit_code" -ne 0 ]]; then
        TEST_PASS=$((TEST_PASS + 1))
    else
        TEST_FAIL=$((TEST_FAIL + 1))
        echo "  FAIL: ${msg:-expected non-zero exit}"
    fi
}

assert_file_exists() {
    local path="$1" msg="${2:-file should exist: $path}"
    if [[ -f "$path" ]]; then
        TEST_PASS=$((TEST_PASS + 1))
    else
        TEST_FAIL=$((TEST_FAIL + 1))
        echo "  FAIL: $msg"
    fi
}

assert_file_not_exists() {
    local path="$1" msg="${2:-file should not exist: $path}"
    if [[ ! -f "$path" ]]; then
        TEST_PASS=$((TEST_PASS + 1))
    else
        TEST_FAIL=$((TEST_FAIL + 1))
        echo "  FAIL: $msg"
    fi
}

assert_dir_exists() {
    local path="$1" msg="${2:-dir should exist: $path}"
    if [[ -d "$path" ]]; then
        TEST_PASS=$((TEST_PASS + 1))
    else
        TEST_FAIL=$((TEST_FAIL + 1))
        echo "  FAIL: $msg"
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" msg="${3:-}"
    if [[ "$haystack" == *"$needle"* ]]; then
        TEST_PASS=$((TEST_PASS + 1))
    else
        TEST_FAIL=$((TEST_FAIL + 1))
        echo "  FAIL: ${msg:-expected to contain '$needle'}"
    fi
}

assert_link() {
    local path="$1" msg="${2:-should be symlink: $path}"
    if [[ -L "$path" ]]; then
        TEST_PASS=$((TEST_PASS + 1))
    else
        TEST_FAIL=$((TEST_FAIL + 1))
        echo "  FAIL: $msg"
    fi
}

report() {
    local name="$1"
    if [[ $TEST_FAIL -eq 0 ]]; then
        printf '\033[0;32m%-30s %d passed\033[0m\n' "$name" "$TEST_PASS"
    else
        printf '\033[0;31m%-30s %d passed, %d failed\033[0m\n' "$name" "$TEST_PASS" "$TEST_FAIL"
    fi
    return $TEST_FAIL
}

# Create a minimal valid conf.d file for testing
create_test_conf() {
    local name="${1:-testpkg}"
    cat > "${OOB_CONF}/${name}" <<EOF
NAME="${name}"
DOWNLOAD="https://example.com/${name}/{VERSION}.tar.gz"
CHECKSUM="none"
VERSION_CHECK="${name}-check.sh"
INSTALL_DIR="${OOB_LIVE}/${name}"
SYMLINKS="${name}:${name}/bin/${name}"
SYMLINK_DIR="${TEST_TMPDIR}/bin"
EOF
    mkdir -p "${TEST_TMPDIR}/bin"
}

# Create a fake version check script
create_test_checkver() {
    local name="${1:-testpkg}" version="${2:-1.0.0}"
    cat > "${OOB_CHECKVER}/${name}-check.sh" <<EOF
#!/bin/bash
echo "$version"
EOF
    chmod +x "${OOB_CHECKVER}/${name}-check.sh"
}
