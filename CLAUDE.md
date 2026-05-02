# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles and system configuration (lifesupport). Configs are symlinked from this repo into `~/.config/`, `~/`, etc.

Key directories: `tmux/`, `ghostty/`, `zsh/`, `nvim/`, `bin/`

## Cross-Platform Compatibility

This setup runs on **macOS** (primary, Ghostty terminal), **Linux/WSL**, and **remote SSH servers**. The dotfiles are deployed to remote machines too — not just the local workstation. Remote servers may not have Ghostty, may use older tmux versions, and typically connect through nested tmux over SSH with `xterm-256color`.

**Default expectation: every change works on macOS and Linux.** When a change can't trivially be made portable, stop and either flag the tradeoff to the user or ask for an explicit single-platform scope before proceeding. Do not ship Linux-only or macOS-only behavior silently.

- **tmux config**: All settings must work on both macOS and Linux tmux. Avoid macOS-only features unless guarded. Terminal features (`xterm-ghostty`, `xterm-256color`) must degrade gracefully when terminfo is missing.
- **Shell scripts** (`bin/`, `scripts/`): Use `#!/usr/bin/env bash` for portability. Avoid GNU-only flags that BSD userland rejects — common offenders: `date -Iseconds`, `stat -c`, `getent`, `readlink -f`, `sed -i ''` vs `sed -i`, `xargs -r`, `find -printf`. Either use POSIX-only forms or wrap the difference in a small helper (see `scripts/sync.sh` `mtime_of` for an example). Escape sequences that target Ghostty (e.g., OSC 9;4 progress) should be harmless no-ops on terminals that don't support them.
- **Ghostty config**: Linux Ghostty may not support all macOS-specific options (e.g., `macos-titlebar-style`, `macos-option-as-alt`). These are fine since Ghostty ignores unknown platform options.
- **zsh config**: Already handles platform differences via `uname` checks. Follow the existing pattern.
- **tmux passthrough / escape sequences**: When sending sequences through tmux (DCS passthrough with `allow-passthrough`), always handle the non-tmux case too (`$TMUX` check).
- **Cron / system-integration scripts**: Even when the cron itself only runs on Linux, the script invoked by cron is also run manually on macOS — keep the script itself portable.
- **Regression policy**: If a fix isn't straightforward to make cross-platform, inform the user rather than shipping something that breaks the other platform.
