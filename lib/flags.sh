#!/usr/bin/env bash
NL_SHOW_HELP=0
NL_SHOW_VERSION=0
NL_SHOW_ALL_DETAILS=0
NL_USE_GITIGNORE=1
NL_DIRS=()
NL_EXCLUDE_DIRS=()
NL_INCLUDE_TYPES=()
NL_EXCLUDE_TYPES=()
NL_CHDIR=""

nl_flags_help() {
cat <<'HLP'
Usage: normelog [OPTIONS] [ERROR_TYPE...]
  -h, --help              Show help
  -v, --version           Show version
  -a                      Show detailed per-file listing
  -I, --ignore-gitignore  Do not pass --use-gitignore when no directories are specified
  -C <dir>, --chdir <dir>,
    --chdir=<dir>         Change working directory before running
  -d <dir> | -d<dir> | --directory=<dir>
  -n <dir> | -n<dir> | --no-directory=<dir>
  --json                  Output JSON
  --debug                 Debug logs
  Patterns:
    TYPE ...      include
    -TYPE ...     exclude
HLP
}

nl_flags_parse() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -C)
        if [[ -z ${2:-} ]]; then
          echo "Error: -C requires a directory" >&2
          exit 1
        fi
        NL_CHDIR="$2"
        shift
        ;;
      -C*)
        NL_CHDIR="${1#-C}"
        ;;
      --chdir)
        if [[ -z ${2:-} ]]; then
          echo "Error: --chdir requires a directory" >&2
          exit 1
        fi
        NL_CHDIR="$2"
        shift
        ;;
      --chdir=*)
        NL_CHDIR="${1#--chdir=}"
        ;;
      -h|--help) NL_SHOW_HELP=1 ;;
      -v|--version) NL_SHOW_VERSION=1 ;;
      -a) NL_SHOW_ALL_DETAILS=1 ;;
      -I|--ignore-gitignore) NL_USE_GITIGNORE=0 ;;
      --json) NL_OUTPUT=json ;;
      --debug) NL_DEBUG=1 ;;
      -d*) if [[ ${#1} -gt 2 ]]; then NL_DIRS+=("${1#-d}"); else NL_DIRS+=("$2"); shift; fi ;;
      --directory=*) NL_DIRS+=("${1#--directory=}") ;;
      -n*) if [[ ${#1} -gt 2 ]]; then NL_EXCLUDE_DIRS+=("${1#-n}"); else NL_EXCLUDE_DIRS+=("$2"); shift; fi ;;
      --no-directory=*) NL_EXCLUDE_DIRS+=("${1#--no-directory=}") ;;
      -*) NL_EXCLUDE_TYPES+=("${1#-}") ;;
      *) NL_INCLUDE_TYPES+=("$1") ;;
    esac; shift
  done
}
