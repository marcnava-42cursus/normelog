#!/usr/bin/env bash

# Apply updates from GitHub releases
# Downloads and installs the latest version

nl_update_apply() {
  nl_log_info "Checking for updates..."

  # Check for required tools
  if ! command -v curl >/dev/null 2>&1; then
    nl_log_error "curl is required for updates but not found in PATH"
    return 1
  fi

  # Fetch latest version from GitHub API
  local api_url="https://api.github.com/repos/marcnava-42cursus/normelog/releases/latest"
  local release_info

  release_info=$(curl -sL --max-time 10 "$api_url" 2>/dev/null)

  if [[ -z "$release_info" ]]; then
    nl_log_error "Could not fetch release information from GitHub"
    return 1
  fi

  # Extract version and download URL
  local latest
  latest=$(echo "$release_info" | \
    grep '"tag_name"' | \
    sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v?([^"]+)".*/\1/' | \
    head -n1)

  local tarball_url
  tarball_url=$(echo "$release_info" | \
    grep '"tarball_url"' | \
    sed -E 's/.*"tarball_url"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' | \
    head -n1)

  if [[ -z "$latest" ]] || [[ -z "$tarball_url" ]]; then
    nl_log_error "Could not parse release information"
    return 1
  fi

  # Remove 'v' prefix if present
  latest="${latest#v}"
  local current="${NL_VERSION#v}"

  # Check if already up to date
  if [[ "$latest" == "$current" ]]; then
    nl_log_info "Already on latest version: v$current"
    return 0
  fi

  nl_log_info "New version available: v$latest (current: v$current)"
  nl_log_info "Downloading from GitHub..."

  # Create temporary directory for download
  local tmp_dir
  tmp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'normelog-update')

  if [[ ! -d "$tmp_dir" ]]; then
    nl_log_error "Could not create temporary directory"
    return 1
  fi

  # Download tarball
  local tarball="$tmp_dir/normelog.tar.gz"
  if ! curl -sL --max-time 30 -o "$tarball" "$tarball_url"; then
    nl_log_error "Failed to download release"
    rm -rf "$tmp_dir"
    return 1
  fi

  nl_log_info "Extracting archive..."

  # Extract tarball
  local extract_dir="$tmp_dir/extract"
  mkdir -p "$extract_dir"

  if ! tar -xzf "$tarball" -C "$extract_dir" 2>/dev/null; then
    nl_log_error "Failed to extract archive"
    rm -rf "$tmp_dir"
    return 1
  fi

  # Find the extracted directory (GitHub tarballs extract to a single directory)
  local source_dir
  source_dir=$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n1)

  if [[ ! -d "$source_dir" ]]; then
    nl_log_error "Could not find extracted source directory"
    rm -rf "$tmp_dir"
    return 1
  fi

  nl_log_info "Installing normelog v$latest..."

  # Run make install from the extracted directory
  if ! (cd "$source_dir" && make install PREFIX="${PREFIX:-/usr/local}") >/dev/null 2>&1; then
    nl_log_error "Installation failed. You may need to run with sudo:"
    nl_log_error "  sudo normelog --update"
    rm -rf "$tmp_dir"
    return 1
  fi

  # Cleanup
  rm -rf "$tmp_dir"

  nl_log_info "Successfully updated to v$latest"
  nl_log_info "Restart your shell or run 'hash -r' to use the new version"

  return 0
}
