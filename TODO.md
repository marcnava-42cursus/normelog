# TODO.md

This document lists missing features mentioned in documentation, planned features, and suggested improvements for normelog.

---

## Missing Features (Documented but Not Implemented)

These features are mentioned in the manual, README, or CLAUDE.md but are not yet implemented.

### 1. **Plugin System** 🔴 HIGH PRIORITY

**Status**: Placeholder only

**Location**: `plugins.d/`, `lib/update_check.sh`, `lib/update_apply.sh`

**Description**: The man page (line 127) and README mention a plugin system where users can drop scripts into `plugins.d/` to extend behavior, but no loader exists.

**Requirements**:
- Plugin discovery in `plugins.d/`
- Source all `.sh` files in alphabetical order
- Define plugin API/hooks (pre-run, post-run, post-parse, etc.)
- Error handling for broken plugins
- Plugin documentation

**Implementation Plan**:
```bash
# Add to bin/normelog after sourcing libs
nl_plugins_load() {
	local plugin_dir="$BASE_DIR/plugins.d"
	if [[ -d "$plugin_dir" ]]; then
		for plugin in "$plugin_dir"/*.sh; do
			[[ -f "$plugin" ]] || continue
			nl_log_debug "Loading plugin: $plugin"
			# shellcheck disable=SC1090
			. "$plugin" || nl_log_warn "Failed to load plugin: $plugin"
		done
	fi
}
```

**Hooks to implement**:
- `nl_hook_pre_norminette()` - Called before norminette execution
- `nl_hook_post_parse()` - Called after parsing, can modify records
- `nl_hook_post_stats()` - Called after stats computation
- `nl_hook_pre_format()` - Called before formatting output

---

### 2. **Update Check and Auto-Update** 🔴 HIGH PRIORITY

**Status**: Placeholder functions only

**Location**: `lib/update_check.sh`, `lib/update_apply.sh`

**Description**: README mentions "GitHub Releases integration" and update mechanism, but functions are empty stubs.

**Requirements**:
- Check GitHub API for latest release
- Compare with current version
- Download and verify new release
- Replace binary in-place or prompt user
- Respect opt-out flag (e.g., `NL_AUTO_UPDATE=0`)

**Implementation Plan**:

`lib/update_check.sh`:
```bash
nl_update_check() {
	[[ "${NL_AUTO_UPDATE_CHECK:-1}" -eq 0 ]] && return 0

	local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/normelog/last_check"
	local cache_age=86400  # 24 hours

	# Check cache freshness
	if [[ -f "$cache_file" ]]; then
		local last_check=$(cat "$cache_file")
		local now=$(date +%s)
		(( now - last_check < cache_age )) && return 0
	fi

	# Fetch latest version from GitHub
	local latest=$(curl -sL https://api.github.com/repos/USER/normelog/releases/latest |
		grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

	if [[ -n "$latest" ]] && [[ "$latest" != "$NL_VERSION" ]]; then
		nl_log_info "New version available: $latest (current: $NL_VERSION)"
		nl_log_info "Run 'normelog --update' to upgrade"
	fi

	# Update cache
	mkdir -p "$(dirname "$cache_file")"
	date +%s > "$cache_file"
}
```

`lib/update_apply.sh`:
```bash
nl_update_apply() {
	nl_log_info "Checking for updates..."
	local latest=$(curl -sL https://api.github.com/repos/USER/normelog/releases/latest |
		grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

	if [[ "$latest" == "$NL_VERSION" ]]; then
		nl_log_info "Already on latest version: $NL_VERSION"
		return 0
	fi

	nl_log_info "Downloading version $latest..."
	# Download, verify checksum, install
	# Implementation depends on release artifact structure
}
```

**New flags**:
- `--update` - Manually trigger update
- `--no-update-check` - Disable automatic update check

---

### 3. **Conditional Detail Display (Fix for `-a` flag)** 🔴 HIGH PRIORITY

