#!/usr/bin/env bash
# JUnit XML output formatter for normelog
# Compatible with Jenkins, GitLab CI, and other CI/CD systems

nl_format_junit() {
	local filtered="$1"
	local stats="$2"

	# Extract statistics
	local ok_files=0
	local err_files=0
	local total_errors=0

	while IFS= read -r line; do
		if [[ $line =~ ^OK_FILES\ (.+)$ ]]; then
			ok_files="${BASH_REMATCH[1]}"
		elif [[ $line =~ ^ERR_FILES\ (.+)$ ]]; then
			err_files="${BASH_REMATCH[1]}"
		elif [[ $line =~ ^TOTAL_ERRORS\ (.+)$ ]]; then
			total_errors="${BASH_REMATCH[1]}"
		fi
	done <<<"$stats"

	local total_files=$((ok_files + err_files))
	local timestamp
	timestamp=$(date -u '+%Y-%m-%dT%H:%M:%S')

	# Generate JUnit XML
	cat <<XML_HEADER
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="normelog" tests="$total_files" failures="$err_files" errors="0" time="0">
	<testsuite name="norminette" tests="$total_files" failures="$err_files" errors="0" time="0" timestamp="$timestamp">
XML_HEADER

	# Process files and errors
	awk -v total_errors="$total_errors" '
		BEGIN {
			current_file = ""
			current_status = ""
			error_count = 0
			errors_text = ""
		}
		/^FILE / {
			# Output previous file if exists
			if (current_file != "") {
				print_testcase(current_file, current_status, errors_text)
			}
			current_file = $2
			current_status = $4
			error_count = 0
			errors_text = ""
		}
		/^ERR / {
			error_count++
			type = $2
			line = $3
			col = $4
			message = substr($0, index($0, $5))

			# Escape XML special characters
			gsub(/&/, "\\&amp;", message)
			gsub(/</, "\\&lt;", message)
			gsub(/>/, "\\&gt;", message)
			gsub(/"/, "\\&quot;", message)
			gsub(/'\''/, "\\&apos;", message)

			errors_text = errors_text sprintf("%s (line %s, col %s): %s\n", type, line, col, message)
		}
		END {
			# Output last file
			if (current_file != "") {
				print_testcase(current_file, current_status, errors_text)
			}
		}
		function print_testcase(file, status, errors) {
			# Escape XML in filename
			gsub(/&/, "\\&amp;", file)
			gsub(/</, "\\&lt;", file)
			gsub(/>/, "\\&gt;", file)
			gsub(/"/, "\\&quot;", file)

			if (status == "OK") {
				print "\t\t<testcase name=\"" file "\" classname=\"norminette\" time=\"0\"/>"
			} else {
				print "\t\t<testcase name=\"" file "\" classname=\"norminette\" time=\"0\">"
				print "\t\t\t<failure message=\"Norminette errors found\" type=\"NormError\">"
				gsub(/&/, "\\&amp;", errors)
				gsub(/</, "\\&lt;", errors)
				gsub(/>/, "\\&gt;", errors)
				print errors
				print "\t\t\t</failure>"
				print "\t\t</testcase>"
			}
		}
	' <<<"$filtered"

	cat <<'XML_FOOTER'
	</testsuite>
</testsuites>
XML_FOOTER
}
