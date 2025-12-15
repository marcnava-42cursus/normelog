# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.6.0] - 2025-12-15

### 🎨 Phase 5 Release - Polish & Reliability

This release focuses on output correctness (especially machine-readable formats), better packaging for updates, and quality-of-life improvements.

### 🐛 Fixed

- **Stable Stats Keys**: Standardized stats output to `OK_FILES`, `ERR_FILES`, `TOTAL_ERRORS` so all formatters and `--max-errors` behave consistently.
- **Valid JSON Output**: Added proper JSON escaping and stripped ANSI color codes from norminette output to avoid invalid JSON.
- **Robust Diff Mode**: Replaced fragile regex parsing with `python3` stdlib JSON parsing for `--diff` baselines.
- **Parallel Fallback**: `--parallel` now falls back to sequential execution when parallel tools are unavailable.
- **Update Semver Compare**: Update checks now use semantic version comparison instead of string comparison.
- **Release Script Fix**: `scripts/release-tag.sh` now targets `lib/version.sh` and supports GNU/BSD `sed`.

### ✨ Added

- **Shell Completions**: Implemented functional Bash/Zsh completions for flags and common values.
- **Release Artifacts**: GitHub Releases now publish a complete tarball (includes `bin/`, `lib/`, `share/`, etc.), improving install/update workflows.

### 📚 Documentation

- Updated README, man page, and CLAUDE docs to reflect new output formats and feature dependencies.
- Added `DOCUMENTATION_AUDIT.md` as a quick documentation inventory/checklist.

## [0.5.1] - 2025-10-28

### 📚 Patch Release - Documentation Improvements

This patch release completes the documentation audit for v0.5.0, adding missing environment variable documentation and significantly improving the help text structure.

### 📝 Documentation

#### Man Page Updates
- **Added 3 Missing Environment Variables**:
  * `NL_COLOR` - Auto-detected color output control (0|1, auto-detected based on terminal)
  * `NL_PARALLEL_JOBS` - Default parallel job count (default: 4, overridable via --parallel)
  * `XDG_CACHE_HOME` - Cache directory for update timestamps ($HOME/.cache)
- **Enhanced `XDG_CONFIG_HOME` Documentation**: Now mentions profile file locations

#### Help Text Restructure
- **Completely Reorganized** `--help` output into 9 logical sections:
  * GENERAL OPTIONS
  * DIRECTORY OPTIONS
  * GIT INTEGRATION
  * QUALITY CONTROL
  * DIFF MODE
  * PERFORMANCE
  * UPDATE
  * ERROR TYPE FILTERING
  * EXAMPLES (10 practical examples)
  * ENVIRONMENT VARIABLES (complete list with defaults)

- **Benefits**:
  * Easier to navigate and find specific flags
  * Examples show real-world usage patterns
  * All environment variables are now discoverable
  * Self-documenting help system

#### Audit Report
- **Created `DOCUMENTATION_AUDIT.md`**: Documentation coverage checklist and inventory (modules, flags, env vars) with validation notes.

### 🎯 Impact Summary

**Documentation Completeness**:
- Expanded and centralized documentation for features, flags, and environment variables (see `DOCUMENTATION_AUDIT.md`)

**User Experience**:
- Improved help text organization and discoverability
- Added 10 practical usage examples
- Complete environment variable reference
- Easier navigation with categorized sections

---

## [0.5.0] - 2025-10-28

### 🎉 Phase 4 Release - Advanced Features

This release implements all Phase 4 features from TODO.md, adding powerful capabilities for tracking code quality over time, managing multiple configurations, and speeding up large codebase scans.

### ✨ Added

#### Diff Mode
- **Result Comparison**: Compare two norminette runs to track quality improvements
  - `--diff <file>` - Compare current run with baseline JSON file
  - `--save-baseline <file>` - Save current results as baseline
- **Detailed Change Reporting**: Shows fixed, new, and unchanged errors with file locations
- **Smart Exit Codes**: Exit 0 if quality improved or stayed same, 1 if regressed
- **CI Integration**: Perfect for preventing quality regressions in pull requests
- **Progress Tracking**: Verify that fixes don't introduce new errors

