# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.2.0] - 2025-10-24

### 🎉 Phase 1 Release - Critical Fixes & Core Functionality

This release focuses on fixing all critical and medium-priority bugs identified in the codebase audit, implementing missing core features, and establishing proper installation mechanisms.

### ✨ Added

- **Configuration Examples**: Created comprehensive example configuration file (`share/examples/normelog.conf.example`) with all `NL_*` variables documented
- **Library Path Detection**: Intelligent detection of library paths to support both development and installed environments
- **Empty Output Validation**: Added validation to handle cases where norminette produces no output
- **TTY Detection**: Automatic color output detection based on whether stdout is a terminal
- **FIXED.md**: New document tracking all resolved issues with detailed explanations
- **CHANGELOG.md**: This changelog file to track version history

### 🐛 Fixed

#### Critical Fixes

- **JSON Formatter AWK Bug**: Fixed incorrect variable references in `lib/format_json.sh` that caused stats to always show 0
  - Now correctly uses `split()` to extract fields from stats strings
  - Fixed JSON escaping to apply only to message text, preventing malformed JSON

- **Case-Insensitive Filtering**: Implemented case-insensitive substring matching for error type filtering in `lib/filter.sh`
  - Patterns now use `toupper()` and `index()` for proper matching
  - Users can now filter with partial patterns (e.g., "SPACE" matches "SPACE_BEFORE_TAB")

- **Flag `-a` Implementation**: Fixed the `-a` (show all details) flag that previously had no effect
  - Details now only show when `-a` is set or when filtering by specific error types
  - Provides cleaner default output showing only summaries and counts

- **Shell Environment Setup**: Moved `set -euo pipefail` from sourced library (`lib/env.sh`) to main script (`bin/normelog`)
  - Prevents unexpected exits in interactive shells
  - Makes libraries safer to source for testing

#### Medium Priority Fixes

- **Log Output Redirection**: All log messages now correctly go to stderr instead of stdout
  - Prevents debug output from polluting actual results
  - Fixes issues with JSON output and piping

- **Color Output Detection**: Replaced hardcoded `NL_COLOR=1` with automatic TTY detection
  - Colors only appear when outputting to a terminal
  - Prevents ANSI codes in redirected output or pipes

- **Lint Script Paths**: Fixed incorrect paths in `scripts/lint.sh`
  - Changed from hardcoded `normelog/bin/normelog` to relative paths
  - Added `cd "$(dirname "$0")/.."` to work from project root

- **shfmt Configuration**: Fixed indentation mismatch between lint script and `.editorconfig`
  - Changed from `-i 2` (2 spaces) to `-i 0` (tabs) to match project standards

#### Installation & Version Fixes

- **Makefile Library Installation**: Fixed Makefile to install library files, not just the binary
  - Added `LIBDIR` variable pointing to `$(PREFIX)/lib/normelog`
  - Libraries now properly installed to `/usr/local/lib/normelog/`
  - Added library cleanup to `uninstall` target

- **Version Consistency**: Updated all version references to 0.2.0
  - Fixed man page showing incorrect version (1.0.10)
  - Updated man page to current date "October 2025"
  - Synchronized `lib/version.sh` and `share/man/normelog.1`

- **Binary Path Resolution**: Enhanced `bin/normelog` to detect library location
  - Checks for installed location (`/usr/local/lib/normelog`)
  - Falls back to development location (`./lib`)
  - Provides clear error if libraries not found

### 🔧 Changed

- **Error Tracking**: Reorganized error documentation
  - `ERRORS.md` now only contains pending low-priority issues (10 remaining)
  - All fixed errors documented in `FIXED.md` with full context

- **Bash Configuration**: Cleaned up user environment
  - Removed commented-out alias from `.bashrc`

### 📚 Documentation

- Updated `ERRORS.md` to reflect current state (0 critical, 0 medium, 10 low-priority issues)
- Created detailed `FIXED.md` with complete documentation of all fixes
- Added comprehensive `share/examples/normelog.conf.example` with usage examples

### 🎯 Impact Summary

**Before Phase 1:**
- 5 critical errors
- 5 medium priority errors
- Installation broken (libraries not installed)
- Multiple features not working as documented

**After Phase 1:**
- ✅ 0 critical errors
- ✅ 0 medium priority errors
- ✅ Fully functional installation system
- ✅ All core features working as documented
- 10 low-priority issues remaining (planned for future releases)

---

## [0.1.0] - 2025-09-03

### Initial Release

- Basic norminette wrapper functionality
- Text and JSON output formats
- Directory inclusion/exclusion
- Error type filtering
- Statistics computation
- Man page and shell completions

---

## Links

- **Repository**: https://github.com/yourusername/normelog
- **Bug Reports**: https://github.com/yourusername/normelog/issues
- **Documentation**: See `README.md` and `man normelog`

---

[0.2.0]: https://github.com/yourusername/normelog/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/yourusername/normelog/releases/tag/v0.1.0
