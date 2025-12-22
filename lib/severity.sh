#!/usr/bin/env bash
# lib/severity.sh - Error severity classification

# Default severity levels for norminette errors
# Can be overridden in config files

# CRITICAL: Compilation blockers, forbidden elements
declare -A NL_SEVERITY_CRITICAL=(
	[FORBIDDEN_CS]=1
	[FORBIDDEN_CHAR_NAME]=1
	[FORBIDDEN_FUNC_NAME]=1
	[FORBIDDEN_VAR_NAME]=1
	[FORBIDDEN_TYPE_NAME]=1
	[FORBIDDEN_MACRO_NAME]=1
	[ASSIGN_IN_CONTROL]=1
	[TOO_MANY_LINES]=1
	[TOO_MANY_ARGS]=1
)

# WARNING: Code quality, style violations
declare -A NL_SEVERITY_WARNING=(
	[LINE_TOO_LONG]=1
	[WRONG_SCOPE]=1
	[WRONG_SCOPE_VAR]=1
	[WRONG_SCOPE_COMMENT]=1
	[MULT_DECL]=1
	[DECL_ASSIGN_LINE]=1
	[TOO_MANY_FUNCS]=1
	[BRACE_NEWLINE]=1
	[INVALID_HEADER]=1
)

# INFO: Minor formatting issues
declare -A NL_SEVERITY_INFO=(
	[SPACE_BEFORE_TAB]=1
	[SPACE_REPLACE_TAB]=1
	[TAB_REPLACE_SPACE]=1
	[EMPTY_LINE_FUNCTION]=1
	[EMPTY_LINE_FILE]=1
	[CONSECUTIVE_NEWLINES]=1
	[SPACE_EMPTY_LINE]=1
	[TRAILING_WHITESPACE]=1
	[NEWLINE_EOF]=1
	[NO_ARGS_VOID]=1
)

# Get severity level for an error type
nl_severity_get() {
	local error_type="$1"

	if [[ -n "${NL_SEVERITY_CRITICAL[$error_type]}" ]]; then
		echo "CRITICAL"
	elif [[ -n "${NL_SEVERITY_WARNING[$error_type]}" ]]; then
		echo "WARNING"
	elif [[ -n "${NL_SEVERITY_INFO[$error_type]}" ]]; then
		echo "INFO"
	else
		# Unknown errors default to WARNING
		echo "WARNING"
	fi
}

