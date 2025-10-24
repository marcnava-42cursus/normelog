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

