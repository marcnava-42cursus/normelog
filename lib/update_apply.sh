#!/usr/bin/env bash

# Apply updates from GitHub releases
# Downloads and installs the latest version

nl_update_get_install_prefix() {
  if [[ -n "${PREFIX:-}" ]]; then
    echo "$PREFIX"
    return 0
  fi

  # If running from an installed layout, LIB_DIR is typically: <prefix>/lib/normelog
  if [[ -n "${LIB_DIR:-}" ]] && [[ "$LIB_DIR" == */lib/normelog ]]; then
    echo "${LIB_DIR%/lib/normelog}"
    return 0
  fi

  # Fallback: if entrypoint resolved BASE_DIR and it looks like an install prefix
  if [[ -n "${BASE_DIR:-}" ]] && [[ -d "$BASE_DIR/lib/normelog" ]]; then
    echo "$BASE_DIR"
    return 0
  fi

  # Fallback: prefer a writable prefix for non-root users.
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    echo "/usr/local"
    return 0
  fi
  if [[ -w "/usr/local" ]] || [[ -w "/usr/local/bin" ]] || [[ -w "/usr/local/lib" ]]; then
    echo "/usr/local"
    return 0
  fi
  if [[ -n "${HOME:-}" ]]; then
    echo "$HOME/.local"
    return 0
  fi
  echo "/usr/local"
}

nl_update_can_write_dir_or_create() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    [[ -w "$dir" && -x "$dir" ]]
    return $?
  fi

  local parent="$dir"
  while [[ "$parent" != "/" && ! -d "$parent" ]]; do
    parent="$(dirname "$parent")"
  done
  [[ -d "$parent" && -w "$parent" && -x "$parent" ]]
}

nl_update_assert_writable_prefix() {
  local prefix="$1"
  local bindir="$prefix/bin"
  local libdir="$prefix/lib/normelog"
  local mandir="$prefix/share/man/man1"

  local missing=()
  nl_update_can_write_dir_or_create "$bindir" || missing+=("$bindir")
  nl_update_can_write_dir_or_create "$libdir" || missing+=("$libdir")
  nl_update_can_write_dir_or_create "$mandir" || missing+=("$mandir")

  if [[ ${#missing[@]} -gt 0 ]]; then
    nl_log_error "No write permission for installation prefix: $prefix"
    nl_log_error "Not writable: ${missing[*]}"
    nl_log_error "If this is a system-wide install, try:"
    nl_log_error "  sudo normelog --update"
    nl_log_error "Or specify a writable prefix, e.g.:"
    nl_log_error "  PREFIX=$HOME/.local normelog --update"
    return 1
  fi

  return 0
}

nl_update_apply() {
  nl_log_info "Checking for updates..."

  # Check for required tools
  if ! command -v curl >/dev/null 2>&1; then
    nl_log_error "curl is required for updates but not found in PATH"
    return 1
  fi
  if ! command -v make >/dev/null 2>&1; then
    nl_log_error "make is required for updates but not found in PATH"
    return 1
  fi
  if ! command -v tar >/dev/null 2>&1; then
    nl_log_error "tar is required for updates but not found in PATH"
    return 1
  fi

  # Fetch latest version from GitHub API
  local api_url="https://api.github.com/repos/marcnava-42cursus/normelog/releases/latest"
  local release_info

  local curl_err
  curl_err=$(mktemp 2>/dev/null || echo "")
  if [[ -n "$curl_err" ]]; then
    if ! release_info=$(curl -fsSL --max-time 10 "$api_url" 2>"$curl_err"); then
      nl_log_error "Could not fetch release information from GitHub"
      nl_log_error "$(tr -d '\n' <"$curl_err" 2>/dev/null || true)"
      rm -f "$curl_err" 2>/dev/null || true
      return 1
    fi
    rm -f "$curl_err" 2>/dev/null || true
  else
    release_info=$(curl -fsSL --max-time 10 "$api_url" 2>/dev/null || true)
  fi

  if [[ -z "$release_info" ]]; then
    nl_log_error "Could not fetch release information from GitHub"
    return 1
  fi

  # Extract version and download URL
  local tag_name
  tag_name=$(
    printf '%s\n' "$release_info" | \
      sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | \
      head -n1
  )

  local latest="${tag_name#v}"

  local tarball_url
  tarball_url=$(
    printf '%s\n' "$release_info" | \
      sed -nE 's/.*"tarball_url"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | \
      head -n1
  )

  # Fallback to public archive URL (less dependency on GitHub API for downloads)
  if [[ -n "$tag_name" ]]; then
    tarball_url="${tarball_url:-https://github.com/marcnava-42cursus/normelog/archive/refs/tags/${tag_name}.tar.gz}"
  fi

  if [[ -z "$latest" ]] || [[ -z "$tarball_url" ]]; then
    nl_log_error "Could not parse release information"
    return 1
  fi

  local current="${NL_VERSION#v}"

  # Check if already up to date (or ahead)
  local cmp=0
  nl_version_compare "$latest" "$current" || cmp=$?
  case $cmp in
    0)
      nl_log_info "Already on latest version: v$current"
      return 0
      ;;
    2)
      nl_log_info "Current version is newer than latest release: v$current (latest: v$latest)"
      return 0
      ;;
  esac

  nl_log_info "New version available: v$latest (current: v$current)"

  local install_prefix
  install_prefix="$(nl_update_get_install_prefix)"
  nl_log_info "Using installation prefix: $install_prefix"
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    if ! nl_update_assert_writable_prefix "$install_prefix"; then
      return 1
    fi
  fi

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
  if ! curl -fsSL --max-time 30 -o "$tarball" "$tarball_url"; then
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
  local make_log="$tmp_dir/make_install.log"
  if ! (cd "$source_dir" && make install PREFIX="$install_prefix") >"$make_log" 2>&1; then
    nl_log_error "Installation failed (PREFIX=$install_prefix)."
    if command -v tail >/dev/null 2>&1; then
      nl_log_error "Last output:"
      tail -n 25 "$make_log" >&2 || true
    fi
    nl_log_error "If this is a permissions issue, try:"
    nl_log_error "  sudo normelog --update"
    nl_log_error "Or specify a writable prefix, e.g.:"
    nl_log_error "  PREFIX=$HOME/.local normelog --update"
    rm -rf "$tmp_dir"
    return 1
  fi

  # Cleanup
  rm -rf "$tmp_dir"

  nl_log_info "Successfully updated to v$latest"
  nl_log_info "Restart your shell or run 'hash -r' to use the new version"

  return 0
}
