#!/usr/bin/env bash
# Convert norminette output to simple records
# Format:
# FILE <path> STATUS <OK|ERR>
# ERR <type> <line> <col> <message>

nl_parse_output() {
	awk '
		/^[^ \t].*\.(c|h):[ \t]*(OK!|Error!)/ {
		file=$0; sub(/:.*/, "", file);
		status=($0 ~ /OK!/) ? "OK" : "ERR";
		print "FILE", file, "STATUS", status; next;
		}
		/^Error:/ {
		match($0, /^Error:[ \t]*([A-Z_]+).*line:[ \t]*([0-9]+).*col:[ \t]*([0-9]+)/, m);
		type=m[1]; line=m[2]; col=m[3];
		msg=$0; sub(/^Error:[ \t]*[A-Z_]+[ \t]*\([^)]*\):[ \t]*/, "", msg);
		print "ERR", type, line, col, msg;
	}'
}
