#!/usr/bin/env bash
# SARIF (Static Analysis Results Interchange Format) output formatter for normelog
# Compatible with GitHub Code Scanning, Visual Studio, and other SARIF consumers

nl_format_sarif() {
	local filtered="$1"
	local stats="$2"

	# Extract statistics
	local total_errors=0
	while IFS= read -r line; do
		if [[ $line =~ ^TOTAL_ERRORS\ (.+)$ ]]; then
			total_errors="${BASH_REMATCH[1]}"
		fi
	done <<<"$stats"

	# Get unique error types for rules
	local error_types
	error_types=$(echo "$stats" | awk '/^TYPE / {print $2}' | sort -u)

	# Generate SARIF JSON
	cat <<SARIF_HEADER
{
	"\$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
	"version": "2.1.0",
	"runs": [
		{
			"tool": {
				"driver": {
					"name": "normelog",
					"informationUri": "https://github.com/marcnava-42cursus/normelog",
					"version": "${NL_VERSION}",
					"rules": [
SARIF_HEADER

	# Generate rules from error types
	local first_rule=1
	while IFS= read -r error_type; do
		[[ -z "$error_type" ]] && continue

		if [[ $first_rule -eq 0 ]]; then
			echo ","
		fi
		first_rule=0

		# Determine severity level
		local level="warning"
		case "$error_type" in
			FORBIDDEN_*|TOO_MANY_FUNCS|TOO_MANY_LINES|INVALID_HEADER)
				level="error"
				;;
			EMPTY_LINE_*|TRAILING_WHITESPACE|CONSECUTIVE_NEWLINES)
				level="note"
				;;
		esac

		cat <<EOF
						{
							"id": "$error_type",
							"name": "$error_type",
							"shortDescription": {
								"text": "Norminette error: $error_type"
							},
							"fullDescription": {
								"text": "42 School norminette detected a $error_type violation"
							},
							"defaultConfiguration": {
								"level": "$level"
							},
							"help": {
								"text": "See 42 School norm documentation for details"
							}
						}
EOF
	done <<<"$error_types"

	cat <<'SARIF_RULES_END'

					]
				}
			},
			"results": [
SARIF_RULES_END

	# Generate results from errors
	awk '
		BEGIN {
			first_result = 1
			current_file = ""
		}
		/^FILE / {
			current_file = $2
		}
		/^ERR / {
			if (first_result == 0) {
				print ","
			}
			first_result = 0

			type = $2
			line_num = $3
			col_num = $4
			message = substr($0, index($0, $5))

			# Escape JSON special characters
			file = current_file
			gsub(/\\/, "\\\\", file)
			gsub(/"/, "\\\"", file)
			gsub(/\n/, "\\n", file)
			gsub(/\r/, "\\r", file)
			gsub(/\t/, "\\t", file)

			gsub(/\\/, "\\\\", message)
			gsub(/"/, "\\\"", message)
			gsub(/\n/, "\\n", message)
			gsub(/\r/, "\\r", message)
			gsub(/\t/, "\\t", message)

			# Determine level based on error type
			level = "warning"
			if (match(type, /^FORBIDDEN_/) || type == "TOO_MANY_FUNCS" || type == "TOO_MANY_LINES" || type == "INVALID_HEADER") {
				level = "error"
			} else if (match(type, /^EMPTY_LINE_/) || type == "TRAILING_WHITESPACE" || type == "CONSECUTIVE_NEWLINES") {
				level = "note"
			}

			print "\t\t\t\t{"
			print "\t\t\t\t\t\"ruleId\": \"" type "\","
			print "\t\t\t\t\t\"level\": \"" level "\","
			print "\t\t\t\t\t\"message\": {"
			print "\t\t\t\t\t\t\"text\": \"" message "\""
			print "\t\t\t\t\t},"
			print "\t\t\t\t\t\"locations\": ["
			print "\t\t\t\t\t\t{"
			print "\t\t\t\t\t\t\t\"physicalLocation\": {"
			print "\t\t\t\t\t\t\t\t\"artifactLocation\": {"
			print "\t\t\t\t\t\t\t\t\t\"uri\": \"" file "\""
			print "\t\t\t\t\t\t\t\t},"
			print "\t\t\t\t\t\t\t\t\"region\": {"
			print "\t\t\t\t\t\t\t\t\t\"startLine\": " line_num ","
			print "\t\t\t\t\t\t\t\t\t\"startColumn\": " col_num
			print "\t\t\t\t\t\t\t\t}"
			print "\t\t\t\t\t\t\t}"
			print "\t\t\t\t\t\t}"
			print "\t\t\t\t\t]"
			print "\t\t\t\t}"
		}
	' <<<"$filtered"

	cat <<'SARIF_FOOTER'

			]
		}
	]
}
SARIF_FOOTER
}
