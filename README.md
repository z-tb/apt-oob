# apt-oob

**apt-oob** is a lightweight out-of-band software manager for Debian-based systems. It manages software that has no apt repository — packages distributed as tarballs with a download URL — handling version checking, verification, installation, and symlinking.

apt-oob integrates with the standard apt upgrade process and runs automatically when `apt upgrade` or `apt-get upgrade` is invoked.

---

## CLI Usage

```
oob install [name]     # Install/update all configured packages, or a single package by NAME
oob check [name]       # Check available versions without installing (all or single package)
oob remove <name>      # Remove installed files from live/, symlinks, and state for a package
oob list               # List all configured packages and their installed versions
oob status <name>      # Show detailed state for a single package
oob init               # Install the apt post-invoke hook for automatic oob runs
oob deinit             # Remove the apt post-invoke hook
```

### Flags

| Flag | Description |
|---|---|
| `-f`, `--force` | `install`: re-download and reinstall regardless of version. `remove`: skip y/n confirmation prompt. |
| `-n`, `--dry-run` | Show what would happen without making changes. |
| `-v`, `--verbose` | Increase terminal output detail. |
| `-q`, `--quiet` | Suppress terminal output; log to file only. |

---

## Install Behavior

`oob install` iterates over all conf.d entries in lexical order. For each package:

1. The version check script runs to determine the latest available version.
2. If the installed version (from state/) already matches, a message is logged and the package is skipped. With `--force`, this check is skipped and the package is reinstalled.
3. The archive is downloaded to a temporary directory (created via `mktemp -d`).
4. If `CHECKSUM` is set to a script name, the checksum script runs and `oob` verifies the download. If `CHECKSUM` is omitted (not set at all), a warning is logged about unclear intent but processing continues as if `"none"`. If explicitly set to `"none"`, no warning.
5. If `CHECKSIG` is set to a script name, the signature verification script runs. Same omission/warning behavior as `CHECKSUM`.
6. The existing `INSTALL_DIR` for the package is removed, the archive is extracted, symlinks are created, and the state file is written.
7. The temporary directory is cleaned up on both success and failure.

Per-package failures (download errors, checksum mismatches, version check failures) are logged and the failing package is skipped, but processing continues for remaining packages. This ensures every configured package gets a chance to update. Because partial failures are handled internally, `oob` exits `0` unless a genuine fatal error occurs — this avoids false post-invoke failures reported by apt.

`--dry-run` shows what would happen without downloading, extracting, or modifying any files.

### Check

`oob check` runs version checks only without downloading or installing. Output per package:

```
golang: installed=1.21.6 available=1.22.0
firefox: installed=148.0.2 available=148.0.2 (up to date)
```

### Remove

`oob remove <name>` removes the package's installed files from `live/`, any symlinks created via the config, and the state file. Always prompts y/n before proceeding unless `--force` is specified. `--dry-run` shows what would be removed without acting.

### List

`oob list` shows all configured packages (from conf.d) and their installed versions. Packages with a conf.d entry but no state file are shown as `configured, not installed`.

### Status

`oob status <name>` shows the state file contents for a package and runs the version check script to report whether an update is available.

### Init / Deinit

`oob init` writes the apt post-invoke hook file. If the hook file already exists, it warns and prompts to overwrite. `oob deinit` removes the hook file.

---

## Output Functions

Terminal output uses ANSI color codes via the following functions:

| Function | Color | Purpose |
|---|---|---|
| `info()` | Cyan | Normal informational messages |
| `warn()` | Yellow | Warning messages |
| `error()` | Red | Error messages |
| `success()` | Green | Success messages |
| `highlight()` | Magenta | Highlighted text |
| `bold()` | White | Bold/emphasized text |

When `-q` is specified, all output is written to the log file only. Otherwise output goes to both terminal and log.

Logging uses syslog-style formatting:

```
Mar 22 10:23:00 oob[12345]: [INFO] golang: installed 1.22.0
Mar 22 10:23:01 oob[12345]: [WARN] firefox: CHECKSUM not set, skipping verification
Mar 22 10:23:02 oob[12345]: [ERROR] minecraft: download failed
```

---

## APT Integration

apt-oob registers itself as an apt post-invoke hook by dropping a configuration file into `/etc/apt/apt.conf.d/`:

```
# /etc/apt/apt.conf.d/99-apt-oob
DPkg::Post-Invoke {"if [ -x /usr/local/apt-oob/bin/oob ]; then /usr/local/apt-oob/bin/oob install -q; fi";};
```

`DPkg::Post-Invoke` runs after dpkg has completed all of its own operations, so apt-oob runs in the same terminal session after apt finishes. The user sees apt-oob output as a natural continuation of the upgrade process. If `oob install` exits non-zero, apt may report a post-invoke failure even though the apt upgrade itself succeeded — `oob` should therefore be careful to only exit non-zero on genuine errors.

`oob init` writes this hook file. If the file already exists, `oob init` warns and prompts to overwrite. `oob deinit` removes it.

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
├── dload/                   # URL resolvers (receive version as $1, print URL to stdout)
│   ├── golang-download.sh
│   └── minecraft-download.sh
├── checksum/                # Checksum scripts (print algo:hash to stdout)
│   ├── golang-checksum.sh
│   └── firefox-verify.sh
├── checksig/                # Signature verification scripts (verify GPG signatures)
│   └── golang-sigcheck.sh
├── keys/                    # GPG public keys (.asc files) used by checksig scripts
│   └── golang-signing.asc
├── live/                    # Extracted package installations
│   └── golang/
│       └── go/              # Extracted as-is from tarball, no renaming
└── state/                   # Installed package state (one file per package)
    └── golang
```

**Logging** is written to `/var/log/apt-oob.log`.

---

## Global Configuration

`/etc/apt-oob.conf` is an optional shell-sourceable configuration file for overriding oob defaults. It is sourced at startup before paths are derived. If the file does not exist, built-in defaults are used.

```sh
# /etc/apt-oob.conf
OOB_BASE="/usr/local/apt-oob"
LOG_FILE="/var/log/apt-oob.log"
```

| Variable | Default | Description |
|---|---|---|
| `OOB_BASE` | `/usr/local/apt-oob` | Root directory for all apt-oob files |
| `LOG_FILE` | `/var/log/apt-oob.log` | Log file path |

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

Each installed package has a corresponding state file under `state/`. These are written atomically (write to temp file, then `mv`) on install and updated on subsequent installs. The state directory acts as the installed package index — `ls state/` lists all managed packages. `oob remove` deletes the state file along with installed files and symlinks.

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

If both `CHECKSUM` and `CHECKSIG` are configured for a package, both must pass for the install to proceed.

---

## keys/

ASCII-armored GPG public key files (`.asc`) used by `checksig/` scripts. Each script is responsible for importing the appropriate key into a temporary keyring at verify time. The system GPG keyring is never read from or written to.