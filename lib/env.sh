#!/usr/bin/env bash
nl_env_init() {
	: "${XDG_CONFIG_HOME:=${HOME}/.config}"
	: "${NL_OUTPUT:=text}"   # text|json
}

