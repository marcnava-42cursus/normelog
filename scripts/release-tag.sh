#!/usr/bin/env bash
set -euo pipefail
ver=${1:-}
[[ -z "$ver" ]] && { echo "Usage: $0 vX.Y.Z"; exit 1; }
version_file="lib/version.sh"
[[ -f "$version_file" ]] || { echo "Error: $version_file not found" >&2; exit 1; }

if sed --version >/dev/null 2>&1; then
	sed -i -E "s/^NL_VERSION=\".*\"/NL_VERSION=\"${ver#v}\"/" "$version_file"
else
	sed -i '' -E "s/^NL_VERSION=\".*\"/NL_VERSION=\"${ver#v}\"/" "$version_file"
fi

git add "$version_file" && git commit -m "chore: bump version to ${ver#v}" && git tag "$ver"
