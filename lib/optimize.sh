#!/usr/bin/env bash
# Performance optimization utilities for normelog

# Cache directory for performance optimizations
NL_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/normelog"

# Initialize optimization cache
nl_optimize_init() {
	mkdir -p "$NL_CACHE_DIR"
}

# Get cache file path for a given key
nl_optimize_cache_path() {
	local key="$1"
	local hash
	hash=$(echo -n "$key" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "$key")
	echo "$NL_CACHE_DIR/$hash"
}

# Check if cached result is still valid
nl_optimize_cache_valid() {
	local cache_file="$1"
	local source_files="$2"  # Space-separated list of files to check
	local max_age="${3:-3600}"  # Default 1 hour

	[[ ! -f "$cache_file" ]] && return 1

	# Check age
	local cache_mtime
	cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)
	local now
	now=$(date +%s)
	local age=$((now - cache_mtime))

	if [[ $age -gt $max_age ]]; then
		nl_log_debug "Cache expired: $cache_file (age: ${age}s)"
		return 1
	fi

	# Check if source files have been modified
	for file in $source_files; do
		[[ ! -f "$file" ]] && continue
		local file_mtime
		file_mtime=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo 0)
		if [[ $file_mtime -gt $cache_mtime ]]; then
			nl_log_debug "Source file newer than cache: $file"
			return 1
		fi
	done

	nl_log_debug "Cache valid: $cache_file"
	return 0
}

# Optimized AWK field extraction (reduces pipe overhead)
nl_optimize_awk_extract() {
	# Use mawk if available (faster than gawk for simple operations)
	if command -v mawk >/dev/null 2>&1; then
		mawk "$@"
	else
		awk "$@"
	fi
}

# Batch file operations to reduce syscalls
nl_optimize_batch_stat() {
	local files=("$@")

	# Use stat once for all files
	if command -v stat >/dev/null 2>&1; then
		stat -c '%n %s %Y' "${files[@]}" 2>/dev/null || \
		stat -f '%N %z %m' "${files[@]}" 2>/dev/null
	fi
}

# Pre-compile frequently used regex patterns
declare -A NL_REGEX_CACHE

nl_optimize_regex_compile() {
	local pattern="$1"
	local name="$2"

	# Store pattern for reuse
	NL_REGEX_CACHE["$name"]="$pattern"
}

nl_optimize_regex_match() {
	local string="$1"
	local name="$2"

	local pattern="${NL_REGEX_CACHE[$name]}"
	[[ -z "$pattern" ]] && return 1

	[[ "$string" =~ $pattern ]]
}

# Memory-efficient line counting
nl_optimize_count_lines() {
	# Use wc -l which is faster than awk
	wc -l | awk '{print $1}'
}

# Fast duplicate removal (for error types, etc.)
nl_optimize_unique() {
	# Use sort -u which is faster than awk for large datasets
	sort -u
}

# Optimize repeated string operations
nl_optimize_string_cache() {
	local -n cache_ref=$1
	local key="$2"
	local value="$3"

	cache_ref["$key"]="$value"
}

# Clean old cache files
nl_optimize_cleanup_cache() {
	local max_age="${1:-604800}"  # Default 7 days

	[[ ! -d "$NL_CACHE_DIR" ]] && return 0

	find "$NL_CACHE_DIR" -type f -mtime "+$((max_age / 86400))" -delete 2>/dev/null || true
	nl_log_debug "Cleaned cache files older than $max_age seconds"
}

# Benchmark a command
nl_optimize_benchmark() {
	local label="$1"
	shift

	if [[ "${NL_DEBUG:-0}" -eq 1 ]]; then
		local start
		start=$(date +%s%N 2>/dev/null || date +%s)
		"$@"
		local end
		end=$(date +%s%N 2>/dev/null || date +%s)
		local duration=$((end - start))

		# Convert to milliseconds if we have nanoseconds
		if [[ ${#duration} -gt 10 ]]; then
			duration=$((duration / 1000000))
			nl_log_debug "Benchmark [$label]: ${duration}ms"
		else
			nl_log_debug "Benchmark [$label]: ${duration}s"
		fi
	else
		"$@"
	fi
}
