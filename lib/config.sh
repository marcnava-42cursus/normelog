#!/usr/bin/env bash
nl_config_load() {
  NL_CONFIG_DIR_SYSTEM="/etc/normelog"
  NL_CONFIG_DIR_USER="${XDG_CONFIG_HOME}/normelog"
  for f in "$NL_CONFIG_DIR_SYSTEM/config" "$NL_CONFIG_DIR_USER/config"; do
    if [[ -f "$f" ]]; then
      # shellcheck disable=SC1090
      . "$f"
    fi
  done
}
