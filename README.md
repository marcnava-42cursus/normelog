# normelog

[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/yourusername/normelog/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A powerful, portable bash-based analyzer and filter for `norminette` with intelligent filtering, statistics tracking, and multiple output formats. Designed for 42 School students working with C projects.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
  - [Basic Commands](#basic-commands)
  - [Options](#options)
  - [Error Type Filtering](#error-type-filtering)
  - [Directory Control](#directory-control)
  - [Output Formats](#output-formats)
- [How It Works](#how-it-works)
  - [Pipeline Architecture](#pipeline-architecture)
  - [Internal Data Format](#internal-data-format)
  - [Modular Design](#modular-design)
- [Configuration](#configuration)
- [Advanced Usage](#advanced-usage)
- [Examples](#examples)
- [Shell Completions](#shell-completions)
- [Development](#development)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Features

- **Smart Filtering**: Filter errors by type with include/exclude patterns
- **Statistics Tracking**: Comprehensive error counts and file statistics
- **Multiple Output Formats**: Human-readable text or machine-parsable JSON
- **Directory Management**: Include or exclude specific directories from analysis
- **Gitignore Support**: Automatically respects `.gitignore` files (configurable)
- **Modular Architecture**: Clean, maintainable bash codebase with separated concerns
- **Shell Completions**: Bash and Zsh completion support out of the box
- **Portable**: Pure bash implementation, works on any POSIX-compliant system
- **Configurable**: System-wide and user-specific configuration files
- **Plugin System**: Extensible architecture for custom plugins

## Requirements

- `bash` (version 4.0 or higher)
- `norminette` (available in PATH)
- Standard Unix utilities: `awk`, `sed`, `grep`

## Installation

### Via Make (Recommended)

```bash
# Clone or download the repository
git clone https://github.com/yourusername/normelog.git
cd normelog

# Install to /usr/local (requires sudo)
make install

# Or install to a custom location
make install PREFIX=$HOME/.local

# Update man page database
make man-install
```

This installs:
- Binary to `$PREFIX/bin/normelog`
- Man page to `$PREFIX/share/man/man1/normelog.1`
- Bash completion to `/etc/bash_completion.d/normelog`
- Zsh completion to `/usr/share/zsh/site-functions/_normelog`

### Manual Installation

```bash
# Make the script executable
chmod +x bin/normelog

# Create a symlink in your PATH
sudo ln -sf "$PWD/bin/normelog" /usr/local/bin/normelog

# Or copy the entire directory
cp -r . /opt/normelog
export PATH="/opt/normelog/bin:$PATH"
```

### Verification

```bash
normelog --version
normelog --help
```

## Quick Start

```bash
# Basic usage - analyze current directory
normelog

# Show detailed per-file error listing
normelog -a

# Filter specific error types
normelog SPACE TAB

# Analyze specific directories
normelog -d src -d include

# Exclude directories from analysis
normelog -n tests -n build

# Output as JSON for scripting
normelog --json

# Combine options
normelog -d src -n build FORBIDDEN -TOO_MANY_VARS_FUNC --json
```

## Usage

### Basic Commands

```bash
normelog [OPTIONS] [DIRECTORY_OPTIONS] [ERROR_TYPE...]
```

When run without arguments, `normelog`:
1. Executes `norminette` with the `-R CheckForbidenSourceHeader` flag
2. Respects `.gitignore` files (unless `-I` is specified)
3. Parses and aggregates all errors
4. Displays a summary with error counts

### Options

#### General Options

| Flag | Long Form | Description |
|------|-----------|-------------|
| `-h` | `--help` | Display the manual page and exit |
| `-v` | `--version` | Show version information and exit |
| `-a` | - | Show detailed per-file error listing |
| `--debug` | - | Enable debug output to stderr |

#### Directory Options

| Flag | Long Form | Description |
|------|-----------|-------------|
| `-d DIR` | `--directory=DIR` | Analyze only specified directories (repeatable) |
| `-n DIR` | `--no-directory=DIR` | Exclude directories from results (repeatable) |
| `-C DIR` | `--chdir=DIR` | Change to directory before running |
| `-I` | `--ignore-gitignore` | Don't respect `.gitignore` files |

#### Output Options

| Flag | Description |
|------|-------------|
| `--json` | Output results in JSON format |

### Error Type Filtering

Error types can be filtered using positional arguments:

- **Include patterns**: Specify error types to include (case-insensitive substring match)
- **Exclude patterns**: Prefix with `-` to exclude specific types

#### Filtering Rules

1. Include patterns are evaluated first
2. Exclude patterns are applied second
3. All patterns are case-insensitive
4. Patterns match using substring comparison

#### Examples

```bash
# Show only FORBIDDEN errors
normelog FORBIDDEN

# Show SPACE or TAB related errors
normelog SPACE TAB

# Show all TOO_* errors except TOO_MANY_VARS_FUNC
normelog TOO -TOO_MANY_VARS_FUNC

# Multiple filters
normelog SPACE TAB LINE -LINE_TOO_LONG
```

### Directory Control

#### Default Behavior

Without `-d` or `-n` flags:
- Analyzes the current directory tree
- Respects `.gitignore` files by default
- Passes `--use-gitignore` to norminette

#### Targeting Specific Directories

```bash
# Analyze only src/ and include/ directories
normelog -d src -d include

# When using -d, gitignore is not automatically applied
normelog -d src --ignore-gitignore
```

#### Excluding Directories

```bash
# Exclude build artifacts and tests
normelog -n build -n tests -n .cache

# Post-filtering: exclusion happens after norminette runs
normelog -d . -n node_modules -n vendor
```

#### Working from Outside Project

```bash
# Analyze a project from any location
normelog -C /path/to/project -a

# Useful for batch processing
for proj in */; do
  normelog -C "$proj" --json > "$proj/norm-report.json"
done
```

### Output Formats

#### Text Output (Default)

The text format provides:

1. **Summary Line**: Correct files / Incorrect files (color-coded)
2. **Error Type Counts**: Aggregated counts per error type
3. **Detailed Listing**: Per-file errors with line, column, and message

```
Correct files: 42
Incorrect files: 8

Error type count:
--------------------
SPACE_BEFORE_TAB         : 3
INVALID_HEADER           : 5
TOO_MANY_FUNCS           : 2
LINE_TOO_LONG            : 12

src/main.c
    INVALID_HEADER (line:   1, col:   1): Missing or invalid header
    LINE_TOO_LONG (line:  42, col:  81): Line exceeds 80 characters
...
```

#### JSON Output

Machine-readable format for integration with other tools:

```json
{
  "ok_files": 42,
  "error_files": 8,
  "total_errors": 22,
  "by_type": {
    "SPACE_BEFORE_TAB": 3,
    "INVALID_HEADER": 5,
    "TOO_MANY_FUNCS": 2,
    "LINE_TOO_LONG": 12
  },
  "files": [
    {
      "file": "src/main.c",
      "errors": [
        {
          "type": "INVALID_HEADER",
          "line": 1,
          "col": 1,
          "message": "Missing or invalid header"
        }
      ]
    }
  ]
}
```

Use with `jq` for powerful queries:

```bash
# Count total errors
normelog --json | jq '.total_errors'

# List files with errors
normelog --json | jq -r '.files[].file'

# Find most common error type
normelog --json | jq -r '.by_type | to_entries | max_by(.value) | .key'

# Export to CSV
normelog --json | jq -r '.files[] | .file as $f | .errors[] |
  [$f, .type, .line, .col, .message] | @csv'
```

## How It Works

### Pipeline Architecture

`normelog` implements a functional pipeline where data flows through transformation stages:

```
┌─────────────────────┐
│  Run norminette     │  Execute norminette with flags
│  (lib/run_norminette)│
└──────────┬──────────┘
           │ Raw norminette output
           ▼
┌─────────────────────┐
│  Exclude Filter     │  Remove excluded directories
│  (lib/exclude.sh)   │
└──────────┬──────────┘
           │ Filtered raw output
           ▼
┌─────────────────────┐
│  Parse Output       │  Convert to structured records
│  (lib/parse.sh)     │
└──────────┬──────────┘
           │ FILE/ERR records
           ▼
┌─────────────────────┐
│  Filter Errors      │  Apply type include/exclude
│  (lib/filter.sh)    │
└──────────┬──────────┘
           │ Filtered records
           ▼
┌─────────────────────┐
│  Compute Stats      │  Aggregate counts
│  (lib/stats.sh)     │
└──────────┬──────────┘
           │ Statistics + Records
           ▼
┌─────────────────────┐
│  Format Output      │  Render as text or JSON
│  (lib/format_*.sh)  │
└─────────────────────┘
```

Each stage:
- Reads from stdin, writes to stdout
- Is implemented as a pure function
- Can be tested independently
- Uses AWK for efficient text processing

### Internal Data Format

Between pipeline stages, data flows as line-oriented records (defined in lib/parse.sh:3-5):

```
FILE <path> STATUS <OK|ERR>
ERR <type> <line> <col> <message>
```

This simple format enables:
- **Stream processing**: No need to load entire dataset into memory
- **AWK efficiency**: Pattern matching and field extraction are trivial
- **Debugging**: Easy to inspect intermediate pipeline stages
- **Composability**: Standard Unix text processing tools work naturally

Example intermediate data:

```
FILE src/main.c STATUS ERR
ERR INVALID_HEADER 1 1 Missing or invalid header
ERR LINE_TOO_LONG 42 81 Line exceeds 80 characters
FILE src/utils.c STATUS OK
FILE src/parser.c STATUS ERR
ERR SPACE_BEFORE_TAB 15 8 Space before tab character
```

### Modular Design

The codebase is organized into focused modules:

```
normelog/
├── bin/
│   └── normelog              # Entrypoint, orchestrates pipeline
├── lib/                      # Core functionality modules
│   ├── env.sh               # Environment setup
│   ├── version.sh           # Version information
│   ├── log.sh               # Logging utilities
│   ├── compat.sh            # Compatibility shims
│   ├── config.sh            # Configuration loading
│   ├── flags.sh             # Command-line parsing
│   ├── run_norminette.sh    # Norminette execution
│   ├── exclude.sh           # Directory exclusion
│   ├── parse.sh             # Output parsing
│   ├── filter.sh            # Error type filtering
│   ├── stats.sh             # Statistics computation
│   ├── format_text.sh       # Text formatter
│   ├── format_json.sh       # JSON formatter
│   ├── update_check.sh      # Update checking (placeholder)
│   └── update_apply.sh      # Update application (placeholder)
├── share/
│   ├── completion/          # Shell completions
│   └── man/                 # Manual pages
├── plugins.d/               # Plugin system (extensible)
└── scripts/                 # Development tools
```

Each module:
- Defines functions with `nl_<module>_*` prefix
- Uses `NL_*` prefix for global variables
- Has no side effects at load time
- Can be sourced independently for testing

## Configuration

### Configuration Files

Configuration is loaded from (in order):

1. `/etc/normelog/config` - System-wide configuration
2. `$XDG_CONFIG_HOME/normelog/config` - User configuration (default: `~/.config/normelog/config`)

Configuration files are sourced as bash scripts and can set any `NL_*` variables.

### Example Configuration

Create `~/.config/normelog/config`:

```bash
# Default to JSON output
NL_OUTPUT=json

# Enable debug mode
NL_DEBUG=1

# Always exclude certain directories
NL_EXCLUDE_DIRS=(build .cache node_modules)

# Use gitignore by default
NL_USE_GITIGNORE=1

# Show all details by default
NL_SHOW_ALL_DETAILS=1
```

### Environment Variables

| Variable | Values | Description |
|----------|--------|-------------|
| `NL_OUTPUT` | `text`, `json` | Force output format |
| `NL_DEBUG` | `0`, `1` | Enable debug messages |
| `XDG_CONFIG_HOME` | path | Base directory for user config |

### Precedence

Configuration is applied in this order (later overrides earlier):

1. Default values (in module code)
2. System config (`/etc/normelog/config`)
3. User config (`$XDG_CONFIG_HOME/normelog/config`)
4. Environment variables
5. Command-line flags

## Advanced Usage

### Combining with Git Hooks

Pre-commit hook example:

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Get list of staged .c and .h files
FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(c|h)$')

if [ -z "$FILES" ]; then
  exit 0
fi

# Run normelog on staged files
normelog --json > /tmp/norm-check.json

# Check if there are errors
ERRORS=$(jq -r '.total_errors' /tmp/norm-check.json)

if [ "$ERRORS" -gt 0 ]; then
  echo "❌ Norminette errors found:"
  jq -r '.files[] | "\(.file): \(.errors | length) error(s)"' /tmp/norm-check.json
  exit 1
fi

echo "✅ No norminette errors"
exit 0
```

### CI/CD Integration

GitHub Actions example:

```yaml
name: Norm Check

on: [push, pull_request]

jobs:
  norm:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install norminette
        run: pip install norminette

      - name: Install normelog
        run: |
          git clone https://github.com/yourusername/normelog.git
          cd normelog && sudo make install

      - name: Run norm check
        run: |
          normelog --json > norm-report.json
          ERRORS=$(jq -r '.total_errors' norm-report.json)
          if [ "$ERRORS" -gt 0 ]; then
            jq . norm-report.json
            exit 1
          fi

      - name: Upload report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: norm-report
          path: norm-report.json
```

### Batch Processing

Process multiple projects:

```bash
#!/bin/bash
# check-all-projects.sh

for project in ~/42/*; do
  if [ -d "$project" ]; then
    echo "Checking $project..."
    normelog -C "$project" --json > "$project/norm-report.json"

    errors=$(jq -r '.total_errors' "$project/norm-report.json")
    if [ "$errors" -eq 0 ]; then
      echo "  ✅ Clean"
    else
      echo "  ❌ $errors error(s)"
    fi
  fi
done
```

### Custom Filtering Scripts

Filter only critical errors:

```bash
#!/bin/bash
# critical-only.sh

CRITICAL_TYPES=(
  "FORBIDDEN"
  "TOO_MANY_FUNCS"
  "INVALID_HEADER"
)

normelog "${CRITICAL_TYPES[@]}" --json | \
  jq 'select(.total_errors > 0)'
```

## Examples

### Basic Usage

```bash
# Simple analysis of current directory
normelog

# Detailed output with all errors listed
normelog -a

# Check specific directories
normelog -d src -d include -a

# Exclude test directories
normelog -n tests -n __tests__ -n spec
```

### Filtering Examples

```bash
# Show only header-related errors
normelog HEADER

# Show formatting errors (space, tab, line length)
normelog SPACE TAB LINE

# Show all errors except function-related ones
normelog -TOO_MANY_FUNCS -TOO_MANY_VARS

# Complex filter: show TOO_* errors but exclude TOO_MANY_VARS_FUNC
normelog TOO -TOO_MANY_VARS_FUNC
```

### JSON Output Examples

```bash
# Generate JSON report
normelog --json > report.json

# Count errors by type
normelog --json | jq '.by_type'

# List only files with errors
normelog --json | jq -r '.files[].file'

# Find files with more than 5 errors
normelog --json | jq -r '.files[] | select(.errors | length > 5) | .file'

# Generate HTML report
normelog --json | jq -r '
  "<html><body><h1>Norm Report</h1>",
  "<p>Total errors: \(.total_errors)</p>",
  (.files[] | "<h2>\(.file)</h2><ul>",
    (.errors[] | "<li>\(.type) at \(.line):\(.col)</li>"),
  "</ul>"),
  "</body></html>"
' > report.html
```

### Advanced Workflows

```bash
# Analyze from outside project directory
normelog -C ~/42/libft -a

# Ignore gitignore and check everything
normelog -I -a

# Combine multiple options
normelog -C ~/42/ft_printf -d src -d include -n tests \
  FORBIDDEN INVALID -a --json > report.json

# Debug pipeline
normelog --debug 2> debug.log
```

## Shell Completions

### Bash

Completions are automatically installed to `/etc/bash_completion.d/` during `make install`.

Manual installation:

```bash
# Copy completion file
sudo cp share/completion/normelog.bash /etc/bash_completion.d/normelog

# Or for user-only
mkdir -p ~/.local/share/bash-completion/completions
cp share/completion/normelog.bash ~/.local/share/bash-completion/completions/normelog

# Reload
source ~/.bashrc
```

### Zsh

Completions are installed to `/usr/share/zsh/site-functions/` during `make install`.

Manual installation:

```bash
# Copy completion file
sudo cp share/completion/_normelog.zsh /usr/share/zsh/site-functions/_normelog

# Or for user-only
mkdir -p ~/.zsh/completions
cp share/completion/_normelog.zsh ~/.zsh/completions/_normelog
echo 'fpath=(~/.zsh/completions $fpath)' >> ~/.zshrc

# Reload
autoload -U compinit && compinit
```

## Development

### Project Structure

The codebase follows strict modularity principles:

- **bin/normelog**: Main entrypoint, sources all modules
- **lib/*.sh**: Self-contained modules with single responsibilities
- **scripts/**: Development utilities (linting, testing, releases)

### Development Commands

```bash
# Lint the entire codebase
make lint

# This runs shellcheck and shfmt on all shell files

# Generate man page from inline docs
make man

# Run normelog locally without installing
./bin/normelog -a

# Create a new release
./scripts/release-tag.sh v1.2.3
```

### Code Style

- **Indentation**: 2 spaces
- **Line length**: 80 characters (flexible for readability)
- **Function naming**: `nl_<module>_<action>` (e.g., `nl_parse_output`)
- **Variable naming**: `NL_*` for globals, lowercase for locals
- **Quote variables**: Always quote expansions unless intentionally splitting
- **Use shellcheck**: All code must pass shellcheck

### Adding New Modules

1. Create `lib/mymodule.sh`
2. Define functions with `nl_mymodule_*` prefix
3. Source in `bin/normelog`
4. Update CLAUDE.md if adding significant functionality

### Testing

Currently, testing is manual. Planned: BATS (Bash Automated Testing System)

```bash
# Run normelog on test fixtures
./bin/normelog -C tests/fixtures/sample-project -a

# Test specific modules (source and call functions)
bash -c 'source lib/parse.sh; echo "test.c: OK!" | nl_parse_output'
```

## Troubleshooting

### norminette not found

```
Error: norminette not found in PATH
Exit code: 127
```

**Solution**: Install norminette:

```bash
pip install --user norminette
# or
pip3 install norminette
```

### Permission denied during installation

```bash
# Install to user directory instead
make install PREFIX=$HOME/.local

# Or use sudo for system-wide installation
sudo make install
```

### Completions not working

**Bash**:
```bash
# Check if completion file exists
ls /etc/bash_completion.d/normelog

# Manually source it
source /etc/bash_completion.d/normelog
```

**Zsh**:
```bash
# Check fpath
echo $fpath

# Rebuild completion cache
rm -f ~/.zcompdump && autoload -U compinit && compinit
```

### Debug output

Enable debug mode to see pipeline execution:

```bash
normelog --debug 2> debug.log
cat debug.log
```

### Unexpected filtering results

Test filters incrementally:

```bash
# Show all error types first
normelog -a

# Add filters one at a time
normelog SPACE -a
normelog SPACE TAB -a
normelog SPACE TAB -LINE_TOO_LONG -a
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Follow** the code style (run `make lint`)
4. **Test** your changes thoroughly
5. **Update** documentation (README, man page, CLAUDE.md)
6. **Commit** with clear messages
7. **Push** to your branch
8. **Open** a Pull Request

### Areas for Contribution

- **Testing**: Implement BATS test suite
- **Plugin system**: Develop plugin loader and example plugins
- **Update mechanism**: Implement GitHub Releases integration
- **Performance**: Optimize AWK scripts for large codebases
- **Features**: Additional output formats, more filtering options
- **Documentation**: More examples, tutorials, video guides

---

**Made with ❤️ for 42 School students**

For bug reports and feature requests, please open an issue on GitHub.
