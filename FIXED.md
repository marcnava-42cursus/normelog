# FIXED.md

This document tracks all errors and issues that have been resolved in the normelog codebase.

---

## Phase 1 (v0.2.0) - Fix Existing Issues

This phase focuses on fixing all critical errors from ERRORS.md and implementing missing core functionality.

---

### ✅ Error #1 - Environment Setup Issue - `set -euo pipefail` in Sourced Library

**Fixed**: 2025-10-24

**File**: `lib/env.sh:3`, `bin/normelog:3`

**Issue**: The `set -euo pipefail` was executed inside `nl_env_init()`, which could cause unexpected exits in interactive shells.

**Solution**: Moved `set -euo pipefail` from `lib/env.sh` to the top of `bin/normelog` (after shebang), making it apply only to the main script and not to sourced libraries.

**Changes**:
- lib/env.sh:3: Removed `set -euo pipefail` from `nl_env_init()`
- bin/normelog:3: Added `set -euo pipefail` at the top of the script

---

### ✅ Error #2 - Missing Output Mode in `-a` Flag Logic

**Fixed**: 2025-10-24

**File**: `lib/format_text.sh:14-20`

**Issue**: The `-a` flag set `NL_SHOW_ALL_DETAILS=1`, but this variable was never checked or used anywhere in the codebase.

**Solution**: Implemented conditional output in `nl_format_text()` to show detailed per-file errors only when `-a` flag is set or when filtering by specific error types.

**Changes**:
- lib/format_text.sh:14-20: Added conditional check to show details only if `NL_SHOW_ALL_DETAILS=1` or if `NL_INCLUDE_TYPES` array is not empty

---

### ✅ Error #3 - AWK Variable References Bug in JSON Formatter

**Fixed**: 2025-10-24

**File**: `lib/format_json.sh:10-12`, `lib/format_json.sh:35-37`

**Issue**: AWK was trying to use shell-style `$3` and `$2` inside a `BEGIN` block where no fields exist yet. Additionally, JSON escaping was applied to the wrong variable.

**Solution**:
1. Used `split()` to extract fields from the array element correctly
2. Fixed JSON escaping to apply only to the message text substring

**Changes**:
- lib/format_json.sh:10-12: Changed to use `split(S[i], a, " ")` and then access `a[3]`, `a[2]`
- lib/format_json.sh:35-37: Extract message text first into `msg_text`, then escape quotes in that variable only

---

### ✅ Error #4 & #5 - Case-Insensitive Substring Matching Not Implemented

**Fixed**: 2025-10-24

**File**: `lib/filter.sh:3-24`

**Issue**:
1. Error type filtering was case-sensitive, but documentation stated it should be case-insensitive
2. Filtering used exact key lookup instead of substring matching

**Solution**: Implemented case-insensitive substring matching using AWK's `toupper()` and `index()` functions.

**Changes**:
- lib/filter.sh:6-7: Convert all patterns to uppercase when building INC and EXC arrays
- lib/filter.sh:10-19: Convert error type to uppercase and use substring matching with `index()` instead of exact key lookup

---

### ✅ Error #6 - Incorrect Color Output Detection

**Fixed**: 2025-10-24

**File**: `lib/log.sh:2-3`

**Issue**: Color was hardcoded to always be enabled (`NL_COLOR=1`), with no detection for whether stdout is a TTY.

**Solution**: Added TTY detection logic that automatically enables color only when stdout is a terminal.

**Changes**:
- lib/log.sh:2-3: Changed from `NL_COLOR=1` to `[[ -t 1 ]] && NL_COLOR=1 || NL_COLOR=0`

---

### ✅ Error #7 - Debug Messages Go to stdout Instead of stderr

**Fixed**: 2025-10-24

**File**: `lib/log.sh:5`

**Issue**: All log functions wrote to stdout, mixing debug output with actual results.

**Solution**: Redirected all log output to stderr using `>&2`.

**Changes**:
- lib/log.sh:5: Added `>&2` to redirect all log messages to stderr

---

### ✅ Error #8 & #9 - Lint Script Has Wrong Paths and shfmt Configuration Mismatch

**Fixed**: 2025-10-24

**File**: `scripts/lint.sh:3-5`

**Issue**:
1. Script referenced `normelog/bin/normelog` with hardcoded paths
2. `shfmt` used `-i 2` (2 spaces) but `.editorconfig` specifies tabs

**Solution**:
1. Changed to relative paths from project root with `cd "$(dirname "$0")/.."`
2. Changed shfmt to use `-i 0` (tabs) to match `.editorconfig`

**Changes**:
- scripts/lint.sh:3: Added `cd "$(dirname "$0")/.."`
- scripts/lint.sh:4: Changed paths to `bin/normelog lib/*.sh scripts/*.sh`
- scripts/lint.sh:5: Changed from `-i 2 -ci normelog` to `-i 0 -s .`

---

### ✅ Error #10 - Missing Error Handling for Empty norminette Output

**Fixed**: 2025-10-24

**File**: `bin/normelog:81-84`

**Issue**: If norminette produced no output, the pipeline would process empty strings, potentially causing issues.

**Solution**: Added validation to check for empty output and exit gracefully with an error message.

**Changes**:
- bin/normelog:81-84: Added check for empty output with appropriate error message

---

### ✅ Configuration File Examples Added

**Fixed**: 2025-10-24

**File**: `share/examples/normelog.conf.example`

**Issue**: README mentioned config files but provided no examples.

**Solution**: Created comprehensive example configuration file with all available `NL_*` variables documented.

**Changes**:
- share/examples/normelog.conf.example: Created new file with documented configuration examples

---

### ✅ Makefile Installation Issues

**Fixed**: 2025-10-24

**File**: `Makefile:5,22-28,47-49`, `bin/normelog:9-19`

