#!/usr/bin/env bash
nl_exclude_filter() {
	local current_file="" line cleaned buffer=""
	local cwd="${PWD}"

	should_exclude() {
		local file="$1" ex file_clean file_abs
		file_clean="${file#./}"
		file_abs="$file_clean"
		if [[ "$file_abs" != /* ]]; then
			file_abs="$cwd/$file_abs"
		fi
		for ex in "${NL_EXCLUDE_DIRS[@]:-}"; do
			ex="${ex%/}"
			ex="${ex#./}"
			[[ -z "$ex" ]] && continue
			if [[ "$ex" == /* ]]; then
				if [[ "$file_abs" == "$ex" || "$file_abs" == "$ex/"* ]]; then
					return 0
				fi
			elif [[ "$ex" == */* ]]; then
				if [[ "$file_clean" == "$ex" || "$file_clean" == "$ex/"* ]]; then
					return 0
				fi
			else
				if [[ "/$file_clean/" == *"/$ex/"* ]]; then
					return 0
				fi
			fi
		done
		return 1
	}

	flush_buffer() {
		if [[ -z "$buffer" ]]; then
			current_file=""
			return
		fi
		if [[ -z "$current_file" ]] || ! should_exclude "$current_file"; then
			printf '%s' "$buffer"
		fi
		buffer=""
		current_file=""
	}

	while IFS= read -r line; do
		cleaned="$line"
		if [[ "$cleaned" == *$'\033'* ]]; then
			cleaned=$(printf '%s' "$line" | sed -E 's/\x1B\[[0-9;]*m//g')
		fi
		if [[ "$cleaned" =~ ^[^[:space:]]+\.(c|h):[[:space:]]*(OK!|KO!|Error!) ]]; then
			if [[ -z "$current_file" ]]; then
				current_file=${cleaned%%:*}
			fi
			buffer+="$line"$'\n'
			flush_buffer
			continue
		fi
		if [[ "$cleaned" =~ ^[^[:space:]]+\.(c|h)$ ]]; then
			if [[ -n "$buffer" && -n "$current_file" ]]; then
				flush_buffer
			fi
			current_file="$cleaned"
			buffer+="$line"$'\n'
			continue
		fi
		if [[ "$cleaned" =~ ^Error:[[:space:]] ]]; then
			buffer+="$line"$'\n'
			continue
		fi
		if [[ -n "$buffer" || -n "$current_file" ]]; then
			buffer+="$line"$'\n'
		else
			printf '%s\n' "$line"
		fi
	done
	flush_buffer
}
