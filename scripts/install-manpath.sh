#!/usr/bin/env bash
set -euo pipefail

prefix="${1:-}"
if [[ -z "$prefix" ]]; then
  echo "usage: install-manpath.sh <prefix>" >&2
  exit 1
fi

man_dir="$prefix/share/man"

if ! command -v man >/dev/null 2>&1; then
  exit 0
fi

current=""
if command -v manpath >/dev/null 2>&1; then
  current="$(manpath)"
elif [[ -n "${MANPATH:-}" ]]; then
  current="$MANPATH"
fi

case ":$current:" in
  *":$man_dir:"*)
    exit 0
    ;;
esac

if [[ -z "${HOME:-}" ]]; then
  exit 0
fi

manpath_file="$HOME/.manpath"
if [[ -f "$manpath_file" ]]; then
  if ! grep -qx "$man_dir" "$manpath_file" 2>/dev/null; then
    printf '%s\n' "$man_dir" >> "$manpath_file"
    echo "Added $man_dir to $manpath_file (for man(1) discovery)."
  fi
else
  printf '%s\n' "$man_dir" > "$manpath_file"
  echo "Created $manpath_file with $man_dir (for man(1) discovery)."
fi

echo "Open a new shell or run: export MANPATH=\"$man_dir\":\$MANPATH"
