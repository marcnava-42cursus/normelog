#!/usr/bin/env bash
nl_config_load() {
	NL_CONFIG_DIR_SYSTEM="/etc/normelog"
	NL_CONFIG_DIR_USER="${XDG_CONFIG_HOME}/normelog"

	# Load default config files
	for f in "$NL_CONFIG_DIR_SYSTEM/config" "$NL_CONFIG_DIR_USER/config"; do
		if [[ -f "$f" ]]; then
			nl_log_debug "Loading config: $f"
			# shellcheck disable=SC1090
			. "$f"
		fi
	done

	# Load profile if specified
	if [[ -n "${NL_PROFILE:-}" ]]; then
		nl_config_load_profile "$NL_PROFILE"
	fi
}

nl_config_load_profile() {
	local profile="$1"
	local profile_file=""

	# Try user profiles first, then system profiles
	for dir in "$NL_CONFIG_DIR_USER/profiles" "$NL_CONFIG_DIR_SYSTEM/profiles"; do
		if [[ -f "$dir/${profile}.conf" ]]; then
			profile_file="$dir/${profile}.conf"
			break
		fi
	done

	if [[ -z "$profile_file" ]]; then
		nl_log_error "Profile not found: $profile"
		nl_log_error "Looked in:"
		nl_log_error "  - $NL_CONFIG_DIR_USER/profiles/${profile}.conf"
		nl_log_error "  - $NL_CONFIG_DIR_SYSTEM/profiles/${profile}.conf"
		exit 1
	fi

	nl_log_debug "Loading profile: $profile_file"
	# shellcheck disable=SC1090
	. "$profile_file"
}
