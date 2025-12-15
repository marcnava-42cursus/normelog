#!/usr/bin/env bash
# Diff mode: Compare two norminette runs

nl_diff_compare() {
	local baseline_file="$1"
	local current_json="$2"

	if [[ ! -f "$baseline_file" ]]; then
		nl_log_error "Baseline file not found: $baseline_file"
		return 1
	fi

	if ! command -v python3 >/dev/null 2>&1; then
		nl_log_error "Diff mode requires python3 to parse JSON baselines"
		return 1
	fi

	python3 -c '
import json
import sys

baseline_path = sys.argv[1]
current_raw = sys.stdin.read()

try:
    with open(baseline_path, "r", encoding="utf-8") as f:
        baseline = json.load(f)
except Exception as exc:
    print(f"Error: failed to read baseline JSON: {exc}", file=sys.stderr)
    sys.exit(1)

try:
    current = json.loads(current_raw)
except Exception as exc:
    print(f"Error: failed to parse current JSON: {exc}", file=sys.stderr)
    sys.exit(1)


def extract_errors(obj):
    out = {}
    for file_obj in obj.get("files", []):
        file_name = file_obj.get("file", "")
        for err in file_obj.get("errors", []):
            err_type = err.get("type", "")
            line = err.get("line", "")
            col = err.get("col", "")
            msg = err.get("message", "")
            key = f"{file_name}:{line}:{col}:{err_type}"
            out[key] = msg
    return out


baseline_errors = extract_errors(baseline)
current_errors = extract_errors(current)

fixed_keys = sorted(k for k in baseline_errors if k not in current_errors)
new_keys = sorted(k for k in current_errors if k not in baseline_errors)
unchanged = sum(1 for k in baseline_errors if k in current_errors)

print("=== Norminette Diff Results ===")
print()
print(f"✅ Fixed:     {len(fixed_keys)} error(s)")
print(f"❌ New:       {len(new_keys)} error(s)")
print(f"➡️  Unchanged: {unchanged} error(s)")
print()

if fixed_keys:
    print("Fixed Errors:")
    for k in fixed_keys:
        file_name, line, col, err_type = k.rsplit(":", 3)
        msg = baseline_errors.get(k, "")
        print(f"  - {file_name}:{line}:{col} [{err_type}] {msg}")
    print()

if new_keys:
    print("New Errors:")
    for k in new_keys:
        file_name, line, col, err_type = k.rsplit(":", 3)
        msg = current_errors.get(k, "")
        print(f"  - {file_name}:{line}:{col} [{err_type}] {msg}")
    print()

sys.exit(1 if len(new_keys) > len(fixed_keys) else 0)
' "$baseline_file" <<<"$current_json"
}

nl_diff_save_baseline() {
	local output_file="$1"
	local json_output="$2"

	echo "$json_output" > "$output_file"
	nl_log_info "Baseline saved to: $output_file"
}
