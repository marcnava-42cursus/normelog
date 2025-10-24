#!/usr/bin/env bash
nl_run_norminette() {
  if ! command -v norminette >/dev/null 2>&1; then
    echo "Error: norminette not found in PATH" >&2
    echo ""  # produce empty output for pipeline
    return 127
  fi
  if [[ ${#NL_DIRS[@]} -eq 0 ]]; then
    if [[ "$NL_USE_GITIGNORE" -eq 1 ]]; then
      norminette -R CheckForbidenSourceHeader --use-gitignore || true
    else
      norminette -R CheckForbidenSourceHeader || true
    fi
  else
    norminette -R CheckForbidenSourceHeader "${NL_DIRS[@]}" || true
  fi
}
