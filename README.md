# normelog

Portable helper around `norminette` to summarize and filter errors. Modular layout at repo root suitable for GitHub Releases.

## Install

- Download the release asset and place a symlink to the entrypoint:

```
chmod +x bin/normelog
sudo ln -sf "$PWD/bin/normelog" /usr/local/bin/normelog
```

## Usage

Run in a repository with C sources:

```
normelog [options] [ERROR_TYPE...]
```

Examples:
- `normelog` — summary and error counts
- `normelog -a` — detailed per-file listing
- `normelog SPACE TAB` — only spacing/tab related errors

See `normelog -h` for full help.
