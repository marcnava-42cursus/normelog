#!/usr/bin/env bash
# Convert norminette output to simple records
# Format:
# FILE <path> STATUS <OK|ERR>
# ERR <type> <line> <col> <message>

nl_parse_output() {
	awk '
		{
			line = $0
			# Strip ANSI color codes from norminette output (e.g., \033[97m...\033[0m)
			gsub(/\033\[[0-9;]*m/, "", line)

			if (line ~ /^[^ \t].*\.(c|h):[ \t]*(OK!|Error!)/) {
				file = line
				sub(/:.*/, "", file)
				status = (line ~ /OK!/) ? "OK" : "ERR"
				print "FILE", file, "STATUS", status
				next
			}

			if (line ~ /^Error:/) {
				match(line, /^Error:[ \t]*([A-Z_]+).*line:[ \t]*([0-9]+).*col:[ \t]*([0-9]+)/, m)
				type = m[1]
				line_no = m[2]
				col = m[3]
				msg = line
				sub(/^Error:[ \t]*[A-Z_]+[ \t]*\([^)]*\):[ \t]*/, "", msg)
				print "ERR", type, line_no, col, msg
				next
			}
		}
	'
}
