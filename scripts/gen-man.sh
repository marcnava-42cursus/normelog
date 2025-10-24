#!/usr/bin/env bash
# Man page version synchronization script
# The manual is manually maintained at share/man/normelog.1
# This script ensures the version number and date are up-to-date

set -euo pipefail

cd "$(dirname "$0")/.."

# Source version
source lib/version.sh

MAN_FILE="share/man/normelog.1"

if [[ ! -f "$MAN_FILE" ]]; then
  echo "Error: Man page not found at $MAN_FILE" >&2
  exit 1
fi

# Get current date in format "Month YYYY"
CURRENT_DATE=$(date '+%B %Y')

# Read current man page header
CURRENT_HEADER=$(head -n1 "$MAN_FILE")

# Extract current version from man page
if [[ "$CURRENT_HEADER" =~ \"([0-9]+\.[0-9]+\.[0-9]+)\" ]]; then
  MAN_VERSION="${BASH_REMATCH[1]}"
else
  echo "Warning: Could not extract version from man page" >&2
  MAN_VERSION="unknown"
fi

# Check if version needs updating
if [[ "$MAN_VERSION" != "$NL_VERSION" ]]; then
  echo "Updating man page version from $MAN_VERSION to $NL_VERSION"

  # Create new header line
  NEW_HEADER=".TH NORMELOG 1 \"$CURRENT_DATE\" \"$NL_VERSION\" \"User Commands\""

  # Update the man page (replace first line)
  sed -i "1s/.*/$NEW_HEADER/" "$MAN_FILE"

  echo "Man page updated successfully"
  echo "  Version: $NL_VERSION"
  echo "  Date: $CURRENT_DATE"
else
  echo "Man page version is up-to-date ($NL_VERSION)"
fi

# Verify man page syntax if groff is available
if command -v groff >/dev/null 2>&1; then
  echo "Verifying man page syntax..."
  if groff -man -Tascii "$MAN_FILE" >/dev/null 2>&1; then
    echo "Man page syntax is valid"
  else
    echo "Warning: Man page may have syntax errors" >&2
  fi
fi
