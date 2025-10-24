#!/usr/bin/env bash
nl_exclude_filter() {
	local current_file="" exclude_current=0 line
	while IFS= read -r line; do
		if [[ "$line" =~ ^[^[:space:]]+\.(c|h):[[:space:]]*(OK!|Error!) ]]; then
			current_file=${line%%:*}
			exclude_current=0
			for ex in "${NL_EXCLUDE_DIRS[@]:-}"; do ex=${ex%/}; [[ "$current_file" == "$ex" || "$current_file" == $ex/* ]] && { exclude_current=1; break; }; done
			(( exclude_current == 0 )) && printf '%s\n' "$line"
		elif [[ "$line" =~ ^Error:[[:space:]] ]] && (( exclude_current == 0 )); then
			printf '%s\n' "$line"
		fi
	done
}

