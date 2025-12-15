# Documentation Audit

This document tracks documentation coverage for normelog and provides a quick inventory of modules, CLI flags, and environment variables.

## Scope

Primary docs:
- `README.md`
- `share/man/normelog.1`
- `lib/flags.sh` (`nl_flags_help`)

Support docs:
- `TODO.md`
- `CHANGELOG.md`
- `CLAUDE.md`

## Module Inventory

Core:
- `bin/normelog` (entrypoint)
- `lib/env.sh` (XDG defaults, base env)
- `lib/version.sh` (version + semver compare)
- `lib/log.sh` (stderr logging, color detection)
- `lib/config.sh` (system/user config + profiles)
- `lib/flags.sh` (CLI parsing + help)
- `lib/run_norminette.sh` (norminette invocation)
- `lib/exclude.sh` (directory exclusion)
- `lib/parse.sh` (norminette output → FILE/ERR records)
- `lib/filter.sh` (type include/exclude filtering)
- `lib/stats.sh` (OK/ERR counts, totals)

Output formats:
- `lib/format_text.sh` (text output)
- `lib/format_json.sh` (JSON output)
- `lib/format_html.sh` (HTML report)
- `lib/format_junit.sh` (JUnit XML)
- `lib/format_sarif.sh` (SARIF JSON)

Advanced features:
- `lib/plugins.sh` (plugin loader + hooks)
- `lib/git.sh` (staged/since/branch file selection)
- `lib/watch.sh` (watch mode)
- `lib/severity.sh` (severity classification + filtering)
- `lib/diff.sh` (baseline diff mode)
- `lib/parallel.sh` (parallel norminette execution)
- `lib/update_check.sh` (update notifications)
- `lib/update_apply.sh` (self-update)
- `lib/optimize.sh` (small perf helpers)
- `lib/compat.sh` (portability shims)

## CLI Flags (by `--help`)

General:
- `-h`, `--help`
- `-v`, `--version`
- `-a`
- `--debug`
- `-C <dir>`, `--chdir <dir>`

Directories:
- `-d <dir>`
- `-n <dir>`
- `-I`, `--ignore-gitignore`

Output:
- `--json`
- `--html`
- `--format <text|json|html|junit|sarif>`

Git integration:
- `--staged`
- `--since <ref>`
- `--branch <ref>`

Quality control:
- `--severity <CRITICAL|WARNING|INFO>`
- `--max-errors <n>`
- `--profile <name>`

Diff mode:
- `--diff <file>`
- `--save-baseline <file>`

Performance:
- `--parallel [jobs]`
- `--watch`

Update:
- `--update`
- `--no-update-check`

## Environment Variables

Documented in README/man/config example:
- `NL_OUTPUT` (`text|json|html|junit|sarif`)
- `NL_DEBUG` (`0|1`)
- `NL_COLOR` (`0|1`, auto-detected if unset)
- `NL_AUTO_UPDATE_CHECK` (`0|1`)
- `NL_PARALLEL_JOBS` (number)
- `XDG_CONFIG_HOME` (config base dir)
- `XDG_CACHE_HOME` (cache base dir)

## Validation Notes

- `lib/stats.sh` emits: `OK_FILES`, `ERR_FILES`, `TOTAL_ERRORS`, and `TYPE ...` lines; formatters depend on these keys.
- `lib/format_json.sh` must emit valid JSON; it escapes tabs/newlines/quotes/backslashes.
- Diff mode (`--diff`) compares JSON baselines and requires `python3`.
- Shell completions live in `share/completion/normelog.bash` and `share/completion/_normelog.zsh`.

