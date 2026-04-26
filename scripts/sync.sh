#!/usr/bin/env bash
# Pull lifesupport (and nvim submodule), refresh nvim plugins + mason tools.
# Cross-platform (Mac/Linux/Nix) — only needs git + nvim on PATH.
#
# Usage:
#   sync.sh              # pull only if working tree is clean; else refuse
#   sync.sh --auto-stash # stash local changes, pull, pop (cron-safe)
#
# Exit codes:
#   0  pulled cleanly (or already up-to-date)
#   1  dirty tree and not --auto-stash
#   2  git pull failed (network, conflict, etc.)
#   3  stash pop conflicted — original work preserved in stash, manual fix needed

set -euo pipefail

REPO_DIR="${LIFESUPPORT_DIR:-$HOME/dev/lifesupport}"
LOG() { printf '\033[1;34m[sync]\033[0m %s\n' "$*"; }

[ -d "$REPO_DIR/.git" ] || { echo "no lifesupport repo at $REPO_DIR"; exit 1; }
cd "$REPO_DIR"

mode="${1:-}"

# ---------------------------------------------------------------- 1. local state
# `--ignore-submodules=dirty` ignores auto-updated content inside submodules
# (notably nvim/lazy-lock.json bumped by Lazy! sync); a real submodule pointer
# change still shows. Untracked files at parent level also don't block.
dirty=0
git diff --quiet --ignore-submodules=dirty && \
  git diff --cached --quiet --ignore-submodules=dirty || dirty=1
stashed=0

if [ "$dirty" -eq 1 ]; then
  if [ "$mode" = "--auto-stash" ]; then
    LOG "working tree dirty — stashing"
    git stash push -u -m "sync.sh auto-stash $(date -Iseconds)" >/dev/null
    stashed=1
  else
    LOG "working tree has local changes — refusing pull"
    git status --short
    echo
    echo "  re-run with --auto-stash for cron-safe stash/pull/pop"
    exit 1
  fi
fi

# ---------------------------------------------------------------- 2. pull + submodules
LOG "fetching"
git fetch --quiet
LOG "pulling (ff-only)"
if ! git pull --ff-only --quiet; then
  LOG "pull failed (diverged?)"
  [ "$stashed" -eq 1 ] && git stash pop >/dev/null 2>&1 || true
  exit 2
fi
LOG "syncing submodules"
git submodule update --init --recursive --quiet

# ---------------------------------------------------------------- 3. restore stash
if [ "$stashed" -eq 1 ]; then
  if git stash pop >/dev/null 2>&1; then
    LOG "stash popped cleanly"
  else
    LOG "stash pop conflicted — your changes are still in 'git stash list'"
    exit 3
  fi
fi

# ---------------------------------------------------------------- 4. nvim plugins
# Prefer /snap/bin/nvim (current stable, what bootstrap installs) over whatever
# `nvim` resolves to on PATH — Ubuntu's apt nvim 0.9.5 may be ahead in PATH and
# is too old for the lifesupport config (mason-lspconfig 2.x needs 0.11+).
NVIM=nvim
if [ -x /snap/bin/nvim ]; then
  NVIM=/snap/bin/nvim
fi
# Snap+root needs XDG explicit (see bootstrap.sh comment about /home/root).
if [ "$(id -u)" -eq 0 ]; then
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
  export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
fi

# Run under mise exec if mise is around, so nvim's child processes (mason
# installers spawning npm/python3) inherit mise-managed runtime PATHs.
RUNNER=()
if command -v mise >/dev/null 2>&1; then
  RUNNER=(mise exec --)
fi

LOG "Lazy! sync"
"${RUNNER[@]}" "$NVIM" --headless "+Lazy! sync" "+qa" 2>&1 | tail -3 || true

LOG "MasonToolsUpdateSync"
"${RUNNER[@]}" "$NVIM" --headless "+MasonToolsUpdateSync" "+qa" 2>&1 | tail -5 || true

LOG "done"
