#!/usr/bin/env bash
set -euo pipefail
command -v help2man >/dev/null || { echo "help2man not found"; exit 1; }
help2man -N -n "norminette analyzer" -o normelog/share/man/normelog.1 normelog/bin/normelog

