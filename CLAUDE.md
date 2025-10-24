# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**normelog** is a portable bash-based helper around `norminette` that summarizes and filters norm errors for C projects. It wraps norminette output and provides filtered, colorized summaries with per-type error counts.

## Architecture

### Modular Shell Structure

The codebase follows a modular bash architecture with clear separation:

- **bin/normelog**: Main entrypoint that sources all library modules and orchestrates the pipeline
- **lib/**: Self-contained modules, each providing specific functionality via shell functions
- **share/**: Completions (bash/zsh) and man pages
- **plugins.d/**: Optional plugin system (currently just placeholder)
- **scripts/**: Development utilities (linting, releases, man page generation)

### Data Pipeline

The tool implements a functional pipeline architecture (bin/normelog:69-98):

1. `nl_run_norminette()` - Execute norminette with options
2. `nl_exclude_filter()` - Apply directory exclusions
3. `nl_parse_output()` - Parse raw norminette output into structured records
4. `nl_filter_errors()` - Filter by error type (include/exclude patterns)
5. `nl_compute_stats()` - Aggregate statistics
6. `nl_format_text()` or `nl_format_json()` - Format final output

### Internal Record Format

Between pipeline stages, data flows as line-oriented records (lib/parse.sh:3-5):
```
FILE <path> STATUS <OK|ERR>
ERR <type> <line> <col> <message>
```

This simple format allows AWK-based transformations at each stage without requiring complex parsers.

### Module Loading

All lib modules are sourced in sequence (bin/normelog:10-24). Each module:
- Defines functions prefixed with `nl_<module>_`
- May set global variables (typically `NL_*` prefix)
- Has no side effects at load time (all logic happens in functions)

## Common Commands

### Development
```bash
# Lint the codebase (runs shellcheck + shfmt)
make lint

# Generate man page from script comments
make man

# Run normelog locally (without installing)
./bin/normelog [options]
```

### Testing
```bash
# No automated tests yet - planned to add BATS
make test
```

### Build & Install
```bash
# Install to /usr/local (or custom PREFIX)
make install

# Install with custom paths
make install PREFIX=/opt/normelog

# Uninstall
make uninstall

# Update man page cache after installing
make man-install
```

### Release Process
```bash
# Tag a new version
./scripts/release-tag.sh vX.Y.Z
```

## Key Configuration

### User Configuration
- System config: `/etc/normelog/config`
- User config: `$XDG_CONFIG_HOME/normelog/config`

Config files are sourced as shell scripts and can override any `NL_*` variables.

### Flag Parsing
All CLI flags are parsed in lib/flags.sh using a single `while` loop. Flags set global `NL_*` variables:
- `-a` → `NL_SHOW_ALL_DETAILS=1`
- `--json` → `NL_OUTPUT=json`
- `-d <dir>` → appends to `NL_DIRS` array
- `-n <dir>` → appends to `NL_EXCLUDE_DIRS` array
- Positional args:
  - `TYPE` → appends to `NL_INCLUDE_TYPES`
  - `-TYPE` → appends to `NL_EXCLUDE_TYPES`

## Important Implementation Details

### Norminette Invocation
- Always uses `-R CheckForbidenSourceHeader` flag
- Conditionally passes `--use-gitignore` when no directories specified and `NL_USE_GITIGNORE=1`
- Runs with `|| true` to capture output even on non-zero exit (lib/run_norminette.sh:10-16)

### AWK-Based Processing
Most data transformation happens via AWK one-liners embedded in bash functions:
- **Parsing**: lib/parse.sh uses regex matching to extract file status and error details
- **Filtering**: lib/filter.sh builds inclusion/exclusion maps from shell arrays
- **Stats**: lib/stats.sh accumulates counts in associative arrays
- **Formatting**: Both text and JSON formatters are pure AWK scripts

When modifying these, test with various norminette outputs as AWK scripts can be fragile with unexpected input.

### Output Formats
- **Text** (default): Colored summary + error type counts + per-file error listings
- **JSON**: Structured output with `ok_files`, `error_files`, `total_errors`, `by_type`, and `files` array

## Code Style

- Bash: Use shellcheck and shfmt (see .shellcheckrc)
- Indentation: 2 spaces, continue indentation enabled
- Function naming: `nl_<module>_<action>` pattern
- Global variables: `NL_*` prefix
- Always quote variable expansions unless intentionally splitting
- Use `set -euo pipefail` in scripts/ utilities but not in lib/ modules (sourced code)