**Status**: Flag exists but does nothing (see ERRORS.md #2)

**Location**: `lib/format_text.sh`, `bin/normelog`

**Description**: The `-a` flag should control whether detailed per-file errors are shown, but currently they're always shown.

**Requirements**:
- Without `-a`: Show only summary and error counts
- With `-a`: Show summary, counts, AND per-file details
- When filtering by type: Always show details (backward compatibility)

**Implementation**: See ERRORS.md #2 for solution

---

### 4. **Configuration File Examples** 🟡 MEDIUM PRIORITY

**Status**: Not created

**Location**: Should be in `share/examples/` or docs

**Description**: README mentions config files but provides no examples to install.

**Requirements**:
- Create `share/examples/normelog.conf.example`
- Document all available `NL_*` variables
- Provide common use-case examples
- Update Makefile to optionally install example config

**Implementation**:
```bash
# share/examples/normelog.conf.example

# Output format (text|json)
#NL_OUTPUT=text

# Enable debug mode (0|1)
#NL_DEBUG=0

# Show all details by default (0|1)
#NL_SHOW_ALL_DETAILS=0

# Use gitignore by default (0|1)
#NL_USE_GITIGNORE=1

# Directories to always exclude (array)
#NL_EXCLUDE_DIRS=(build .cache obj)

# Error types to always exclude (array)
#NL_EXCLUDE_TYPES=(SPACE_EMPTY_LINE CONSECUTIVE_NEWLINES)

# Color output (0|1, auto-detected if not set)
#NL_COLOR=1

# Automatic update check (0|1)
#NL_AUTO_UPDATE_CHECK=1
```

---

### 5. **BATS Test Suite** 🟡 MEDIUM PRIORITY

**Status**: Not implemented

**Location**: Should be in `tests/`

**Description**: CLAUDE.md and README mention BATS testing but no tests exist.

**Requirements**:
- Install BATS framework
- Test each module independently
- Integration tests for full pipeline
- Test error cases and edge cases
- CI integration

**Test Structure**:
```
tests/
├── fixtures/
│   ├── sample-ok.c
│   ├── sample-errors.c
│   └── norminette-output-samples/
├── unit/
│   ├── test_parse.bats
│   ├── test_filter.bats
│   ├── test_stats.bats
│   └── test_format.bats
└── integration/
    ├── test_pipeline.bats
    └── test_cli.bats
```

**Example test**:
```bash
# tests/unit/test_parse.bats
@test "parse handles OK status" {
	source lib/parse.sh
	result=$(echo "test.c: OK!" | nl_parse_output)
	[[ "$result" == "FILE test.c STATUS OK" ]]
}

@test "parse extracts error details" {
	source lib/parse.sh
	input="Error: SPACE_TAB    (line:   5, col:   3):  space before tab"
	result=$(echo "$input" | nl_parse_output)
	[[ "$result" =~ "ERR SPACE_TAB 5 3" ]]
}
```

---

### 6. **Man Page Auto-Generation** 🟢 LOW PRIORITY

**Status**: Partially implemented

**Location**: `scripts/gen-man.sh`

**Description**: The gen-man.sh script exists but is empty. Should extract documentation from source comments.

**Requirements**:
- Parse special comment blocks from `bin/normelog` or a separate doc file
- Generate `.1` man page format
- Include version, date, examples
- Auto-update during build

**Implementation**: Use `help2man` or custom parser:
```bash
#!/usr/bin/env bash
# scripts/gen-man.sh
set -euo pipefail

cd "$(dirname "$0")/.."
source lib/version.sh

help2man -N \
	--name="Analyzer and filter for norminette" \
	--section=1 \
	--version-string="$NL_VERSION" \
	--help-option="--help" \
	bin/normelog > share/man/normelog.1

echo "Generated share/man/normelog.1"
```

---

## Suggested Improvements

New features and enhancements that would improve normelog but aren't currently documented.

### 7. **Configuration Profiles** 🟡 MEDIUM PRIORITY

**Description**: Allow users to maintain multiple configuration profiles for different projects.

**Use Case**:
- Strict profile for submission
- Lenient profile for development
- Team-specific configurations

**Implementation**:
```bash
# Usage
normelog --profile strict
normelog --profile dev

# Loads from $XDG_CONFIG_HOME/normelog/profiles/strict.conf
```

---

### 8. **Watch Mode** 🟡 MEDIUM PRIORITY

**Description**: Continuously monitor files and re-run norminette on changes.

**Use Case**: Development workflow - see errors update in real-time

**Implementation**:
```bash
normelog --watch

# Uses inotifywait or fswatch to monitor .c and .h files
# Re-runs pipeline on any change
# Clears screen and shows updated results
```

**Requirements**:
- Detect `inotifywait` or `fswatch` availability
- Debounce rapid changes
- Optional: desktop notifications on new errors

---

### 9. **HTML Report Generation** 🟢 LOW PRIORITY

**Description**: Generate a beautiful HTML report with syntax highlighting and navigation.

**Use Case**: Code reviews, CI artifacts, team dashboards

**Implementation**:
```bash
normelog --html > report.html

# Or
normelog --html --output report.html
```

**Features**:
- Syntax-highlighted code snippets
- Clickable file navigation
- Error grouping and filtering
- Charts/graphs for error distribution
- Responsive design for mobile viewing

---

### 10. **Incremental Mode (Git Integration)** 🔴 HIGH PRIORITY

**Description**: Only check files changed since last commit or between commits.

**Use Case**:
- Pre-commit hooks (only check staged files)
- CI/CD (only check changed files in PR)
- Faster feedback during development

**Implementation**:
```bash
# Check only staged files
normelog --staged

# Check files changed in last commit
normelog --since HEAD~1

# Check files in current branch vs main
normelog --branch main

# Internal implementation
git diff --name-only --cached | grep -E '\.(c|h)$' | xargs norminette
```

---

### 11. **Error Severity Levels** 🟡 MEDIUM PRIORITY

**Description**: Categorize errors by severity (critical, warning, info) and allow filtering.

**Use Case**:
- Focus on critical errors first
- Different exit codes for different severity levels
- CI can fail on critical but warn on style

**Implementation**:
```bash
normelog --severity critical
normelog --min-severity warning  # Show warning and critical
normelog --max-errors 0 --severity critical  # Fail if any critical errors

# Configuration
CRITICAL_ERRORS=(FORBIDDEN_CS TOO_MANY_FUNCS FORBIDDEN_CHAR_NAME)
WARNING_ERRORS=(SPACE_* TAB_* LINE_TOO_LONG)
INFO_ERRORS=(EMPTY_LINE_*)
```

**Exit codes**:
- 0: No errors
- 1: Info errors only
- 2: Warnings present
- 3: Critical errors present

---

### 12. **Diff Mode** 🟡 MEDIUM PRIORITY

**Description**: Compare two runs and show what errors were added/fixed.

**Use Case**:
- Track progress over time
- Verify fixes didn't introduce new errors
- CI comparison (before vs after)

**Implementation**:
```bash
# Save baseline
normelog --json > baseline.json

# After changes
normelog --diff baseline.json

# Output
# ✅ Fixed: 15 errors
# ❌ New: 3 errors
# ➡️  Unchanged: 42 errors
```

---

### 13. **Custom Rules/Checks** 🟢 LOW PRIORITY

**Description**: Allow users to define custom checks beyond norminette.

**Use Case**:
- Project-specific naming conventions
- Banned function detection
- Custom header format validation

**Implementation**:
```bash
# .normelog/rules/custom-checks.sh
nl_custom_check_banned_functions() {
	local file="$1"
	if grep -q "printf" "$file"; then
		echo "CUSTOM_BANNED_FUNC: printf is not allowed in this project"
	fi
}
```

---

### 14. **Statistics Tracking Over Time** 🟢 LOW PRIORITY

**Description**: Track error counts over time and show trends.

**Use Case**:
- Measure code quality improvement
- Team dashboards
- Motivational feedback

**Implementation**:
```bash
normelog --stats-track

# Stores results in ~/.local/share/normelog/stats.db (SQLite or JSON)
# Can query with:
normelog --stats-show
normelog --stats-graph  # ASCII graph of errors over time
```

---

### 15. **Auto-Fix Mode (Experimental)** 🟢 LOW PRIORITY

**Description**: Automatically fix certain error types (spacing, tabs, etc.)

**Use Case**:
- Quick cleanup before submission
- Batch fixing of simple errors

**Implementation**:
```bash
normelog --fix SPACE_* TAB_*

# Uses sed/awk to fix errors in-place
# Creates backups before modifying
# Shows diff of changes
```

**Safety**:
- Only fix simple, reversible errors
- Always create `.bak` files
- Require explicit confirmation for multiple files
- Never fix structural errors (only formatting)

---

### 16. **Language Server Protocol (LSP) Support** 🟢 LOW PRIORITY

**Description**: Provide real-time norminette feedback in editors via LSP.

**Use Case**:
- VSCode, Vim, Emacs integration
- See errors as you type
- Inline error messages

**Implementation**: Create separate `normelog-lsp` binary that implements LSP protocol.

---

### 17. **Parallel Execution** 🟡 MEDIUM PRIORITY

**Description**: Run norminette on multiple files in parallel for speed.

**Use Case**: Large codebases (50+ files)

**Implementation**:
```bash
normelog --parallel 4  # Use 4 processes

# Internal: use GNU parallel or xargs -P
find . -name "*.c" -o -name "*.h" | \
	parallel -j4 norminette {} | \
	nl_parse_output | ...
```

---

### 18. **Exit Code Customization** 🟡 MEDIUM PRIORITY

**Description**: Allow users to configure exit codes based on error types or counts.

**Use Case**:
- CI pipelines with specific requirements
- Gradual rollout (warn now, fail later)

**Implementation**:
```bash
normelog --fail-on TOO_MANY_FUNCS  # Exit 1 if this error exists
normelog --max-errors 10            # Exit 1 if more than 10 errors
normelog --max-per-type 5           # Exit 1 if any type has > 5 errors

# Configuration file
NL_FAIL_ON_TYPES=(FORBIDDEN_CS TOO_MANY_FUNCS)
NL_MAX_TOTAL_ERRORS=50
NL_MAX_PER_FILE=10
```

---

### 19. **Integration with External Tools** 🟢 LOW PRIORITY

**Description**: Export data to popular tools and formats.

**Formats**:
- JUnit XML (for Jenkins, GitLab CI)
- SARIF (Static Analysis Results Interchange Format)
- Checkstyle XML (for SonarQube)
- GitHub Actions annotations

**Implementation**:
```bash
normelog --format junit > results.xml
normelog --format sarif > results.sarif
normelog --github-actions  # Emits ::error:: annotations
```

---

### 20. **Interactive Mode** 🟢 LOW PRIORITY

**Description**: TUI (Text User Interface) for exploring errors.

**Use Case**:
- Navigate large error lists easily
- Filter and search interactively
- Open files in editor at error location

**Implementation**: Use `fzf` or `dialog` for interactive selection:
```bash
normelog --interactive

# Shows:
# [↓↑] Navigate  [Enter] View  [f] Filter  [q] Quit
# > src/main.c (15 errors)
#   src/utils.c (8 errors)
#   include/header.h (3 errors)
```

---

## Summary

### Missing Features (Must Implement): 6
1. ✅ Plugin System
2. ✅ Update Check/Auto-Update
3. ✅ Fix `-a` flag
4. ✅ Config Examples
5. ✅ BATS Tests
6. ✅ Man Page Generation

### Suggested Improvements: 14

**High Priority** (3):
- Incremental Mode (Git Integration)
- Plugin System
- Update Mechanism

**Medium Priority** (6):
- Configuration Profiles
- Watch Mode
- Error Severity Levels
- Diff Mode
- Parallel Execution
- Exit Code Customization

**Low Priority** (5):
- HTML Report
- Statistics Tracking
- Auto-Fix Mode
- LSP Support
- External Tool Integration
- Interactive Mode

---

## Implementation Priority

### Phase 1 (v0.2.0) - Fix Existing Issues
1. Fix all critical errors from ERRORS.md
2. Implement `-a` flag properly
3. Add config examples
4. Update documentation

### Phase 2 (v0.3.0) - Core Missing Features
1. Plugin system
2. Update mechanism
3. BATS test suite
4. Man page generation

### Phase 3 (v0.4.0) - Usability
1. Incremental mode (git integration)
2. Watch mode
3. Error severity levels
4. Better error messages

### Phase 4 (v0.5.0) - Advanced Features
1. Diff mode
2. Configuration profiles
3. Parallel execution
4. Exit code customization

### Phase 5 (v1.0.0) - Polish
1. HTML reports
2. External tool integration
3. Performance optimizations
4. Comprehensive documentation
