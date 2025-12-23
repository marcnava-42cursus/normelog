#!/usr/bin/env bash
NL_VERSION="0.7.1"

nl_version_init() {
	export NL_VERSION
}


# Compare two semantic versions (X.Y.Z).
# Returns:
#   0 if equal
#   1 if $1 > $2
#   2 if $1 < $2
nl_version_compare() {
	local a="${1#v}" b="${2#v}"
	local IFS=.
	local a_major a_minor a_patch
	local b_major b_minor b_patch

	read -r a_major a_minor a_patch <<<"$a"
	read -r b_major b_minor b_patch <<<"$b"

	a_major=${a_major:-0}; a_minor=${a_minor:-0}; a_patch=${a_patch:-0}
	b_major=${b_major:-0}; b_minor=${b_minor:-0}; b_patch=${b_patch:-0}

	[[ $a_major =~ ^[0-9]+$ ]] || a_major=0
	[[ $a_minor =~ ^[0-9]+$ ]] || a_minor=0
	[[ $a_patch =~ ^[0-9]+$ ]] || a_patch=0
	[[ $b_major =~ ^[0-9]+$ ]] || b_major=0
	[[ $b_minor =~ ^[0-9]+$ ]] || b_minor=0
	[[ $b_patch =~ ^[0-9]+$ ]] || b_patch=0

	if ((a_major > b_major)); then return 1; fi
	if ((a_major < b_major)); then return 2; fi
	if ((a_minor > b_minor)); then return 1; fi
	if ((a_minor < b_minor)); then return 2; fi
	if ((a_patch > b_patch)); then return 1; fi
	if ((a_patch < b_patch)); then return 2; fi
	return 0
}
