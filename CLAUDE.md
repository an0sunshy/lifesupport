# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles and system configuration (lifesupport). Configs are symlinked from this repo into `~/.config/`, `~/`, etc.

Key directories: `tmux/`, `ghostty/`, `zsh/`, `nvim/`, `bin/`, `scripts/`

## Onboarding a host

Hosts are managed from `~/dev/ansible-scripts`, where the `[dev]` inventory group lists every machine that should run lifesupport's dotfiles + sync cron. Excluded from `[dev]`: hypervisors and pure servers (e.g. `helios`, `supernova`) that don't need an interactive dev environment.

**Two install levels** controlled by `BOOTSTRAP_LEVEL` in `scripts/bootstrap.sh`:

- **`full`** (default) — interactive dev workstation. Installs apt essentials, snap nvim, stows dotfiles, mise + node@lts, claude-code, runs Lazy/Mason for nvim plugins.
- **`minimal`** — utility/server host. Installs apt essentials + cron, stows dotfiles only. No snap, no mise, no claude, no nvim plugins. `sync.sh` will auto-skip its nvim refresh phase on these hosts.

**Three-step flow for a new host** (target = inventory hostname):

```
# 1. Add the host to the [dev] group in inventories/hosts.
# 2. Bootstrap (full by default):
ansible-playbook playbooks/bootstrap-dev.yml -e target_host=<host>
#    or minimal:
ansible-playbook playbooks/bootstrap-dev.yml -e target_host=<host> -e bootstrap_level=minimal
# 3. Install the 5-minute sync cron:
ansible-playbook playbooks/lifesupport-sync-cron.yml -e target_host=<host> -e enable_cron=true
```

**Sudo prerequisite.** `bootstrap.sh` needs sudo for apt/snap. On hosts where the user lacks NOPASSWD, ansible runs the script without a TTY and `sudo -v` would hang forever waiting for a password — so the script now fails fast with a clear error in that case. Either grant NOPASSWD on the bootstrap user, or warm the sudo cache (`sudo -v` interactively) right before running ansible. Hosts where ansible connects as root (e.g. helios, supernova) skip this entirely.

**Sync cron behavior.** `sync.sh` runs every 5 minutes and exits cleanly without pulling if the working tree is dirty, HEAD was committed in the last 30 min, or any tracked file was edited in the last 30 min — pause-if-active is the default. A successful pull writes `~/.cache/lifesupport-sync.last-success`; absence > 7 days emits a loud `WARN`. Logs self-rotate at 256k. The expensive nvim plugin refresh only runs when upstream HEAD actually moved, and only if mise or system npm is available — so minimal hosts produce clean logs.

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
