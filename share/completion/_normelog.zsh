#compdef normelog

_normelog() {
	_arguments -s \
		'(-h --help)'{-h,--help}'[Show help message and exit]' \
		'(-v --version)'{-v,--version}'[Show version and exit]' \
		'-a[Show detailed per-file error listing]' \
		'--json[Output results in JSON format]' \
		'--html[Output results as HTML report]' \
		'--format[Output format]:format:(text json html junit sarif)' \
		'--order[Sort error types by count]:order:(asc desc)' \
		'--debug[Enable debug logging to stderr]' \
		'(-C --chdir)'{-C,--chdir}'[Change working directory before running]:directory:_files -/' \
		'-d[Analyze only specified directory (repeatable)]:directory:_files -/' \
		'-n[Exclude directory from analysis (repeatable)]:directory:_files -/' \
		'(-I --ignore-gitignore)'{-I,--ignore-gitignore}'[Do not use --use-gitignore with norminette]' \
		'--staged[Check only staged files]' \
		'--since[Check files changed since git ref]:ref:' \
		'--branch[Check files in current branch vs base]:ref:' \
		'--severity[Filter by minimum severity]:level:(INFO WARNING CRITICAL)' \
		'--severity-only[Filter by exact severity]:level:(INFO WARNING CRITICAL)' \
		'--max-errors[Exit with error if total errors exceeds n]:number:' \
		'--profile[Load configuration profile]:profile:' \
		'--diff[Compare with baseline JSON file]:file:_files' \
		'--save-baseline[Save current results as baseline JSON]:file:_files' \
		'--parallel[Run norminette in parallel]:jobs:' \
		'--watch[Continuously monitor files and re-run on changes]' \
		'--update[Check for and install latest version]' \
		'--no-update-check[Disable automatic update check for this run]' \
		'*:error type:'
}

_normelog "$@"

