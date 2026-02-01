# bash completion for normelog

_normelog() {
	local cur prev
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	_normelog_complete_dir() {
		local arg="$1"
		local prefix="${2:-}"
		local replies=()
		COMPREPLY=()
		replies=($(compgen -d -- "$arg"))
		local i display test_path
		for i in "${replies[@]}"; do
			display="$i"
			printf -v test_path '%b' "$i"
			if [[ -d "$test_path" && "$display" != */ ]]; then
				display="${display}/"
			fi
			COMPREPLY+=("${prefix}${display}")
		done
		if type compopt >/dev/null 2>&1; then
			compopt -o nospace
		fi
	}

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
			_normelog_complete_dir "$cur"
			return 0
			;;
	esac

	case "$cur" in
		--chdir=*)
			_normelog_complete_dir "${cur#--chdir=}" "--chdir="
			return 0
			;;
		--directory=*)
			_normelog_complete_dir "${cur#--directory=}" "--directory="
			return 0
			;;
		--no-directory=*)
			_normelog_complete_dir "${cur#--no-directory=}" "--no-directory="
			return 0
			;;
	esac

	if [[ "$cur" == -C* && "$cur" != "-C" ]]; then
		_normelog_complete_dir "${cur#-C}" "-C"
		return 0
	fi
	if [[ "$cur" == -d* && "$cur" != "-d" ]]; then
		_normelog_complete_dir "${cur#-d}" "-d"
		return 0
	fi
	if [[ "$cur" == -n* && "$cur" != "-n" ]]; then
		_normelog_complete_dir "${cur#-n}" "-n"
		return 0
	fi

	# Complete options
	if [[ "$cur" == -* ]]; then
		COMPREPLY=($(compgen -W "${opts[*]}" -- "$cur"))
		return 0
	fi

	return 0
}

complete -F _normelog normelog