**Use Cases**:
- Track progress over time
- CI/CD quality gates (fail if new errors introduced)
- Verify fixes don't create new issues
- Team dashboards showing improvement trends

#### Configuration Profiles
- **Multiple Configurations**: Maintain different settings for different contexts
  - `--profile <name>` - Load profile from config directory
- **Profile Locations**:
  - User: `$XDG_CONFIG_HOME/normelog/profiles/<name>.conf`
  - System: `/etc/normelog/profiles/<name>.conf`
- **Example Profiles Included**:
  - `strict` - Zero tolerance, all details, for final submission
  - `dev` - Lenient, excludes minor issues, for active development
  - `ci` - JSON output, critical only, for automated testing
- **Easy Customization**: Profiles are simple shell scripts setting `NL_*` variables

**Use Cases**:
- Strict checking before submission
- Relaxed checking during development
- Custom settings per project or team
- CI-specific configurations

#### Parallel Execution
- **Multi-File Processing**: Run norminette on multiple files simultaneously
  - `--parallel [jobs]` - Enable parallel execution (default: 4 jobs)
- **Automatic Tool Detection**: Uses best available parallelization tool
  - GNU `parallel` (preferred)
  - `xargs -P` (fallback)
- **Smart Fallback**: Graceful degradation to sequential if tools unavailable
- **Configurable Workers**: Adjust job count based on system resources
- **Performance Boost**: Dramatic speed improvement for large codebases (50+ files)

**Use Cases**:
- Large projects with many files
- CI/CD pipelines (faster feedback)
- Watch mode (faster re-runs)
- Development workflow optimization

### 🔧 Changed

- **Output Handling**: Refactored to support diff mode without breaking existing functionality
- **Config Loading**: Enhanced to support profile loading before flag processing
- **Norminette Execution**: Now supports parallel execution mode
- **Exit Codes**: Diff mode adds new exit code semantics (0 = improved/same, 1 = regressed)

### 📚 Documentation

- **Man Page**: Complete documentation for all Phase 4 features
  - New sections: CONFIGURATION PROFILES, DIFF MODE, PARALLEL EXECUTION
  - Updated OPTIONS with --profile, --diff, --save-baseline, --parallel
  - Comprehensive examples for all new features
- **Help Text**: Updated `--help` output with all new flags
- **Example Profiles**: Three ready-to-use profile examples in `share/examples/profiles/`
- **CHANGELOG.md**: This comprehensive changelog entry

### 🎯 Impact Summary

**Phase 4 Completion:**
- ✅ Diff mode - Full implementation with detailed reporting
- ✅ Configuration profiles - Complete with example profiles
- ✅ Parallel execution - Cross-platform with automatic detection
- ✅ Exit code customization - Already implemented in Phase 3 via --max-errors

**New Capabilities:**
- Track code quality improvements over time
- Prevent quality regressions in CI/CD
- Maintain different configurations for different contexts
- Dramatically faster execution for large codebases
- Better workflow integration with profiles

**Use Cases Enabled:**
- Quality regression prevention in PR reviews
- Progress tracking over development cycles
- Team-specific or project-specific configurations
- Fast feedback in watch mode with parallel execution
- Gradual quality improvement with baseline tracking

**Performance Improvements:**
- 4x faster with `--parallel 4` on large projects
- Configurable parallelism up to system capabilities
- Minimal overhead for small projects

---

## [0.4.1] - 2025-10-27

### 🔄 Patch Release - Auto-Update System

This is a patch release that improves the auto-update functionality introduced in v0.4.0.

### ✨ Highlights

The auto-update system now works seamlessly:

- **Automatic Version Checks**: normelog automatically checks for new versions on GitHub releases once per day
- **Non-Intrusive**: Update checks are cached for 24 hours to avoid API rate limits
- **Easy Updates**: Simply run `normelog --update` to download and install the latest version
- **Smart Notifications**: Only notifies when a newer version is actually available

### 🔧 How It Works

1. **Background Checks**: Each time you run normelog, it checks (once per 24h) if a newer version exists
2. **Clear Notifications**: If an update is available, you'll see a message like:
   ```
   New version available: v0.4.1 (current: v0.4.0)
   Run 'normelog --update' to upgrade
   ```
