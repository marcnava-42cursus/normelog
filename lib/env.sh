#!/usr/bin/env bash
nl_env_init() {
	set -euo pipefail
	: "${XDG_CONFIG_HOME:=${HOME}/.config}"
	: "${NL_OUTPUT:=text}"   # text|json
}

