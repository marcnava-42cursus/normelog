# ERRORS.md

This document lists all errors, bugs, and issues found in the normelog codebase during analysis.

**Note**: Errors that have been fixed are moved to FIXED.md

---

## Low Priority Issues

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

**Total Issues Remaining**: 6

- **Critical**: 0 (all fixed in Phase 1)
- **Medium**: 0 (all fixed in Phase 1)
- **Low**: 4
- **Documentation**: 2

### Issues Fixed in Phase 1 (v0.2.0):

All critical and medium priority errors have been fixed. See FIXED.md for details.

**Fixed Issues**:
1. ✅ Error #1 - Environment Setup Issue
2. ✅ Error #2 - Missing Output Mode in `-a` Flag
3. ✅ Error #3 - AWK Variable References Bug in JSON Formatter
4. ✅ Error #4 - Case-Insensitive Filtering Not Implemented
5. ✅ Error #5 - Substring Matching Not Implemented
6. ✅ Error #6 - Incorrect Color Output Detection
7. ✅ Error #7 - Debug Messages Go to stdout Instead of stderr
8. ✅ Error #8 - Lint Script Has Wrong Paths
9. ✅ Error #9 - shfmt Configuration Mismatch
10. ✅ Error #10 - Missing Error Handling for Empty norminette Output

### Issues Fixed in Phase 2 (v0.3.0):

**Fixed Issues**:
11. ✅ Error #11 - Unused NL_SHOW_ALL_DETAILS Variable (Already fixed in Phase 1)
12. ✅ Error #12 - Plugin System Not Implemented
14. ✅ Error #14 - JSON Escaping Bug (Already fixed in Phase 1)
17. ✅ Error #17 - No Version Check Between Binary and Man Page

---
