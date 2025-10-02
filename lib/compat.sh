#!/usr/bin/env bash
# wrappers for grep/sed/awk portability if needed
nl_grep() { grep "$@"; }
nl_sed() { sed "$@"; }
nl_awk() { awk "$@"; }

