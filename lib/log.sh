#!/usr/bin/env bash
# Detect if stdout is a terminal
: "${NL_COLOR:=}"
if [[ -z "$NL_COLOR" ]]; then
	[[ -t 1 ]] && NL_COLOR=1 || NL_COLOR=0
fi
nl_log_color() { [[ "$NL_COLOR" -eq 1 ]] || return 0; printf "\033[%sm" "$1"; }
nl_log_reset() { printf "\033[0m"; }
nl_log() { local lvl=$1; shift; echo "[$lvl] $*" >&2; }
nl_log_info() { nl_log INFO "$@"; }
nl_log_warn() { nl_log WARN "$@"; }
nl_log_error() { nl_log ERROR "$@"; }
nl_log_debug() { [[ "${NL_DEBUG:-0}" -eq 1 ]] && nl_log DEBUG "$@" || true; }
