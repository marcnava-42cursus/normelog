#!/usr/bin/env bash
nl_format_text() {
	local records="$1" stats="$2" severity_stats="${3:-}"
	local green="" red="" yellow="" cyan="" reset="" bold=""
	if [[ "${NL_COLOR:-1}" -eq 1 ]]; then
		green=$'\033[32m'
		red=$'\033[31m'
		yellow=$'\033[33m'
		cyan=$'\033[36m'
		reset=$'\033[0m'
		bold=$'\033[1m'
	fi

	echo "$stats" | awk -v green="$green" -v red="$red" -v reset="$reset" -v bold="$bold" '
	/^OK_FILES/ {ok=$2}
	/^ERR_FILES/ {er=$2}
	END {
		printf "%sFiles: %d%s\n", bold, ok+er, reset
		printf "--------------------\n"
		printf "%sCorrect:   %d%s\n%sIncorrect: %d%s\n\n", green, ok, reset, red, er, reset
	}
	'

	local total_errors
	total_errors=$(echo "$stats" | awk '/^TOTAL_ERRORS/ {print $2}')

	# Show severity breakdown if available
	if [[ -n "$severity_stats" ]]; then
		echo "${bold}Errors: ${total_errors}${reset}"
		echo "--------------------"
		echo "$severity_stats" | awk -v red="$red" -v yellow="$yellow" -v cyan="$cyan" -v reset="$reset" '
		/^SEVERITY_CRITICAL/ { printf "%sCritical: %d%s\n", red, $2, reset }
		/^SEVERITY_WARNING/ { printf "%sWarning:  %d%s\n", yellow, $2, reset }
		/^SEVERITY_INFO/ { printf "%sInfo:     %d%s\n", cyan, $2, reset }
		'
		echo ""
	fi

	echo "Error type count:"
	echo "--------------------"

	local type_stats
	type_stats=$(echo "$stats" | grep "^TYPE") || true

	if [[ -n "${NL_ORDER:-}" ]]; then
		if [[ "$NL_ORDER" == "asc" ]]; then
			type_stats=$(echo "$type_stats" | sort -k3,3n -k2,2)
		elif [[ "$NL_ORDER" == "desc" ]]; then
			type_stats=$(echo "$type_stats" | sort -k3,3nr -k2,2)
		fi
	fi

	echo "$type_stats" | awk -v red="$red" -v yellow="$yellow" -v cyan="$cyan" -v reset="$reset" '
		BEGIN {
			# Initialize severity maps (sync with lib/severity.sh)
			crit["FORBIDDEN_CS"] = 1; crit["FORBIDDEN_CHAR_NAME"] = 1
			crit["FORBIDDEN_FUNC_NAME"] = 1; crit["FORBIDDEN_VAR_NAME"] = 1
			crit["FORBIDDEN_TYPE_NAME"] = 1; crit["FORBIDDEN_MACRO_NAME"] = 1
			crit["ASSIGN_IN_CONTROL"] = 1; crit["TOO_MANY_LINES"] = 1
			crit["TOO_MANY_ARGS"] = 1
			crit["TERNARY_FBIDDEN"] = 1; crit["TOO_MANY_VARS_FUNC"] = 1
			crit["TOO_MANY_FUNCS"] = 1

			warn["LINE_TOO_LONG"] = 1
			warn["WRONG_SCOPE"] = 1; warn["WRONG_SCOPE_VAR"] = 1
			warn["MULT_DECL"] = 1; warn["DECL_ASSIGN_LINE"] = 1
			warn["BRACE_NEWLINE"] = 1; warn["INVALID_HEADER"] = 1

			info["SPACE_BEFORE_TAB"] = 1; info["SPACE_REPLACE_TAB"] = 1
			info["TAB_REPLACE_SPACE"] = 1; info["EMPTY_LINE_FUNCTION"] = 1
			info["EMPTY_LINE_FILE"] = 1; info["CONSECUTIVE_NEWLINES"] = 1
			info["SPACE_EMPTY_LINE"] = 1; info["TRAILING_WHITESPACE"] = 1
			info["NEWLINE_EOF"] = 1; info["NO_ARGS_VOID"] = 1
			info["WRONG_SCOPE_COMMENT"] = 1; info["MISSALIGNED_VAR_DECL"] = 1
			info["TOO_MANY_TAB"] = 1; info["TOO_FEW_TAB"] = 1
			info["SPC_AFTER_OPERATOR"] = 1; info["SPC_BFR_OPERATOR"] = 1
			info["SPACE_AFTER_KW"] = 1; info["CONSECUTIVE_SPC"] = 1
			info["EOL_OPERATOR"] = 1; info["TOO_MANY_WS"] = 1
			info["MIXED_SPACE_TAB"] = 1; info["SPACE_BEFORE_FUNC"] = 1
			info["NO_SPC_AFR_PAR"] = 1; info["NL_AFTER_PREPROC"] = 1
			info["SPACE_AFTER_POINTER"] = 1; info["SPC_BEFORE_NL"] = 1
			info["TAB_INSTEAD_NL"] = 1
		}
		/^TYPE /{
			type = $2
			color = yellow # Default
			if (crit[type]) color = red
			else if (info[type]) color = cyan
			printf "%s%-25s%s: %d\n", color, type, reset, $3
		}
	'
	echo ""

	# Only show details if -a flag is set or if filtering by type
	if [[ "${NL_SHOW_ALL_DETAILS:-0}" -eq 1 ]] || [[ -n "${NL_INCLUDE_TYPES[*]-}" ]]; then
		echo "$records" | awk -v red="$red" -v yellow="$yellow" -v cyan="$cyan" -v reset="$reset" '
		BEGIN {
			# Initialize severity maps (sync with lib/severity.sh)
			crit["FORBIDDEN_CS"] = 1; crit["FORBIDDEN_CHAR_NAME"] = 1
			crit["FORBIDDEN_FUNC_NAME"] = 1; crit["FORBIDDEN_VAR_NAME"] = 1
			crit["FORBIDDEN_TYPE_NAME"] = 1; crit["FORBIDDEN_MACRO_NAME"] = 1
			crit["ASSIGN_IN_CONTROL"] = 1; crit["TOO_MANY_LINES"] = 1
			crit["TOO_MANY_ARGS"] = 1
			crit["TERNARY_FBIDDEN"] = 1; crit["TOO_MANY_VARS_FUNC"] = 1
			crit["TOO_MANY_FUNCS"] = 1

			warn["LINE_TOO_LONG"] = 1
			warn["WRONG_SCOPE"] = 1; warn["WRONG_SCOPE_VAR"] = 1
			warn["MULT_DECL"] = 1; warn["DECL_ASSIGN_LINE"] = 1
			warn["BRACE_NEWLINE"] = 1; warn["INVALID_HEADER"] = 1

			info["SPACE_BEFORE_TAB"] = 1; info["SPACE_REPLACE_TAB"] = 1
			info["TAB_REPLACE_SPACE"] = 1; info["EMPTY_LINE_FUNCTION"] = 1
			info["EMPTY_LINE_FILE"] = 1; info["CONSECUTIVE_NEWLINES"] = 1
			info["SPACE_EMPTY_LINE"] = 1; info["TRAILING_WHITESPACE"] = 1
			info["NEWLINE_EOF"] = 1; info["NO_ARGS_VOID"] = 1
			info["WRONG_SCOPE_COMMENT"] = 1; info["MISSALIGNED_VAR_DECL"] = 1
			info["TOO_MANY_TAB"] = 1; info["TOO_FEW_TAB"] = 1
			info["SPC_AFTER_OPERATOR"] = 1; info["SPC_BFR_OPERATOR"] = 1
			info["SPACE_AFTER_KW"] = 1; info["CONSECUTIVE_SPC"] = 1
			info["EOL_OPERATOR"] = 1; info["TOO_MANY_WS"] = 1
			info["MIXED_SPACE_TAB"] = 1; info["SPACE_BEFORE_FUNC"] = 1
			info["NO_SPC_AFR_PAR"] = 1; info["NL_AFTER_PREPROC"] = 1
			info["SPACE_AFTER_POINTER"] = 1; info["SPC_BEFORE_NL"] = 1
			info["TAB_INSTEAD_NL"] = 1
		}
		/^FILE /{
			file=$2
			header_printed=0
		}
		/^ERR /{
			if (header_printed == 0) {
				printf "%s\n", file
				header_printed = 1
			}
			type = $2
			color = yellow # Default
			if (crit[type]) color = red
			else if (info[type]) color = cyan

			printf "    %s%s (line: %3s, col: %3s): %s%s\n", color, $2, $3, $4, substr($0, index($0,$5)), reset
		}
		'
	fi
}
