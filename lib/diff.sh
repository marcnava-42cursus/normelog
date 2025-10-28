#!/usr/bin/env bash
# Diff mode: Compare two norminette runs

nl_diff_compare() {
	local baseline_file="$1"
	local current_json="$2"

	if [[ ! -f "$baseline_file" ]]; then
		nl_log_error "Baseline file not found: $baseline_file"
		exit 1
	fi

	# Parse both JSON files and compare
	awk -v baseline_file="$baseline_file" -v current="$current_json" '
	BEGIN {
		# Read baseline JSON
		while ((getline line < baseline_file) > 0) {
			baseline = baseline line
		}
		close(baseline_file)

		# Parse baseline errors into array: file:line:col:type -> message
		parse_errors(baseline, baseline_errors)

		# Parse current errors
		parse_errors(current, current_errors)

		# Compare
		fixed = 0
		new_err = 0
		unchanged = 0

		# Find fixed errors (in baseline but not in current)
		for (key in baseline_errors) {
			if (!(key in current_errors)) {
				fixed++
				fixed_list[fixed] = key " | " baseline_errors[key]
			} else {
				unchanged++
			}
		}

		# Find new errors (in current but not in baseline)
		for (key in current_errors) {
			if (!(key in baseline_errors)) {
				new_err++
				new_list[new_err] = key " | " current_errors[key]
			}
		}

		# Output results
		print "=== Norminette Diff Results ==="
		print ""
		printf "✅ Fixed:     %d error(s)\n", fixed
		printf "❌ New:       %d error(s)\n", new_err
		printf "➡️  Unchanged: %d error(s)\n", unchanged
		print ""

		# Show details
		if (fixed > 0) {
			print "Fixed Errors:"
			for (i = 1; i <= fixed; i++) {
				split(fixed_list[i], parts, " | ")
				split(parts[1], loc, ":")
				printf "  - %s:%s:%s [%s] %s\n", loc[1], loc[2], loc[3], loc[4], parts[2]
			}
			print ""
		}

		if (new_err > 0) {
			print "New Errors:"
			for (i = 1; i <= new_err; i++) {
				split(new_list[i], parts, " | ")
				split(parts[1], loc, ":")
				printf "  - %s:%s:%s [%s] %s\n", loc[1], loc[2], loc[3], loc[4], parts[2]
			}
			print ""
		}

		# Exit code: 0 if improved or same, 1 if worse
		exit_code = (new_err > fixed) ? 1 : 0
		exit exit_code
	}

	function parse_errors(json, errors,    files_match, file, line, col, type, msg) {
		# Extract files array from JSON
		if (match(json, /"files": \[([^\]]+)\]/, files_match)) {
			files_str = files_match[1]

			# Split by file objects
			n = split(files_str, file_objs, /\}, \{/)
			for (i = 1; i <= n; i++) {
				obj = file_objs[i]

				# Extract file name
				if (match(obj, /"file": "([^"]+)"/, file_match)) {
					file = file_match[1]
				}

				# Extract errors array for this file
				if (match(obj, /"errors": \[([^\]]+)\]/, errors_match)) {
					errors_str = errors_match[1]

					# Split by error objects
					m = split(errors_str, err_objs, /\}, \{/)
					for (j = 1; j <= m; j++) {
						err = err_objs[j]

						# Extract error fields
						if (match(err, /"type":"([^"]+)"/, type_match)) type = type_match[1]
						if (match(err, /"line":([0-9]+)/, line_match)) line = line_match[1]
						if (match(err, /"col":([0-9]+)/, col_match)) col = col_match[1]
						if (match(err, /"message":"([^"]+)"/, msg_match)) {
							msg = msg_match[1]
							# Unescape JSON
							gsub(/\\"/, "\"", msg)
						}

						# Create unique key
						key = file ":" line ":" col ":" type
						errors[key] = msg
					}
				}
			}
		}
	}
	'
}

nl_diff_save_baseline() {
	local output_file="$1"
	local json_output="$2"

	echo "$json_output" > "$output_file"
	nl_log_info "Baseline saved to: $output_file"
}