**Issue**:
1. Makefile only installed the binary but not the library files
2. Binary used relative paths that broke when installed system-wide
3. Man page had incorrect version (1.0.10) and wrong date (October 2025)

**Solution**:
1. Added `LIBDIR` variable and installation of lib/*.sh files to Makefile
2. Modified bin/normelog to auto-detect if running from installation or source
3. Updated version to 0.2.0 and corrected date to October 2024

**Changes**:
- Makefile:5: Added `LIBDIR ?= $(PREFIX)/lib/normelog`
- Makefile:25-26: Added library installation: `install -d "$(LIBDIR)"` and `install -m 0644 lib/*.sh "$(LIBDIR)/"`
- Makefile:49: Added library cleanup in uninstall: `@rm -rf "$(LIBDIR)"`
- bin/normelog:9-19: Added intelligent library path detection for both installed and development environments
- lib/version.sh:2: Updated version from 0.1.0 to 0.2.0
- share/man/normelog.1:1: Updated version from 1.0.10 to 0.2.0 and date to "October 2025"

---

## Phase 2 (v0.3.0) - Core Missing Features

This phase implements the essential missing features documented in TODO.md Phase 2.

---

### ✅ Error #11 - Unused NL_SHOW_ALL_DETAILS Variable

**Fixed**: 2025-10-24 (Phase 1)

**File**: `lib/format_text.sh:13-16`

**Issue**: The `NL_SHOW_ALL_DETAILS` variable was set but never used.

**Solution**: Implemented the feature to control detailed error output based on this variable (fixed in Error #2).

**Status**: Already fixed in Phase 1

---

### ✅ Error #12 - Plugin System Not Implemented

**Fixed**: 2025-10-24 (Phase 2)

**File**: `lib/update_check.sh`, `lib/update_apply.sh`, `plugins.d/`

**Issue**: README and man page mentioned a plugin system, but it was just placeholder code with empty functions.

**Solution**: Fully implemented hook-based plugin system with automatic discovery and loading.

**Changes**:
- lib/plugins.sh: Created new module with plugin loader
- plugins.d/.gitkeep: Created plugin directory with comprehensive documentation
- bin/normelog: Integrated plugin loading and hook calls throughout pipeline
- Added 4 hook points:
  - `nl_hook_pre_norminette()` - Before norminette execution
  - `nl_hook_post_parse()` - After parsing
  - `nl_hook_post_stats()` - After statistics
  - `nl_hook_pre_format()` - Before formatting

**Features**:
- Automatic discovery of `.sh` files in `plugins.d/`
- Alphabetical loading order
- Error handling for broken plugins
- Comprehensive logging

---

### ✅ Error #14 - JSON Escaping Bug

**Fixed**: 2025-10-24 (Phase 1)

**File**: `lib/format_json.sh:35`

**Issue**: JSON escaping was applied to entire line instead of just the message field.

**Solution**: Fixed in Error #3 - JSON escaping now only applies to message text.

**Status**: Already fixed in Phase 1

---

### ✅ Error #17 - Version Synchronization Between Binary and Man Page

**Fixed**: 2025-10-24 (Phase 2)

**File**: `lib/version.sh`, `share/man/normelog.1:1`, `scripts/gen-man.sh`

**Issue**: Version was hardcoded in two places (`lib/version.sh` and man page) and could get out of sync.

**Solution**: Implemented automatic version synchronization script.

**Changes**:
- scripts/gen-man.sh: Enhanced to automatically update man page version and date
- Added version extraction from man page
- Added comparison with current version
- Automatic update when versions don't match
- Added groff syntax validation

**Usage**: Run `make man` to synchronize version and date

---

### ✅ Update System Implementation

**Fixed**: 2025-10-24 (Phase 2)

**Files**: `lib/update_check.sh`, `lib/update_apply.sh`, `lib/flags.sh`, `bin/normelog`

**Issue**: Update check and apply functions were empty placeholders.

**Solution**: Fully implemented automatic update checking and one-command updates via GitHub Releases.

**Update Check Features**:
- Fetches latest version from GitHub Releases API
- Caches check results for 24 hours
- 5-second timeout for network requests
- Graceful handling of network failures
- Respects `NL_AUTO_UPDATE_CHECK` environment variable
- Can be disabled with `--no-update-check` flag

**Update Apply Features**:
- Downloads latest release tarball from GitHub
- Extracts and runs `make install` automatically
- Supports custom installation prefix
- Verifies version before/after update
- Automatic cleanup of temporary files
- Clear error messages and logging

**Changes**:
- lib/update_check.sh: Implemented update checking with caching
- lib/update_apply.sh: Implemented download and installation
- lib/flags.sh: Added `--update` and `--no-update-check` flags
- bin/normelog: Integrated update check at end of execution

---

### ✅ BATS Test Suite Implementation

**Fixed**: 2025-10-24 (Phase 2)

**Files**: `tests/`, `Makefile`

**Issue**: No automated testing system existed (only manual testing mentioned).

**Solution**: Implemented comprehensive BATS (Bash Automated Testing System) test suite.

**Changes**:
- tests/run_tests.sh: Created colored test runner script
- tests/unit/test_parse.bats: Unit tests for parse module
- tests/unit/test_filter.bats: Unit tests for filter module
- tests/unit/test_stats.bats: Unit tests for stats module
- tests/integration/test_cli.bats: Integration tests for CLI
- tests/fixtures/: Created test fixtures and sample data
- Makefile: Updated `test` target to run test suite

**Test Coverage**:
- Parser module: OK status, error extraction, multiple errors
- Filter module: Include/exclude patterns, preservation of FILE records
- Stats module: Error counting, type aggregation, file counting
- CLI: All command-line flags and options

---

