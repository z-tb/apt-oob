# apt-oob

**apt-oob** is a lightweight out-of-band software manager for Debian-based systems. It manages software that has no apt repository — packages distributed as tarballs with a download URL — handling version checking, verification, installation, and symlinking.

apt-oob integrates with the standard apt upgrade process and runs automatically when `apt upgrade` or `apt-get upgrade` is invoked.

---

## CLI Usage

```
oob upgrade            # Check and upgrade all configured packages
oob upgrade <name>     # Check and upgrade a single package by NAME
oob list               # List all configured packages and their installed versions
oob status <name>      # Show detailed state for a single package
```

---

## Upgrade Behavior

`oob upgrade` iterates over all conf.d entries in lexical order. For each package:

1. The version check script runs to determine the latest available version.
2. If the installed version (from state/) already matches, a message is logged and the package is skipped.
3. Otherwise the download, verification, extraction, and symlink steps proceed.

Per-package failures (download errors, checksum mismatches, version check failures) are logged and the failing package is skipped, but processing continues for remaining packages. This ensures every configured package gets a chance to update. Because partial failures are handled internally, `oob` exits `0` unless a genuine fatal error occurs — this avoids false post-invoke failures reported by apt.

---

## APT Integration

apt-oob registers itself as an apt post-invoke hook by dropping a configuration file into `/etc/apt/apt.conf.d/`:

```
# /etc/apt/apt.conf.d/99apt-oob
DPkg::Post-Invoke {"if [ -x /usr/local/apt-oob/bin/oob ]; then /usr/local/apt-oob/bin/oob upgrade; fi";};
```

`DPkg::Post-Invoke` runs after dpkg has completed all of its own operations, so apt-oob runs in the same terminal session after apt finishes. The user sees apt-oob output as a natural continuation of the upgrade process. If `oob upgrade` exits non-zero, apt may report a post-invoke failure even though the apt upgrade itself succeeded — `oob` should therefore be careful to only exit non-zero on genuine errors.

---

## Directory Structure

```
/usr/local/apt-oob/
├── bin/
│   └── oob                  # Main executable
├── conf.d/                  # Package configuration files (sourced in lexical order)
│   ├── 10-golang
│   └── 20-minecraft
├── checkver/                # Version check scripts (print latest version string to stdout)
│   ├── golang-check.sh
│   └── minecraft-check.sh
├── dload/                   # Download URL resolution scripts (receive version as $1, print URL to stdout)
│   ├── golang-download.sh
│   └── minecraft-download.sh
├── checksum/                # Checksum scripts (print algo:hash to stdout)
│   ├── golang-checksum.sh
│   └── firefox-verify.sh
├── checksig/                # Signature verification scripts (verify detached GPG signatures)
│   └── golang-sigcheck.sh
├── keys/                    # ASCII-armored GPG public keys (.asc files) used by checksig scripts
│   └── golang-signing.asc
├── live/                    # Extracted package installations
│   └── golang/
│       └── go/              # Extracted as-is from tarball, no renaming
└── state/                   # Installed package state (one file per package)
    └── golang
```

**Logging** is written to `/var/log/apt-oob.log`.

---

## conf.d File Format

Configuration files are plain shell-sourceable key=value files. They are loaded in lexical order — numeric prefixes (`10-`, `20-`) control precedence. Each file configures one package.

### Template Variables

The following variables are available for use in `DOWNLOAD` when it contains an `https://` URL. They are substituted by `oob` at runtime using the version string returned by `VERSION_CHECK`.

| Variable | Description |
|---|---|
| `{VERSION}` | Full version string e.g. `1.21.6` |
| `{MAJOR}` | Major component e.g. `1` |
| `{MINOR}` | Minor component e.g. `21` |
| `{REVISION}` | Revision component e.g. `6` |

---

### Reference

