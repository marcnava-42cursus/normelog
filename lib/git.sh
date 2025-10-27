#!/usr/bin/env bash
# lib/git.sh - Git integration for incremental checking

# Get list of files changed since a commit/branch
nl_git_get_changed_files() {
	local ref="${1:-HEAD}"

	# Check if we're in a git repo
	if ! git rev-parse --git-dir >/dev/null 2>&1; then
		nl_log_error "Not in a git repository. Git integration requires a git repository."
		nl_log_error "Run 'git init' to initialize a repository or use without --since flag."
		return 1
	fi

	# Get changed files (C and H only)
	git diff --name-only --diff-filter=ACMR "$ref" 2>/dev/null | grep -E '\.(c|h)$' || true
}

# Get staged files (for pre-commit hooks)
nl_git_get_staged_files() {
	# Check if we're in a git repo
	if ! git rev-parse --git-dir >/dev/null 2>&1; then
		nl_log_error "Not in a git repository. Git integration requires a git repository."
		nl_log_error "Run 'git init' to initialize a repository or use without --staged flag."
		return 1
	fi

	# Get staged files (C and H only)
	git diff --name-only --cached --diff-filter=ACMR 2>/dev/null | grep -E '\.(c|h)$' || true
}

# Get files changed in current branch vs base branch
nl_git_get_branch_files() {
	local base_branch="${1:-main}"

	# Check if we're in a git repo
	if ! git rev-parse --git-dir >/dev/null 2>&1; then
		nl_log_error "Not in a git repository. Git integration requires a git repository."
		nl_log_error "Run 'git init' to initialize a repository or use without --branch flag."
		return 1
	fi

	# Check if base branch exists
	if ! git rev-parse --verify "$base_branch" >/dev/null 2>&1; then
		# Try 'master' as fallback
		if git rev-parse --verify "master" >/dev/null 2>&1; then
			base_branch="master"
			nl_log_debug "Base branch 'main' not found, using 'master' instead"
		else
			nl_log_error "Base branch '$base_branch' not found in repository"
			nl_log_error "Specify an existing branch with --branch <name>"
			return 1
		fi
	fi

	# Get files changed in current branch
	git diff --name-only --diff-filter=ACMR "$base_branch"...HEAD 2>/dev/null | grep -E '\.(c|h)$' || true
}
