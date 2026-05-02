#!/usr/bin/env bash
# Pull lifesupport (and nvim submodule), refresh nvim plugins + mason tools.
# Cross-platform (Mac/Linux/Nix) — only needs git + nvim on PATH.
#
# Usage:
#   sync.sh              # pull only if working tree is clean and idle; else pause
#   sync.sh --auto-stash # stash local changes, pull, pop (manual override)
#
# Cron-safe by default: a dirty tree, recent file edits, or recent commits all
# cause a clean exit-0 "paused" rather than blocking. A stale-skip warning
# fires when the last successful sync is older than $LIFESUPPORT_SYNC_STALE_DAYS
# (default 7) so a host can't silently drift forever.
#
# Env knobs:
#   LIFESUPPORT_DIR              repo path (default $HOME/dev/lifesupport)
#   LIFESUPPORT_SYNC_MIN_IDLE    skip if any tracked file's mtime, or HEAD's
#                                commit time, is within this many minutes
#                                (default 30)
#   LIFESUPPORT_SYNC_STALE_DAYS  loud-warn if last success is older than this
#                                many days (default 7)
#   LIFESUPPORT_SYNC_LOG_MAX     truncate log file to this many bytes at end
#                                of run (default 262144 = 256k)
#
# Exit codes:
#   0  pulled cleanly, already up-to-date, or paused (active edits / dirty)
#   1  hard failure (no repo, --auto-stash with broken stash pop, etc.)
#   2  git pull failed (network, diverged, etc.)
#   3  --auto-stash: stash pop conflicted, original work preserved in stash

set -euo pipefail

# ----------------------------------------------------------- 0. environment fix
# Cron on some systems leaves $HOME empty, which makes snap nvim resolve XDG
# dirs under /home/.local and fail with "permission denied". Backfill from
# getent before anything reads $HOME.
if [ -z "${HOME:-}" ]; then
  HOME="$(getent passwd "$(id -un)" | cut -d: -f6)"
  export HOME
fi

REPO_DIR="${LIFESUPPORT_DIR:-$HOME/dev/lifesupport}"
MIN_IDLE_MIN="${LIFESUPPORT_SYNC_MIN_IDLE:-30}"
STALE_DAYS="${LIFESUPPORT_SYNC_STALE_DAYS:-7}"
LOG_MAX_BYTES="${LIFESUPPORT_SYNC_LOG_MAX:-262144}"
SUCCESS_SENTINEL="$HOME/.cache/lifesupport-sync.last-success"
LOG_FILE="${LIFESUPPORT_SYNC_LOG:-$HOME/.cache/lifesupport-sync.log}"

LOG()  { printf '\033[1;34m[sync]\033[0m %s %s\n' "$(date -Iseconds)" "$*"; }
WARN() { printf '\033[1;33m[sync WARN]\033[0m %s %s\n' "$(date -Iseconds)" "$*" >&2; }

truncate_log() {
  # Self-rotate the log so a 5-min cadence can't grow it without bound. Only
  # acts on $LOG_FILE if it exists and exceeds the cap. Safe to call from any
  # exit path.
  [ -f "$LOG_FILE" ] || return 0
  local size
  size=$(wc -c <"$LOG_FILE" 2>/dev/null || echo 0)
  if [ "$size" -gt "$LOG_MAX_BYTES" ]; then
    tail -c "$LOG_MAX_BYTES" "$LOG_FILE" >"$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
  fi
}
trap truncate_log EXIT

[ -d "$REPO_DIR/.git" ] || { echo "no lifesupport repo at $REPO_DIR"; exit 1; }
cd "$REPO_DIR"

mode="${1:-}"

# ------------------------------------------------------------ 1. stale check
# If we haven't recorded a success recently, surface it loudly. We still try
# to sync this run — the warning is just so silent drift can't hide.
if [ -f "$SUCCESS_SENTINEL" ]; then
  last_success_epoch=$(stat -c %Y "$SUCCESS_SENTINEL" 2>/dev/null || stat -f %m "$SUCCESS_SENTINEL" 2>/dev/null || echo 0)
  now_epoch=$(date +%s)
  age_days=$(( (now_epoch - last_success_epoch) / 86400 ))
  if [ "$age_days" -gt "$STALE_DAYS" ]; then
    WARN "no successful sync in $age_days days (threshold: $STALE_DAYS) — host may be drifting"
  fi
fi

# ------------------------------------------------------------ 2. local state
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
    LOG "paused: working tree has local changes (re-run with --auto-stash to override)"
    exit 0
  fi
fi

# ------------------------------------------------------------ 3. idle check
# Skip if any tracked file was modified, or HEAD was committed, within the
# last MIN_IDLE_MIN minutes. Proxy for "user is actively editing" — catches
# saved-but-not-staged edits and very recent local commits without needing
# editor introspection. Skipped for --auto-stash (manual override).
if [ "$mode" != "--auto-stash" ] && [ "$MIN_IDLE_MIN" -gt 0 ]; then
  threshold_epoch=$(( $(date +%s) - MIN_IDLE_MIN * 60 ))
  head_epoch=$(git log -1 --format=%ct 2>/dev/null || echo 0)
  if [ "$head_epoch" -gt "$threshold_epoch" ]; then
    LOG "paused: HEAD committed within last $MIN_IDLE_MIN min"
    exit 0
  fi
  # Newest mtime among tracked files. `git ls-files -z | xargs -0 stat` is
  # portable enough; we cap at the first hit older than threshold by sorting.
  newest=$(git ls-files -z | xargs -0 stat -c %Y 2>/dev/null | sort -nr | head -1 || echo 0)
  if [ -n "$newest" ] && [ "$newest" -gt "$threshold_epoch" ]; then
    LOG "paused: tracked file modified within last $MIN_IDLE_MIN min"
    exit 0
  fi
fi

# ------------------------------------------------------------ 4. pull
pre_head=$(git rev-parse HEAD)
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
post_head=$(git rev-parse HEAD)

# ------------------------------------------------------------ 5. restore stash
if [ "$stashed" -eq 1 ]; then
  if git stash pop >/dev/null 2>&1; then
    LOG "stash popped cleanly"
  else
    LOG "stash pop conflicted — your changes are still in 'git stash list'"
    exit 3
  fi
fi

# ------------------------------------------------------------ 6. record success
mkdir -p "$(dirname "$SUCCESS_SENTINEL")"
touch "$SUCCESS_SENTINEL"

# ------------------------------------------------------------ 7. nvim refresh
# Only run when HEAD actually moved — the Lazy/Mason refresh hits many remote
# registries and is too expensive to run on every cron tick. On a no-op pull
# we exit early here.
if [ "$pre_head" = "$post_head" ]; then
  LOG "no upstream changes — skipping nvim refresh"
  LOG "done"
  exit 0
fi

# Prefer /snap/bin/nvim (current stable, what bootstrap installs) over whatever
# `nvim` resolves to on PATH — Ubuntu's apt nvim 0.9.5 may be ahead in PATH and
# is too old for the lifesupport config (mason-lspconfig 2.x needs 0.11+).
NVIM=nvim
if [ -x /snap/bin/nvim ]; then
  NVIM=/snap/bin/nvim
fi
# Snap's confined view of $HOME breaks for both root and (rarer) $HOME-empty
# cron envs. Set XDG explicitly in either case.
if [ "$(id -u)" -eq 0 ] || [ -n "${LIFESUPPORT_FORCE_XDG:-}" ]; then
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