```sh
# conf.d/10-golang

# Package name — used for directory naming under live/ and state/
NAME="golang"

# Download source. Either:
#   https:// URL — supports {VERSION} {MAJOR} {MINOR} {REVISION} template variables
#   script name  — resolved under apt-oob/dload/, receives latest version as $1, prints URL to stdout
DOWNLOAD="golang-download.sh"
# or: DOWNLOAD="https://go.dev/dl/go{VERSION}.linux-amd64.tar.gz"

# Checksum method. Either:
#   none         — skip verification entirely for this package
#   script name  — resolved under apt-oob/checksum/, receives version as $1,
#                  must print "algo:hash" to stdout (e.g. sha256:abc123...) and exit 0
CHECKSUM="golang-verify.sh"
# or: CHECKSUM="none"

# Signature verification script under apt-oob/checksig/
# Receives version as $1 and path to downloaded archive as $2
# Responsible for fetching the detached signature and verifying against a key in apt-oob/keys/
# Must exit 0 on success, non-zero on failure
# If both CHECKSUM and CHECKSIG are set, both must pass
CHECKSIG="golang-sigcheck.sh"
# or: CHECKSIG="none"

# Version check script under apt-oob/checkver/
# Must print the latest available version string to stdout and exit 0 on success
VERSION_CHECK="golang-check.sh"

# Base directory to extract the package archive into
# The tarball is extracted as-is — no renaming or stripping of top-level directories
# Actual install path is recorded in state after extraction
# OOB_LIVE is a built-in variable set to /usr/local/apt-oob/live
INSTALL_DIR="${OOB_LIVE}/${NAME}"

# Space-separated list of symlinks to create
# Format: "linkname:path_relative_to_INSTALL_DIR"
# Path must include the top-level directory the tarball extracts to
SYMLINKS="go:go/bin/go gofmt:go/bin/gofmt"

# Directory in which symlinks are created
SYMLINK_DIR="/usr/local/bin"
```

---

## State Files

Each installed package has a corresponding state file under `state/`. These are written atomically on install and updated on upgrade. The state directory acts as the installed package index — `ls state/` lists all managed packages.

```sh
# state/golang
INSTALLED_VERSION="1.21.6"
INSTALL_DATE="2026-03-22T10:23:00Z"
INSTALL_PATH="/usr/local/apt-oob/live/golang/go"
SYMLINKS="go:/usr/local/bin/go gofmt:/usr/local/bin/gofmt"
```

Note: In conf.d, `SYMLINKS` paths are relative to `INSTALL_DIR` (e.g. `go:go/bin/go`). In state files, `SYMLINKS` records the resolved absolute paths (e.g. `go:/usr/local/bin/go`).

---

## checkver/ Scripts

Scripts placed under `checkver/` are responsible for discovering the latest available version of a package. They must:

- Print a single version string to stdout (e.g. `1.22.0`)
- Exit `0` on success
- Exit non-zero if the version cannot be determined

---

## dload/ Scripts

Scripts placed under `dload/` are responsible for resolving the download URL for a given version. They must:

- Accept the version string as `$1`
- Print a single `https://` URL to stdout
- Exit `0` on success
- Exit non-zero on failure

---

## checksum/ Scripts

Scripts placed under `checksum/` are responsible for producing the expected checksum for a given version. They must:

- Accept the version string as `$1`
- Print a single `algo:hash` string to stdout (e.g. `sha256:abc123...` or `sha512:def456...`)
- Supported algorithms: `sha256`, `sha512`
- Exit `0` on success
- Exit non-zero if the checksum cannot be determined

`oob` computes the matching hash of the downloaded archive and compares it against the script output.

---

## checksig/ Scripts

Scripts placed under `checksig/` are responsible for verifying the GPG signature of a downloaded archive. They must:

- Accept the version string as `$1` and the path to the downloaded archive as `$2`
- Fetch the detached signature for the given version
- Import the appropriate key from `apt-oob/keys/` into a temporary isolated keyring (the system keyring is never touched)
- Verify the signature against the archive
- Exit `0` on verification success
- Exit non-zero on failure

If both `CHECKSUM` and `CHECKSIG` are configured for a package, both must pass for the upgrade to proceed.

---

## keys/

ASCII-armored GPG public key files (`.asc`) used by `checksig/` scripts. Each script is responsible for importing the appropriate key into a temporary keyring at verify time. The system GPG keyring is never read from or written to.