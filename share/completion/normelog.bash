# bash completion for normelog

_normelog() {
	local cur prev
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	local opts=(
		-h --help
		-v --version
		-a
		--json
		--html
		--format
		--order
		--debug
		-C --chdir
		-d
		-n
		-I --ignore-gitignore
		--staged
		--since
		--branch
		--severity
		--severity-only
		--max-errors
		--profile
		--diff
		--save-baseline
		--parallel
		--watch
		--update
		--no-update-check
	)

	case "$prev" in
		--format)
			COMPREPLY=($(compgen -W "text json html junit sarif" -- "$cur"))
			return 0
			;;
		--order)
			COMPREPLY=($(compgen -W "asc desc" -- "$cur"))
			return 0
			;;
		--severity|--severity-only)
			COMPREPLY=($(compgen -W "INFO WARNING CRITICAL" -- "$cur"))
			return 0
			;;
		-C|--chdir|-d|-n)
			COMPREPLY=($(compgen -d -- "$cur"))
			return 0
			;;
	esac

	# Complete options
	if [[ "$cur" == -* ]]; then
		COMPREPLY=($(compgen -W "${opts[*]}" -- "$cur"))
		return 0
	fi

	return 0
}

complete -F _normelog normelog

