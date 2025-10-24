#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v shellcheck >/dev/null && shellcheck -x bin/normelog lib/*.sh scripts/*.sh || true
command -v shfmt >/dev/null && shfmt -d -i 0 -s . || true

