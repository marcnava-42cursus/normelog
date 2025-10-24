# ERRORS.md

This document lists all errors, bugs, and issues found in the normelog codebase during analysis.

## Critical Errors

### 1. **Environment Setup Issue - `set -euo pipefail` in Sourced Library**

**File**: `lib/env.sh:3`

**Issue**: The `set -euo pipefail` is executed inside `nl_env_init()`, which is called from `bin/normelog`. This can cause unexpected exits in interactive shells or when sourcing the library for testing.

**Cause**: The `pipefail` and `errexit` options propagate to the parent shell when sourced, making the entire script fragile. Any command that returns non-zero will immediately exit.

**Impact**: High - Can cause premature script termination

**Solution**:
```bash
# Move set -euo pipefail to bin/normelog main script only
# In lib/env.sh, just initialize variables:
nl_env_init() {
	: "${XDG_CONFIG_HOME:=${HOME}/.config}"
	: "${NL_OUTPUT:=text}"
}
```

And in `bin/normelog` add at the top (after shebang):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Then source libraries...
```

---

### 2. **Missing Output Mode in `-a` Flag Logic**

**File**: `lib/format_text.sh:13-16`, `bin/normelog:95-99`

**Issue**: The `-a` flag sets `NL_SHOW_ALL_DETAILS=1`, but this variable is never checked or used anywhere in the codebase.

**Cause**: The text formatter always shows all details regardless of the `-a` flag. The filtering logic that should conditionally show details based on this flag is missing.

**Impact**: Medium - The `-a` flag has no effect

**Solution**: Implement conditional output in `nl_format_text()`:
```bash
nl_format_text() {
	local records="$1" stats="$2"
	echo "$stats" | awk '
		/^STATS OK/ {ok=$3}
		/^STATS ERR/ {er=$3}
		END { printf "\033[32mCorrect files: %d\033[0m\n\033[31mIncorrect files: %d\033[0m\n\n", ok, er }
	'
	echo "Error type count:"
	echo "--------------------"
	echo "$stats" | awk '/^TYPE /{ printf "%-25s: %d\n", $2, $3 }'
	echo ""

	# Only show details if -a flag is set or if filtering by type
	if [[ "${NL_SHOW_ALL_DETAILS}" -eq 1 ]] || [[ ${#NL_INCLUDE_TYPES[@]} -gt 0 ]]; then
		echo "$records" | awk '
			/^FILE /{file=$2}
			/^ERR /{printf "%s\n    %s (line: %3s, col: %3s): %s\n", file, $2, $3, $4, substr($0, index($0,$5))}
		'
	fi
}
```

---

### 3. **AWK Variable References Bug in JSON Formatter**

**File**: `lib/format_json.sh:10-12`

**Issue**: AWK is trying to use shell-style `$3` and `$2` inside a `BEGIN` block where no fields exist yet.

```bash
if (S[i] ~ /^STATS OK/) ok=$3      # BUG: $3 doesn't exist here
else if (S[i] ~ /^STATS ERR/) err=$3
else if (S[i] ~ /^TOTAL/) total=$2
```

**Cause**: Incorrect AWK syntax - should use `split()` to extract fields from the array element.

**Impact**: High - JSON output will show 0 for ok_files, error_files, and total_errors

**Solution**:
```bash
if (S[i] ~ /^STATS OK/) { split(S[i], a, " "); ok=a[3] }
else if (S[i] ~ /^STATS ERR/) { split(S[i], a, " "); err=a[3] }
else if (S[i] ~ /^TOTAL/) { split(S[i], a, " "); total=a[2] }
```

---

### 4. **Case-Insensitive Filtering Not Implemented**

**File**: `lib/filter.sh:3-17`

**Issue**: The man page and README state that error type filtering is case-insensitive, but the actual implementation uses exact string matching in AWK associative arrays.

**Cause**: The include/exclude arrays are built from the exact command-line arguments without converting to uppercase.

**Impact**: Medium - Users expect case-insensitive matching but get case-sensitive

**Solution**: Convert all patterns to uppercase in AWK:
```bash
nl_filter_errors() {
	awk -v inc="${NL_INCLUDE_TYPES[*]:-}" -v exc="${NL_EXCLUDE_TYPES[*]:-}" '
		BEGIN {
			ninc=split(inc, I, " "); nexc=split(exc, E, " ")
			for (i=1;i<=ninc;i++) if (I[i] != "") INC[toupper(I[i])]=1
			for (i=1;i<=nexc;i++) if (E[i] != "") EXC[toupper(E[i])]=1
		}
		/^ERR / {
			type=$2; keep=1; type_upper=toupper(type)
			if (ninc>0) {
				keep=0
				for (pattern in INC) {
					if (index(type_upper, pattern) > 0) { keep=1; break }
				}
			}
			for (pattern in EXC) {
				if (index(type_upper, pattern) > 0) { keep=0; break }
			}
			if (keep) print; next
		}
		/^FILE / { print }
	'
}
```

---

### 5. **Substring Matching Not Implemented**

**File**: `lib/filter.sh:11`

**Issue**: The documentation says patterns use "substring match", but the code uses exact key lookup: `if (ninc>0 && !(type in INC)) keep=0`

**Cause**: Using associative array membership test instead of substring matching

**Impact**: High - Users can't filter with partial patterns like "SPACE" to match "SPACE_BEFORE_TAB"

**Solution**: Use substring matching with `index()` function (see solution in Error #4)

---

## Medium Priority Errors

### 6. **Incorrect Color Output Detection**

**File**: `lib/log.sh:2-4`

**Issue**: The color is hardcoded to always be enabled (`NL_COLOR=1`), but there's no detection for whether stdout is a TTY.

**Cause**: Missing TTY detection logic

**Impact**: Medium - Color codes appear in redirected output or pipes

**Solution**:
```bash
# Detect if stdout is a terminal
[[ -t 1 ]] && NL_COLOR=1 || NL_COLOR=0

nl_log_color() { [[ "$NL_COLOR" -eq 1 ]] || return 0; printf "\033[%sm" "$1"; }
nl_log_reset() { [[ "$NL_COLOR" -eq 1 ]] || return 0; printf "\033[0m"; }
```

---

### 7. **Debug Messages Go to stdout Instead of stderr**

**File**: `lib/log.sh:9`

**Issue**: `nl_log_debug()` uses `echo` which writes to stdout, mixing debug output with actual results.

**Cause**: Missing stderr redirection

**Impact**: Medium - Debug output pollutes actual output, especially with `--json`

**Solution**:
```bash
nl_log_debug() { [[ "${NL_DEBUG:-0}" -eq 1 ]] && nl_log DEBUG "$@" >&2 || true; }
```

Also fix all other log functions:
```bash
nl_log() { local lvl=$1; shift; echo "[$lvl] $*" >&2; }
```

---

### 8. **Lint Script Has Wrong Paths**

**File**: `scripts/lint.sh:3-4`

**Issue**: The script references `normelog/bin/normelog` and `normelog/lib/*.sh` but should use relative paths from the project root.

**Cause**: Hardcoded paths that don't match the actual project structure

**Impact**: Medium - `make lint` doesn't work

**Solution**:
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v shellcheck >/dev/null && shellcheck -x bin/normelog lib/*.sh scripts/*.sh || true
command -v shfmt >/dev/null && shfmt -d -i 4 -s . || true
```

---

### 9. **shfmt Configuration Mismatch**

**File**: `scripts/lint.sh:4`

**Issue**: The lint script uses `shfmt -i 2` (2 spaces) but `.editorconfig` specifies tabs with width 4.

**Cause**: Configuration was updated but lint script wasn't

**Impact**: Medium - Linting will fail on all files

**Solution**:
```bash
command -v shfmt >/dev/null && shfmt -d -i 0 -s . || true  # -i 0 means tabs
```

---

### 10. **Missing Error Handling for Empty norminette Output**

**File**: `bin/normelog:72-78`

**Issue**: If norminette produces no output (empty directory, no C files), the pipeline will process empty strings, potentially causing issues.

**Cause**: No validation of norminette output before processing

**Impact**: Low - May produce confusing output

**Solution**: Add validation:
```bash
output=$(nl_run_norminette)
rc=$?
if [[ $rc -eq 127 ]]; then
	nl_log_error "norminette not found in PATH"
	exit 127
fi

if [[ -z "$output" ]]; then
	nl_log_error "No C files found or norminette produced no output"
	exit 0
fi
```

---

## Low Priority Issues

### 11. **Unused Variables in format_text.sh**

**File**: `lib/format_text.sh:13-16`

**Issue**: The `NL_SHOW_ALL_DETAILS` variable is set but never used (see Error #2).

**Impact**: Low - Confusing for maintainers

**Solution**: Implement the feature or remove the variable

---

### 12. **Plugin System Not Implemented**

**File**: `lib/update_check.sh`, `lib/update_apply.sh`, `plugins.d/sample-plugin.sh`

**Issue**: The manual and README mention a plugin system, but it's just placeholder functions.

**Cause**: Feature not yet implemented

**Impact**: Low - Documented feature doesn't exist

**Solution**: Either implement plugin loading or mark as "planned feature" in docs

---

### 13. **No Input Validation for Directory Arguments**

**File**: `lib/flags.sh:74-94`

**Issue**: The `-d` and `-n` flags accept any string as directory without validation.

**Cause**: Missing validation logic

**Impact**: Low - Errors will occur later in norminette execution

**Solution**: Add validation:
```bash
-d*)
	if [[ ${#1} -gt 2 ]]; then
		dir="${1#-d}"
	else
		dir="$2"
		shift
	fi
	if [[ ! -d "$dir" ]]; then
		nl_log_error "Directory does not exist: $dir"
		exit 1
	fi
	NL_DIRS+=("$dir")
	;;
```

---

### 14. **JSON Escaping Bug**

**File**: `lib/format_json.sh:35`

**Issue**: The line `gsub(/"/, "\\\"", R[i])` escapes quotes in the entire line, but then only a substring is used. This means quotes in the message might not be properly escaped.

**Cause**: Escaping happens on wrong variable

**Impact**: Low - Malformed JSON if error messages contain quotes

**Solution**:
```bash
# Extract message first, then escape
msg_text = substr(R[i], msg)
gsub(/"/, "\\\"", msg_text)
printf "%s\"}", msg_text
```

---

### 15. **Completion Files Not Tested**

**File**: `share/completion/normelog.bash`, `share/completion/_normelog.zsh`

**Issue**: No test or verification that completions work correctly

**Impact**: Low - Completions might be broken

**Solution**: Test manually or add to documentation

---

### 16. **Man Page Date Is Incorrect**

**File**: `share/man/normelog.1:1`

**Issue**: Man page shows "October 2025" which is in the future (assuming current date is before that).

**Impact**: Low - Cosmetic issue

**Solution**: Update to correct date or use script generation date

---

### 17. **No Version Check Between Binary and Man Page**

**File**: `lib/version.sh`, `share/man/normelog.1:1`

**Issue**: Version is hardcoded in two places and can get out of sync.

**Impact**: Low - Documentation might show wrong version

**Solution**: Generate man page from source with correct version

---

### 18. **Missing Shellcheck Directives**

**File**: Multiple files

**Issue**: Several files have shellcheck warnings that should be addressed or suppressed with directives.

**Impact**: Low - Code quality

**Solution**: Run shellcheck and fix or suppress warnings appropriately

---

## Documentation Errors

### 19. **README Example Has Wrong GitHub URL**

**File**: `README.md:57, 523`

**Issue**: Examples use `https://github.com/yourusername/normelog.git` which is a placeholder.

**Impact**: Low - Users can't clone from examples

**Solution**: Replace with actual repository URL or generic instructions

---

### 20. **CLAUDE.md Reference to Old Structure**

**File**: `CLAUDE.md` (if it mentions old paths)

**Issue**: After restructuring, some paths might be outdated.

**Impact**: Low - Confusing for AI assistants

**Solution**: Verify all paths are current

---

## Summary

**Total Issues Found**: 20

- **Critical**: 5
- **Medium**: 5
- **Low**: 8
- **Documentation**: 2

### Most Critical Issues to Fix First:

1. Fix AWK variable bug in JSON formatter (Error #3)
2. Implement case-insensitive substring matching (Errors #4, #5)
3. Fix `-a` flag implementation (Error #2)
4. Fix debug output to stderr (Error #7)
5. Move `set -euo pipefail` to main script (Error #1)
