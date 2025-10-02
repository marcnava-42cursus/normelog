# normelog

Portable helper around `norminette` to summarize and filter errors, designed for simple download from GitHub Releases (no .deb packaging required).

## Install

- Download the latest `normelog` from Releases
- Make it executable and place it in your `PATH`:

```
chmod +x normelog
sudo mv normelog /usr/local/bin/
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

