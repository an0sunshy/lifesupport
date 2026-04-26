#!/usr/bin/env bash
# Idempotent dev-host bootstrap.
# Pre-reqs (manual):
#   - SSH key for github.com:an0sunshy is in place (~/.ssh/id_ed25519 or agent forwarding)
#   - User has sudo (will prompt)
# Re-runnable: every step is a no-op if already done.

set -euo pipefail

REPO_URL="git@github.com:an0sunshy/lifesupport.git"
REPO_DIR="$HOME/dev/lifesupport"
LOG() { printf '\033[1;34m[bootstrap]\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- 1. sanity
LOG "checking prereqs"
command -v git >/dev/null || { echo "git missing — install before running"; exit 1; }
# Define a SUDO wrapper: empty when running as root, "sudo" otherwise. Lets
# this script work both on personal hosts (xiao + sudo) and on Proxmox /
# bare-metal hosts where the only login is root.
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  command -v sudo >/dev/null || { echo "sudo missing (and not running as root)"; exit 1; }
  # Try non-interactive sudo first (works for NOPASSWD); fall back to
  # interactive cache (needs TTY); fail clearly if neither works.
  if ! sudo -n true 2>/dev/null; then
    sudo -v 2>/dev/null || { echo "sudo needs a password and no TTY available — run 'sudo -v' first, then re-run this script"; exit 1; }
  fi
  SUDO="sudo"
fi

# Snap remaps $HOME for confined apps; when running as root, snap nvim ends up
# looking at /home/root/.config/nvim instead of /root/.config/nvim and silently
# starts with no config (Lazy/Mason commands then fail with E492). Setting the
# XDG vars explicitly forces nvim to the real config/data dirs.
if [ "$(id -u)" -eq 0 ]; then
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
  export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
fi

# Verify github SSH auth (don't fail — agent forwarding may be in play).
# `< /dev/null` matters: when this script is piped via `bash -s`, ssh would
# otherwise read the remainder of the script as its own stdin and silently
# truncate the run.
ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes -T git@github.com < /dev/null 2>&1 | \
    grep -q "successfully authenticated" \
  || echo "warning: github SSH auth not confirmed (proceeding anyway)"

# ---------------------------------------------------------------- 2. apt
LOG "installing apt packages"
$SUDO apt-get update -qq
$SUDO apt-get install -y -qq \
  zsh stow curl wget ca-certificates build-essential unzip \
  zsh-autosuggestions zsh-syntax-highlighting fzf jq \
  python3 python3-venv python3-pip \
  snapd

# ---------------------------------------------------------------- 3. snap nvim
# Always prefer snap (current stable) over apt (0.9.5 on noble — too old for
# mason-lspconfig 2.x which calls vim.lsp.enable, available from nvim 0.11).
if [ ! -x /snap/bin/nvim ]; then
  LOG "ensuring snapd is running"
  if ! $SUDO systemctl is-active --quiet snapd 2>/dev/null; then
    $SUDO systemctl daemon-reload || true
    $SUDO systemctl enable --now snapd.socket snapd.service 2>&1 | tail -3 || true
  fi
  LOG "waiting for snap seed"
  $SUDO snap wait system seed.loaded 2>&1 | tail -1 || true
  # On a freshly-installed snapd (e.g. PVE / Debian first-time install), the
  # daemon advertises seed.loaded before the API is fully ready, and the
  # first snap install often dies with "context canceled". Retry with backoff.
  LOG "installing nvim via snap"
  for attempt in 1 2 3 4 5; do
    if $SUDO snap install nvim --classic; then
      break
    fi
    [ "$attempt" -eq 5 ] && { echo "snap install failed after 5 attempts"; exit 1; }
    LOG "  snap install attempt $attempt failed; retrying in 10s"
    sleep 10
  done
fi
# Prepend /snap/bin so the snap nvim wins over any apt-installed nvim that
# happens to live in /usr/bin (the base bootstrap.yml installs that one).
export PATH="/snap/bin:$PATH"

# ---------------------------------------------------------------- 4. clone lifesupport
mkdir -p "$HOME/dev"
if [ ! -d "$REPO_DIR" ]; then
  LOG "cloning lifesupport"
  git clone "$REPO_URL" "$REPO_DIR"
else
  LOG "lifesupport already present — fetching + ff"
  git -C "$REPO_DIR" fetch --quiet
  # --ff-only refuses if local commits diverge — surfaces conflicts loudly
  # rather than silently rebasing host-local edits.
  if ! git -C "$REPO_DIR" pull --ff-only --quiet 2>&1; then
    LOG "  WARNING: lifesupport pull failed (local edits or diverged?). Continuing with current state."
  fi
fi
cd "$REPO_DIR"
git config submodule.recurse true
LOG "syncing submodules"
# Tracks whatever commit the parent repo pins, not upstream tip — keeps the
# nvim config version coherent with the parent commit you pulled.
git submodule update --init --recursive

# ---------------------------------------------------------------- 5. stow + nvim symlink
LOG "stowing zsh + tmux"
ts=$(date +%Y%m%d-%H%M%S)
backup="$HOME/.dotfiles-backup-$ts"
# Move out of the way anything that exists and isn't already pointing at the
# canonical lifesupport location. Handles both regular files (first-time
# install) and stale symlinks pointing at a legacy ~/lifesupport/ checkout.
ensure_clear() {
  local target="$1"
  local desired="$2"
  [ -e "$target" ] || [ -L "$target" ] || return 0
  if [ -L "$target" ] && [ "$(readlink -f "$target" 2>/dev/null)" = "$desired" ]; then
    return 0
  fi
  mkdir -p "$backup"
  mv "$target" "$backup/" 2>/dev/null || rm -rf "$target"
  LOG "  cleared $target → $backup/"
}
ensure_clear "$HOME/.zshrc" "$REPO_DIR/zsh/.zshrc"
ensure_clear "$HOME/.tmux.conf" "$REPO_DIR/tmux/.tmux.conf"
stow -t "$HOME" zsh tmux

LOG "linking ~/.config/nvim"
mkdir -p "$HOME/.config"
ensure_clear "$HOME/.config/nvim" "$REPO_DIR/nvim"
[ -L "$HOME/.config/nvim" ] || ln -s "$REPO_DIR/nvim" "$HOME/.config/nvim"

# ---------------------------------------------------------------- 6. oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  LOG "installing oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null
fi
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" ]; then
  LOG "cloning zsh-completions plugin"
  git clone --depth 1 https://github.com/zsh-users/zsh-completions \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-completions"
fi

# ---------------------------------------------------------------- 7. mise + node
if [ ! -x "$HOME/.local/bin/mise" ]; then
  LOG "installing mise"
  curl -fsSL https://mise.run | sh
fi
export PATH="$HOME/.local/bin:$PATH"
LOG "ensuring node lts"
mise use -g node@lts >/dev/null

# ---------------------------------------------------------------- 8. claude code
LOG "installing claude code"
mise exec -- npm install -g @anthropic-ai/claude-code >/dev/null

# ---------------------------------------------------------------- 9. zshrc-local-pre
if [ ! -f "$HOME/.zshrc-local-pre" ]; then
  LOG "writing ~/.zshrc-local-pre (PATH + Debian plugin paths)"
  cat > "$HOME/.zshrc-local-pre" <<'EOF'
# Per-host overrides for Linux (Ubuntu/Debian).
# Sourced early by ~/.zshrc, before oh-my-zsh init.

case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
# Prepend /snap/bin (not append) so snap-installed nvim wins over apt's older one.
case ":$PATH:" in *":/snap/bin:"*) ;; *) [ -d /snap/bin ] && export PATH="/snap/bin:$PATH" ;; esac

[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
EOF
fi

# ---------------------------------------------------------------- 10. nvim plugins
# Run snap nvim explicitly via full path, under `mise exec` so its child
# processes (mason installers that spawn npm/python3) inherit the
# mise-managed runtime PATHs.
LOG "installing/updating nvim plugins (Lazy! sync) — may take a minute"
mise exec -- /snap/bin/nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -5 || true

LOG "installing mason tools (MasonToolsUpdateSync — blocks until done)"
mise exec -- /snap/bin/nvim --headless "+MasonToolsUpdateSync" "+qa" 2>&1 | tail -15 || true

# ---------------------------------------------------------------- 11. shell
if [ "$(getent passwd "$USER" | cut -d: -f7)" != "/usr/bin/zsh" ]; then
  LOG "default shell is not zsh — run: chsh -s /usr/bin/zsh"
fi

LOG "done"
LOG "next: open a new shell (zsh), verify: type mise claude nvim"
