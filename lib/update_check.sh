#!/usr/bin/env bash

# Check for updates from GitHub releases
# Respects NL_AUTO_UPDATE_CHECK environment variable (default: 1)
# Caches check results for 24 hours to avoid excessive API calls

nl_update_check() {
  # Allow disabling automatic update checks
  if [[ "${NL_AUTO_UPDATE_CHECK:-1}" -eq 0 ]]; then
    nl_log_debug "Automatic update check disabled"
    return 0
  fi

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/normelog"
  local cache_file="$cache_dir/last_check"
  local cache_age=86400  # 24 hours in seconds

  # Create cache directory if it doesn't exist
  mkdir -p "$cache_dir" 2>/dev/null || return 0

  # Check cache freshness
  if [[ -f "$cache_file" ]]; then
    local last_check
    last_check=$(cat "$cache_file" 2>/dev/null || echo "0")
    local now
    now=$(date +%s)
    local age=$((now - last_check))

    if [[ $age -lt $cache_age ]]; then
      nl_log_debug "Update check cached (checked ${age}s ago)"
      return 0
    fi
  fi

  nl_log_debug "Checking for updates..."

  # Fetch latest version from GitHub API
  local api_url="https://api.github.com/repos/marcnava-42cursus/normelog/releases/latest"
  local latest

  # Use curl if available, otherwise skip check
  if ! command -v curl >/dev/null 2>&1; then
    nl_log_debug "curl not found, skipping update check"
    return 0
  fi

  # Fetch with timeout and error handling
  latest=$(curl -sL --max-time 5 "$api_url" 2>/dev/null | \
    grep '"tag_name"' | \
    sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v?([^"]+)".*/\1/' | \
    head -n1)

  # Check if we got a valid response
  if [[ -z "$latest" ]]; then
    nl_log_debug "Could not fetch latest version from GitHub"
    return 0
  fi

  # Remove 'v' prefix if present for comparison
  latest="${latest#v}"
  local current="${NL_VERSION#v}"

  # Compare versions
  if [[ "$latest" != "$current" ]]; then
    # Simple version comparison (works for semantic versioning)
    if [[ "$latest" > "$current" ]] || [[ "$latest" == "$current."* ]]; then
      nl_log_info "New version available: v$latest (current: v$current)"
      nl_log_info "Run 'normelog --update' to upgrade"
    fi
  else
    nl_log_debug "normelog is up to date (v$current)"
  fi

  # Update cache timestamp
  date +%s > "$cache_file" 2>/dev/null || true
}
