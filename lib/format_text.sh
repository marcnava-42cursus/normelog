#!/usr/bin/env bash
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
	if [[ "${NL_SHOW_ALL_DETAILS:-0}" -eq 1 ]] || [[ ${#NL_INCLUDE_TYPES[@]} -gt 0 ]]; then
		echo "$records" | awk '
		/^FILE /{file=$2}
		/^ERR /{printf "%s\n    %s (line: %3s, col: %3s): %s\n", file, $2, $3, $4, substr($0, index($0,$5))}
		'
	fi
}
