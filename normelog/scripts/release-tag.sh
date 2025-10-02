#!/usr/bin/env bash
set -euo pipefail
ver=${1:-}
[[ -z "$ver" ]] && { echo "Usage: $0 vX.Y.Z"; exit 1; }
sed -i -E "s/^NL_VERSION=\".*\"/NL_VERSION=\"${ver#v}\"/" normelog/lib/version.sh
git add normelog/lib/version.sh && git commit -m "chore: bump version to ${ver#v}" && git tag "$ver"