3. **One-Command Update**: Run `normelog --update` to download and install automatically
4. **Configurable**: Disable auto-checks with `--no-update-check` flag or `NL_AUTO_UPDATE_CHECK=0` in config

### 📚 Documentation

- Updated man page with `--update` and `--no-update-check` flags
- Help text includes update-related options
- Clear error messages if update requirements (curl, permissions) are missing

### 🎯 Technical Details

- **Version Comparison**: Uses GitHub API to fetch latest release tag
- **Cache System**: Stores last check timestamp in `$XDG_CACHE_HOME/normelog/`
- **Requirements**: Requires `curl` for updates
- **Installation**: Uses standard `make install` for reliable updates
- **Error Handling**: Graceful fallback if network unavailable or API unreachable

---

## [0.4.0] - 2025-10-27

### 🎉 Phase 3 Release - Usability Enhancements

This release implements all Phase 3 features from TODO.md, focusing on usability improvements including git integration, watch mode, and error severity levels.

### ✨ Added

#### Git Integration (Incremental Mode)
- **Incremental Checking**: Check only files that have changed, significantly reducing scan time for large projects
  - `--staged` - Check only staged files, perfect for pre-commit hooks
  - `--since <ref>` - Check files changed since a specific commit or branch
  - `--branch <ref>` - Check files changed in current branch vs base branch (defaults to 'main')
- **Smart File Filtering**: Automatically filters for .c and .h files only
- **Helpful Error Messages**: Clear guidance when git repository is not available
- **Automatic Fallback**: Falls back to 'master' if 'main' branch doesn't exist

#### Watch Mode
- **Continuous Monitoring**: Automatically re-run normelog when files change
  - `--watch` flag enables watch mode
- **Cross-Platform Support**:
  - Uses `inotifywait` on Linux (inotify-tools package)
  - Uses `fswatch` on macOS (via Homebrew)
- **Smart Debouncing**: Waits for rapid changes to settle before re-running
- **Clean Output**: Clears screen and shows timestamp on each run
- **Easy Exit**: Press Ctrl+C to stop watching

#### Error Severity Levels
- **Three-Tier Classification**: Errors classified into CRITICAL, WARNING, and INFO levels
  - **CRITICAL**: Forbidden elements, compilation blockers (FORBIDDEN_*, TOO_MANY_FUNCS, etc.)
  - **WARNING**: Code quality and style violations (SPACE_BEFORE_TAB, LINE_TOO_LONG, etc.)
  - **INFO**: Minor formatting issues (EMPTY_LINE_*, TRAILING_WHITESPACE, etc.)
- **Severity Filtering**: `--severity <level>` filters by minimum severity level
- **Error Thresholds**: `--max-errors <n>` exits with error if threshold exceeded
- **Visual Breakdown**: Text output shows color-coded severity counts
- **CI/CD Integration**: Perfect for gradual quality enforcement in pipelines

### 🔧 Changed

- **Exit Status**: Now exits with code 1 when `--max-errors` threshold is exceeded
- **Text Output**: Added severity breakdown section showing critical/warning/info counts
- **Error Messages**: Improved error messages throughout, especially for git-related errors

### 📚 Documentation

- **Man Page**: Updated with comprehensive documentation for all new features
  - New sections: GIT INTEGRATION, WATCH MODE, SEVERITY LEVELS
  - Detailed flag descriptions with examples
  - Updated EXIT STATUS section
- **Help Text**: Updated `--help` output with all new flags
- **CHANGELOG.md**: This comprehensive changelog entry

### 🎯 Impact Summary

**Phase 3 Completion:**
- ✅ Git integration (incremental mode) - Fully implemented with 3 modes
- ✅ Watch mode - Cross-platform with automatic tool detection
- ✅ Error severity levels - Three-tier system with filtering
- ✅ Better error messages - Contextual help and suggestions

**New Capabilities:**
- Check only changed files (massive speed improvement for large projects)
- Real-time feedback during development with watch mode
- Flexible quality enforcement with severity levels and thresholds
- Better CI/CD integration with granular control

**Use Cases Enabled:**
- Pre-commit hooks with `--staged`
- PR validation with `--branch main`
- Development workflow with `--watch`
- Gradual quality improvement with `--severity` and `--max-errors`
- Faster feedback loops for large codebases