# Filter errors by severity level
nl_severity_filter() {
	local min_severity="${NL_MIN_SEVERITY:-INFO}"
	local only_severity="${NL_ONLY_SEVERITY:-}"

	# Severity order: INFO < WARNING < CRITICAL
	local include_info=0
	local include_warning=0
	local include_critical=0

	if [[ -n "$only_severity" ]]; then
		case "$only_severity" in
			INFO) include_info=1 ;;
			WARNING) include_warning=1 ;;
			CRITICAL) include_critical=1 ;;
			*)
				nl_log_error "Invalid severity level: $only_severity"
				return 1
				;;
		esac
	else
		case "$min_severity" in
			INFO)
				include_info=1
				include_warning=1
				include_critical=1
				;;
			WARNING)
				include_warning=1
				include_critical=1
				;;
			CRITICAL)
				include_critical=1
				;;
			*)
				nl_log_error "Invalid severity level: $min_severity"
				return 1
				;;
		esac
	fi

	awk -v inc_info="$include_info" \
	    -v inc_warn="$include_warning" \
	    -v inc_crit="$include_critical" '
	BEGIN {
		# Initialize severity maps
		# CRITICAL
		crit["FORBIDDEN_CS"] = 1
		crit["FORBIDDEN_CHAR_NAME"] = 1
		crit["FORBIDDEN_FUNC_NAME"] = 1
		crit["FORBIDDEN_VAR_NAME"] = 1
		crit["FORBIDDEN_TYPE_NAME"] = 1
		crit["FORBIDDEN_MACRO_NAME"] = 1
		crit["ASSIGN_IN_CONTROL"] = 1
		crit["TOO_MANY_LINES"] = 1
		crit["TOO_MANY_ARGS"] = 1

		# WARNING
		warn["LINE_TOO_LONG"] = 1
		warn["WRONG_SCOPE"] = 1
		warn["WRONG_SCOPE_VAR"] = 1
		warn["WRONG_SCOPE_COMMENT"] = 1
		warn["MULT_DECL"] = 1
		warn["DECL_ASSIGN_LINE"] = 1
		warn["TOO_MANY_FUNCS"] = 1
		warn["BRACE_NEWLINE"] = 1
		warn["INVALID_HEADER"] = 1

		# INFO
		info["SPACE_BEFORE_TAB"] = 1
		info["SPACE_REPLACE_TAB"] = 1
		info["TAB_REPLACE_SPACE"] = 1
		info["EMPTY_LINE_FUNCTION"] = 1
		info["EMPTY_LINE_FILE"] = 1
		info["CONSECUTIVE_NEWLINES"] = 1
		info["SPACE_EMPTY_LINE"] = 1
		info["TRAILING_WHITESPACE"] = 1
		info["NEWLINE_EOF"] = 1
		info["NO_ARGS_VOID"] = 1
	}

	# Always pass FILE records
	/^FILE / {
		print
		next
	}

	# Filter ERR records by severity
	/^ERR / {
		type = $2

		if (crit[type] && inc_crit) {
			print
		} else if (warn[type] && inc_warn) {
			print
		} else if (info[type] && inc_info) {
			print
		} else if (!crit[type] && !warn[type] && !info[type] && inc_warn) {
			# Unknown errors default to WARNING
			print
		}
	}
	'
}

# Compute severity-based statistics
nl_severity_stats() {
	awk '
	BEGIN {
		critical = 0
		warning = 0
		info = 0
		unknown = 0

		# Initialize severity maps
		# CRITICAL
		crit["FORBIDDEN_CS"] = 1
		crit["FORBIDDEN_CHAR_NAME"] = 1
		crit["FORBIDDEN_FUNC_NAME"] = 1
		crit["FORBIDDEN_VAR_NAME"] = 1
		crit["FORBIDDEN_TYPE_NAME"] = 1
		crit["FORBIDDEN_MACRO_NAME"] = 1
		crit["ASSIGN_IN_CONTROL"] = 1
		crit["TOO_MANY_LINES"] = 1
		crit["TOO_MANY_ARGS"] = 1

		# WARNING
		warn["LINE_TOO_LONG"] = 1
		warn["WRONG_SCOPE"] = 1
		warn["WRONG_SCOPE_VAR"] = 1
		warn["WRONG_SCOPE_COMMENT"] = 1
		warn["MULT_DECL"] = 1
		warn["DECL_ASSIGN_LINE"] = 1
		warn["TOO_MANY_FUNCS"] = 1
		warn["BRACE_NEWLINE"] = 1
		warn["INVALID_HEADER"] = 1

		# INFO
		info_map["SPACE_BEFORE_TAB"] = 1
		info_map["SPACE_REPLACE_TAB"] = 1
		info_map["TAB_REPLACE_SPACE"] = 1
		info_map["EMPTY_LINE_FUNCTION"] = 1
		info_map["EMPTY_LINE_FILE"] = 1
		info_map["CONSECUTIVE_NEWLINES"] = 1
		info_map["SPACE_EMPTY_LINE"] = 1
		info_map["TRAILING_WHITESPACE"] = 1
		info_map["NEWLINE_EOF"] = 1
		info_map["NO_ARGS_VOID"] = 1
	}

	/^ERR / {
		type = $2

		if (crit[type]) {
			critical++
		} else if (warn[type]) {
			warning++
		} else if (info_map[type]) {
			info++
		} else {
			# Unknown errors default to WARNING
			warning++
		}
	}

	END {
		print "SEVERITY_CRITICAL " critical
		print "SEVERITY_WARNING " warning
		print "SEVERITY_INFO " info
	}
	'
}
