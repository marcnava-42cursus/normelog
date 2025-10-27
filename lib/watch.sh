#!/usr/bin/env bash
# lib/watch.sh - Watch mode for continuous monitoring

# Watch for file changes and re-run normelog
nl_watch_run() {
	# Check for inotifywait or fswatch
	local watcher=""
	if command -v inotifywait >/dev/null 2>&1; then
		watcher="inotifywait"
	elif command -v fswatch >/dev/null 2>&1; then
		watcher="fswatch"
	else
		nl_log_error "Watch mode requires either inotifywait or fswatch"
		nl_log_error "Install with: apt-get install inotify-tools (Debian/Ubuntu)"
		nl_log_error "         or: brew install fswatch (macOS)"
		return 1
	fi

	nl_log_info "Starting watch mode (press Ctrl+C to stop)..."
	nl_log_info "Using $watcher to monitor file changes"

	# Determine directories to watch
	local watch_dirs=()
	if [[ ${#NL_DIRS[@]} -gt 0 ]]; then
		watch_dirs=("${NL_DIRS[@]}")
	else
		watch_dirs=(".")
	fi

	# Initial run
	clear
	echo "=== Initial run at $(date '+%H:%M:%S') ==="
	nl_watch_exec_normelog

	# Watch loop
	if [[ "$watcher" == "inotifywait" ]]; then
		nl_watch_inotify "${watch_dirs[@]}"
	else
		nl_watch_fswatch "${watch_dirs[@]}"
	fi
}

# Execute normelog without watch mode
nl_watch_exec_normelog() {
	# Build command without --watch flag
	local cmd=("$0")
	local skip_next=0

	for arg in "${NL_ORIGINAL_ARGS[@]}"; do
		if [[ $skip_next -eq 1 ]]; then
			skip_next=0
			continue
		fi

		case "$arg" in
			--watch)
				continue
				;;
			*)
				cmd+=("$arg")
				;;
		esac
	done

	# Run normelog
	"${cmd[@]}" 2>&1 || true
}

# Watch using inotifywait
nl_watch_inotify() {
	local dirs=("$@")

	while true; do
		# Watch for modify, create, delete events on .c and .h files
		inotifywait -q -r -e modify,create,delete \
			--include '.*\.(c|h)$' \
			"${dirs[@]}" 2>/dev/null || break

		# Debounce: wait a bit for rapid changes to settle
		sleep 0.5

		# Clear screen and re-run
		clear
		echo "=== File changed at $(date '+%H:%M:%S') ==="
		nl_watch_exec_normelog
	done
}

# Watch using fswatch
nl_watch_fswatch() {
	local dirs=("$@")

	# Use fswatch with filter for .c and .h files
	fswatch -r -e '.*' -i '\.(c|h)$' "${dirs[@]}" | while read -r file; do
		# Debounce: wait a bit for rapid changes to settle
		sleep 0.5

		# Clear screen and re-run
		clear
		echo "=== File changed: $file at $(date '+%H:%M:%S') ==="
		nl_watch_exec_normelog
	done
}
