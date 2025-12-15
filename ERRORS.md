# ERRORS.md

This document lists known issues in the normelog codebase.

**Note**: Issues that have been fixed are moved to `FIXED.md`.

---

## Current Issues

No known open issues at this time.

---

## Notes (Feature Dependencies)

Some features require optional external tools:

- `--diff`: requires `python3` (parsing JSON baselines)
- `--watch`: requires `inotifywait` (Linux) or `fswatch` (macOS)
- `--update`: requires `curl`
- `--parallel`: benefits from GNU `parallel` (falls back to `xargs -P` when available)

---

## Summary

**Total Issues Remaining**: 0

---
