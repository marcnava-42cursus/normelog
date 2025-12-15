#!/usr/bin/env bash
nl_format_text() {
	local records="$1" stats="$2" severity_stats="${3:-}"
	local green="" red="" yellow="" cyan="" reset=""
	if [[ "${NL_COLOR:-1}" -eq 1 ]]; then
		green=$'\033[32m'
		red=$'\033[31m'
		yellow=$'\033[33m'
		cyan=$'\033[36m'
		reset=$'\033[0m'
	fi

	echo "$stats" | awk -v green="$green" -v red="$red" -v reset="$reset" '
	/^OK_FILES/ {ok=$2}
	/^ERR_FILES/ {er=$2}
	END { printf "%sCorrect files: %d%s\n%sIncorrect files: %d%s\n\n", green, ok, reset, red, er, reset }
	'

	# Show severity breakdown if available
	if [[ -n "$severity_stats" ]]; then
		echo "Error severity:"
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
	echo "$stats" | awk '/^TYPE /{ printf "%-25s: %d\n", $2, $3 }'
	echo ""

	# Only show details if -a flag is set or if filtering by type
	if [[ "${NL_SHOW_ALL_DETAILS:-0}" -eq 1 ]] || [[ -n "${NL_INCLUDE_TYPES[*]-}" ]]; then
		echo "$records" | awk '
		/^FILE /{file=$2}
		/^ERR /{printf "%s\n    %s (line: %3s, col: %3s): %s\n", file, $2, $3, $4, substr($0, index($0,$5))}
		'
	fi
}
