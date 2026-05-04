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
# dirs under /home/.local and fail with "permission denied". Backfill before
# anything reads $HOME. `getent` is Linux-only; on macOS fall back to `dscl`,
# then to tilde expansion (~user), so this works on every supported platform.
if [ -z "${HOME:-}" ]; then
  _u="$(id -un)"
  if command -v getent >/dev/null 2>&1; then
    HOME="$(getent passwd "$_u" | cut -d: -f6)"
  elif command -v dscl >/dev/null 2>&1; then
    HOME="$(dscl . -read "/Users/$_u" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
  fi
  : "${HOME:=$(eval echo "~$_u")}"
  export HOME
  unset _u
fi

REPO_DIR="${LIFESUPPORT_DIR:-$HOME/dev/lifesupport}"
MIN_IDLE_MIN="${LIFESUPPORT_SYNC_MIN_IDLE:-30}"
STALE_DAYS="${LIFESUPPORT_SYNC_STALE_DAYS:-7}"
LOG_MAX_BYTES="${LIFESUPPORT_SYNC_LOG_MAX:-262144}"
SUCCESS_SENTINEL="$HOME/.cache/lifesupport-sync.last-success"
LOG_FILE="${LIFESUPPORT_SYNC_LOG:-$HOME/.cache/lifesupport-sync.log}"

# `date -Iseconds` is GNU-only; the explicit format works on macOS BSD date too.
NOW() { date '+%Y-%m-%dT%H:%M:%S%z'; }
LOG()  { printf '\033[1;34m[sync]\033[0m %s %s\n' "$(NOW)" "$*"; }
WARN() { printf '\033[1;33m[sync WARN]\033[0m %s %s\n' "$(NOW)" "$*" >&2; }

# `stat -c %Y` is GNU; macOS BSD stat needs `-f %m`. Wrap the difference once.
mtime_of() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null; }

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
  last_success_epoch=$(mtime_of "$SUCCESS_SENTINEL" || echo 0)
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
  # Newest mtime among tracked files. We `stat` each file via mtime_of so the
  # GNU/BSD difference is hidden. `xargs -0` keeps the pipeline NUL-safe for
  # paths with spaces; the inner shell loops because mtime_of is a function.
  newest=$(git ls-files -z | xargs -0 -I{} bash -c 'stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null' _ {} | sort -nr | head -1)
  if [ -n "$newest" ] && [ "$newest" -gt "$threshold_epoch" ]; then
    LOG "paused: tracked file modified within last $MIN_IDLE_MIN min"
    exit 0
  fi
fi

# ------------------------------------------------------------ 4. pull
# Capture stderr so a transient SSH/network failure produces a single tidy
# log line instead of leaking raw "fatal: Could not read from remote" output.
# A missed fetch isn't fatal — the next 5-min tick will retry.
pre_head=$(git rev-parse HEAD)
LOG "fetching"
if ! fetch_err=$(git fetch --quiet 2>&1); then
  WARN "fetch failed (transient?): $(printf '%s' "$fetch_err" | tr '\n' ' ' | head -c 200)"
  [ "$stashed" -eq 1 ] && git stash pop >/dev/null 2>&1 || true
  exit 2
fi
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

# Locate mise. In interactive zsh `mise` is a shell function defined by the
# user's rc, so `command -v mise` returns false in cron — we must look at
# known binary paths. Without mise, mason installers can't find npm/python3
# at install time and produce a flood of E492-style noise; we'd rather skip
# the nvim refresh cleanly than ship broken plugins.
MISE_BIN=""
for candidate in \
    "${MISE_BIN_PATH:-}" \
    "$HOME/.local/bin/mise" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/mise/bin/mise" \
    "/usr/local/bin/mise" \
    "/opt/homebrew/bin/mise"; do
  if [ -n "$candidate" ] && [ -x "$candidate" ]; then
    MISE_BIN="$candidate"; break
  fi
done

# Skip the (expensive, network-heavy) nvim plugin/mason refresh if neither
# mise nor a system npm is around — without one of them mason's installers
# fail loudly. The dotfile-sync side is already done by this point; this is
# purely cosmetic for hosts that aren't full dev workstations.
if [ -z "$MISE_BIN" ] && ! command -v npm >/dev/null 2>&1; then
  LOG "skip nvim refresh: no mise or system npm available on this host"
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

# Run under mise exec when available so nvim's child processes (mason
# installers spawning npm/python3) inherit mise-managed runtime PATHs.
RUNNER=()
if [ -n "$MISE_BIN" ]; then
  RUNNER=("$MISE_BIN" exec --)
fi

LOG "Lazy! sync"
"${RUNNER[@]}" "$NVIM" --headless "+Lazy! sync" "+qa" 2>&1 | tail -3 || true

LOG "MasonToolsUpdateSync"
"${RUNNER[@]}" "$NVIM" --headless "+MasonToolsUpdateSync" "+qa" 2>&1 | tail -5 || true

LOG "done"
