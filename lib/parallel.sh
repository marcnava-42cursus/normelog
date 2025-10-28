#!/usr/bin/env bash
# Parallel execution support

nl_parallel_detect_tool() {
	# Detect available parallelization tool
	if command -v parallel >/dev/null 2>&1; then
		echo "parallel"
	elif command -v xargs >/dev/null 2>&1; then
		# Check if xargs supports -P flag
		if echo "test" | xargs -P 1 echo >/dev/null 2>&1; then
			echo "xargs"
		else
			echo "none"
		fi
	else
		echo "none"
	fi
}

nl_parallel_run_norminette() {
	local jobs="${NL_PARALLEL_JOBS:-4}"
	local tool
	tool=$(nl_parallel_detect_tool)

	if [[ "$tool" == "none" ]]; then
		nl_log_error "Parallel execution requires 'parallel' or 'xargs -P'"
		nl_log_error "Install GNU parallel: apt-get install parallel (or brew install parallel)"
		nl_log_error "Falling back to sequential execution..."
		return 1
	fi

	nl_log_debug "Using parallel tool: $tool with $jobs jobs"

	# Collect all files to check
	local files=()
	if [[ ${#NL_DIRS[@]} -gt 0 ]]; then
		# Files specified directly or via git
		for item in "${NL_DIRS[@]}"; do
			if [[ -f "$item" ]]; then
				files+=("$item")
			elif [[ -d "$item" ]]; then
				# Find C/H files in directory
				while IFS= read -r -d '' file; do
					files+=("$file")
				done < <(find "$item" -type f \( -name "*.c" -o -name "*.h" \) -print0)
			fi
		done
	else
		# Scan current directory
		while IFS= read -r -d '' file; do
			files+=("$file")
		done < <(find . -type f \( -name "*.c" -o -name "*.h" \) -print0)
	fi

	if [[ ${#files[@]} -eq 0 ]]; then
		nl_log_error "No C/H files found"
		return 1
	fi

	nl_log_debug "Found ${#files[@]} files to check"

	# Run norminette in parallel
	local tmpfile
	tmpfile=$(mktemp)

	if [[ "$tool" == "parallel" ]]; then
		# GNU parallel
		printf "%s\n" "${files[@]}" | \
			parallel -j "$jobs" --keep-order norminette -R CheckForbidenSourceHeader {} \
			> "$tmpfile" 2>&1 || true
	else
		# xargs -P
		printf "%s\n" "${files[@]}" | \
			xargs -P "$jobs" -I {} norminette -R CheckForbidenSourceHeader {} \
			> "$tmpfile" 2>&1 || true
	fi

	# Output results
	cat "$tmpfile"
	rm -f "$tmpfile"
}
