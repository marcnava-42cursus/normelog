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
NL_DO_UPDATE=0
NL_NO_UPDATE_CHECK=0
NL_GIT_STAGED=0
NL_GIT_SINCE=""
NL_GIT_BRANCH=""
NL_WATCH=0
NL_ORIGINAL_ARGS=()
NL_MIN_SEVERITY=""
NL_MAX_ERRORS=""
NL_DIFF_BASELINE=""
NL_SAVE_BASELINE=""
NL_PROFILE=""
NL_PARALLEL=0
NL_PARALLEL_JOBS=4
NL_ORDER=""

nl_flags_help() {
cat <<'HLP'
Usage: normelog [OPTIONS] [ERROR_TYPE...]

normelog - Analyzer and filter for norminette with statistics and multiple output formats

GENERAL OPTIONS:
  -h, --help               Show this help message and exit
  -v, --version            Show version and exit
  -a                       Show detailed per-file error listing
  --json                   Output results in JSON format
  --html                   Output results as HTML report
  --format <fmt>           Output format: text, json, html, junit, sarif
  --order <dir>            Sort error types by count: asc, desc
  --debug                  Enable debug logging to stderr
  -C <dir>, --chdir <dir>  Change working directory before running

DIRECTORY OPTIONS:
  -d <dir>                 Analyze only specified directory (repeatable)
  -n <dir>                 Exclude directory from analysis (repeatable)
  -I, --ignore-gitignore   Do not use --use-gitignore with norminette

GIT INTEGRATION:
  --staged                 Check only staged files (for pre-commit hooks)
  --since <ref>            Check files changed since commit/branch
  --branch <ref>           Check files in current branch vs base (default: main)

QUALITY CONTROL:
  --severity <level>       Filter by minimum severity: CRITICAL, WARNING, INFO
  --severity-only <level>  Filter by exact severity: CRITICAL, WARNING, INFO
  --max-errors <n>         Exit with error if total errors exceeds n
  --profile <name>         Load configuration profile (strict, dev, ci, etc.)

DIFF MODE:
  --diff <file>            Compare with baseline JSON file
  --save-baseline <file>   Save current results as baseline JSON

PERFORMANCE:
  --parallel [jobs]        Run norminette in parallel (default: 4 jobs)
  --watch                  Continuously monitor files and re-run on changes

UPDATE:
  --update                 Check for and install latest version
  --no-update-check        Disable automatic update check for this run

ERROR TYPE FILTERING:
  TYPE ...                 Include only these error types (case-insensitive)
  -TYPE ...                Exclude these error types

EXAMPLES:
  normelog                              # Check current directory
  normelog -a                           # Show all error details
  normelog --json                       # Output as JSON
  normelog FORBIDDEN SPACE              # Only show these error types
  normelog -EMPTY_LINE_EOF              # Exclude this error type
  normelog --profile strict             # Use strict profile
  normelog --staged                     # Pre-commit hook
  normelog --parallel 8                 # Use 8 parallel jobs
  normelog --watch --profile dev        # Watch mode with dev profile

ENVIRONMENT VARIABLES:
  NL_OUTPUT              Output format (text|json|html|junit|sarif)
  NL_DEBUG               Enable debug mode (0|1)
  NL_COLOR               Force color output (0|1, auto-detected)
  NL_AUTO_UPDATE_CHECK   Enable update checks (0|1, default: 1)
  NL_PARALLEL_JOBS       Default parallel jobs (default: 4)
  XDG_CONFIG_HOME        Config directory ($HOME/.config)
  XDG_CACHE_HOME         Cache directory ($HOME/.cache)

For detailed documentation, see: man normelog
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
			-h|--help)
				NL_SHOW_HELP=1
				;;
			-v|--version)
				NL_SHOW_VERSION=1
				;;
			-a)
				NL_SHOW_ALL_DETAILS=1
				;;
			-I|--ignore-gitignore)
				NL_USE_GITIGNORE=0
				;;
			--json)
				NL_OUTPUT=json
				;;
			--html)
				NL_OUTPUT=html
				;;
			--format)
				if [[ -z ${2:-} ]]; then
					echo "Error: --format requires a format type (text, json, html, junit, sarif)" >&2
					exit 1
				fi
				case "$2" in
					text|json|html|junit|sarif)
						NL_OUTPUT="$2"
						;;
					*)
						echo "Error: Invalid format '$2'. Valid formats: text, json, html, junit, sarif" >&2
						exit 1
						;;
				esac
				shift
				;;
			--order)
				if [[ -z ${2:-} ]]; then
					echo "Error: --order requires a sort direction (asc, desc)" >&2
					exit 1
				fi
				case "$2" in
					asc|desc)
						NL_ORDER="$2"
						;;
					*)
						echo "Error: Invalid order '$2'. Valid values: asc, desc" >&2
						exit 1
						;;
				esac
				shift
				;;
			--debug)
				NL_DEBUG=1
				;;
			--update)
				NL_DO_UPDATE=1
				;;
			--no-update-check)
				NL_NO_UPDATE_CHECK=1
				;;
			--staged)
				NL_GIT_STAGED=1
				;;
			--since)
				if [[ -z ${2:-} ]]; then
					echo "Error: --since requires a git reference" >&2
					exit 1
				fi
				NL_GIT_SINCE="$2"
				shift
				;;
			--branch)
				if [[ -z ${2:-} ]]; then
					echo "Error: --branch requires a branch name" >&2
					exit 1
				fi
				NL_GIT_BRANCH="$2"
				shift
				;;
			--watch)
				NL_WATCH=1
				;;
			--severity)
				if [[ -z ${2:-} ]]; then
					echo "Error: --severity requires a level (CRITICAL, WARNING, INFO)" >&2
					exit 1
				fi
				NL_MIN_SEVERITY="$2"
				shift
				;;
			--severity-only)
				if [[ -z ${2:-} ]]; then
					echo "Error: --severity-only requires a level (CRITICAL, WARNING, INFO)" >&2
					exit 1
				fi
				NL_ONLY_SEVERITY="$2"
				shift
				;;
			--max-errors)
				if [[ -z ${2:-} ]]; then
					echo "Error: --max-errors requires a number" >&2
					exit 1
				fi
				NL_MAX_ERRORS="$2"
				shift
				;;
		--profile)
			if [[ -z ${2:-} ]]; then
				echo "Error: --profile requires a profile name" >&2
				exit 1
			fi
			NL_PROFILE="$2"
			shift
			;;
		--diff)
			if [[ -z ${2:-} ]]; then
				echo "Error: --diff requires a baseline file path" >&2
				exit 1
			fi
			NL_DIFF_BASELINE="$2"
			shift
			;;
		--save-baseline)
			if [[ -z ${2:-} ]]; then
				echo "Error: --save-baseline requires a file path" >&2
				exit 1
			fi
			NL_SAVE_BASELINE="$2"
			shift
			;;
		--parallel)
			NL_PARALLEL=1
			# Optional: accept number of jobs
			if [[ -n ${2:-} ]] && [[ $2 =~ ^[0-9]+$ ]]; then
				NL_PARALLEL_JOBS="$2"
				shift
			fi
			;;
			-d*)
				local dir
				if [[ ${#1} -gt 2 ]]; then
					dir="${1#-d}"
				else
					if [[ -z ${2:-} ]]; then
						echo "Error: -d requires a directory" >&2
						exit 1
					fi
					dir="$2"
					shift
				fi
				if [[ ! -d "$dir" ]]; then
					echo "Error: Directory does not exist: $dir" >&2
					exit 1
				fi
				NL_DIRS+=("$dir")
				;;
			--directory=*)
				local dir="${1#--directory=}"
				if [[ ! -d "$dir" ]]; then
					echo "Error: Directory does not exist: $dir" >&2
					exit 1
				fi
				NL_DIRS+=("$dir")
				;;
			-n*)
				local dir
				if [[ ${#1} -gt 2 ]]; then
					dir="${1#-n}"
				else
					if [[ -z ${2:-} ]]; then
						echo "Error: -n requires a directory" >&2
						exit 1
					fi
					dir="$2"
					shift
				fi
				if [[ ! -d "$dir" ]]; then
					echo "Error: Directory does not exist: $dir" >&2
					exit 1
				fi
				NL_EXCLUDE_DIRS+=("$dir")
				;;
			--no-directory=*)
				local dir="${1#--no-directory=}"
				if [[ ! -d "$dir" ]]; then
					echo "Error: Directory does not exist: $dir" >&2
					exit 1
				fi
				NL_EXCLUDE_DIRS+=("$dir")
				;;
			--*)
				echo "Error: Unknown option '$1'" >&2
				exit 1
				;;
			-*)
				NL_EXCLUDE_TYPES+=("${1#-}")
				;;
			*)
				NL_INCLUDE_TYPES+=("$1")
				;;
		esac;
		shift
	done
}
