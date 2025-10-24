#!/usr/bin/env bash
set -euo pipefail
command -v shellcheck >/dev/null && shellcheck -x normelog/bin/normelog normelog/lib/*.sh || true
command -v shfmt >/dev/null && shfmt -d -i 2 -ci normelog || true