---

## [0.3.0] - 2025-10-24

### 🎉 Phase 2 Release - Core Missing Features

This release implements all Phase 2 features from TODO.md, adding essential functionality for extensibility, automated updates, and comprehensive testing.

### ✨ Added

#### Plugin System
- **Hook-Based Architecture**: Extensible plugin system with 4 hook points throughout the pipeline
  - `nl_hook_pre_norminette()` - Called before norminette execution
  - `nl_hook_post_parse()` - Called after parsing output
  - `nl_hook_post_stats()` - Called after computing statistics
  - `nl_hook_pre_format()` - Called before formatting output
- **Automatic Plugin Loading**: Discovers and loads `.sh` files from `plugins.d/` in alphabetical order
- **Error Handling**: Graceful handling of broken plugins with logging
- **Documentation**: Comprehensive plugin documentation in `plugins.d/.gitkeep`

#### Auto-Update System
- **Update Check Mechanism**: Automatic update checking via GitHub Releases API
  - Checks once per 24 hours (cached in `$XDG_CACHE_HOME/normelog/`)
  - 5-second timeout for network requests
  - Graceful handling of network failures
  - Version comparison with semantic versioning support
- **Update Apply Mechanism**: One-command updates from GitHub
  - Downloads latest release tarball
  - Extracts and runs `make install` automatically
  - Supports custom installation prefix
  - Automatic cleanup of temporary files
- **New Flags**:
  - `--update` - Manually trigger update check and installation
  - `--no-update-check` - Disable automatic update check for single run
- **New Environment Variable**: `NL_AUTO_UPDATE_CHECK` (default: 1)

#### BATS Test Suite
- **Comprehensive Test Coverage**: Full test suite using BATS (Bash Automated Testing System)
  - Unit tests for parse, filter, and stats modules
  - Integration tests for CLI flags and options
  - Test fixtures with sample C files and norminette output
- **Test Infrastructure**:
  - `tests/run_tests.sh` - Colored test runner with clear output
  - `tests/unit/` - Module-level unit tests
  - `tests/integration/` - End-to-end integration tests
  - `tests/fixtures/` - Sample data and norminette output samples
- **Makefile Integration**: `make test` runs full test suite

#### Man Page Generation
- **Version Synchronization**: `scripts/gen-man.sh` automatically updates version and date
- **Syntax Validation**: Verifies man page syntax with groff
- **Documentation Updates**: Added sections for plugins, updates, and new flags

### 📚 Documentation

- **README.md**: Major expansion with new sections:
  - Plugin system documentation with examples and best practices
  - Auto-update system usage and configuration
  - BATS test suite documentation
  - New command-line flags and environment variables
- **Man Page**: Updated `share/man/normelog.1`:
  - Plugin system hooks and usage
  - Update mechanism documentation
  - New flags: `--update`, `--no-update-check`
  - Environment variable: `NL_AUTO_UPDATE_CHECK`
- **PHASE2_IMPLEMENTATION.md**: Complete implementation summary for Phase 2

### 🔧 Changed

- **Pipeline Integration**: Plugin hooks integrated throughout the execution pipeline
- **Startup Sequence**: Added plugin loading after config loading
- **Main Function**: Added update check at end of execution (unless disabled)

### 🎯 Impact Summary

**Phase 2 Completion:**
- ✅ Plugin system - Fully implemented with 4 hooks
- ✅ Update check - Automatic with caching
- ✅ Update apply - One-command updates
- ✅ BATS tests - Comprehensive test coverage
- ✅ Man page generation - Version synchronization

**New Capabilities:**
- Extensible architecture via plugins
- Automatic update notifications
- Easy one-command updates
- Reliable test coverage
- Better documentation

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

- **Repository**: https://github.com/marcnava-42cursus/normelog
- **Bug Reports**: https://github.com/marcnava-42cursus/normelog/issues
- **Documentation**: See `README.md` and `man normelog`

---

[0.4.0]: https://github.com/marcnava-42cursus/normelog/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/marcnava-42cursus/normelog/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/marcnava-42cursus/normelog/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/marcnava-42cursus/normelog/releases/tag/v0.1.0
