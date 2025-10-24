#!/usr/bin/env bash
# Plugin system for normelog
# Plugins are loaded from $BASE_DIR/plugins.d/*.sh in alphabetical order

# Plugin hooks (can be overridden by plugins)
nl_hook_pre_norminette() { :; }
nl_hook_post_parse() { :; }
nl_hook_post_stats() { :; }
nl_hook_pre_format() { :; }

nl_plugins_load() {
  local plugin_dir="${BASE_DIR}/plugins.d"

  # Check if plugins directory exists
  if [[ ! -d "$plugin_dir" ]]; then
    nl_log_debug "No plugins directory found at $plugin_dir"
    return 0
  fi

  # Load all .sh files in alphabetical order
  local plugin
  local loaded_count=0

  for plugin in "$plugin_dir"/*.sh; do
    # Skip if no .sh files found (glob didn't match)
    [[ -f "$plugin" ]] || continue

    nl_log_debug "Loading plugin: $(basename "$plugin")"

    # Source the plugin with error handling
    # shellcheck disable=SC1090
    if . "$plugin"; then
      ((loaded_count++))
      nl_log_debug "Successfully loaded plugin: $(basename "$plugin")"
    else
      nl_log_warn "Failed to load plugin: $(basename "$plugin")"
    fi
  done

  if [[ $loaded_count -gt 0 ]]; then
    nl_log_debug "Loaded $loaded_count plugin(s)"
  fi
}
