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
command -v sudo >/dev/null || { echo "sudo missing"; exit 1; }
# Try non-interactive sudo first (works for NOPASSWD); fall back to interactive
# cache (needs TTY); fail clearly if neither works.
if ! sudo -n true 2>/dev/null; then
  sudo -v 2>/dev/null || { echo "sudo needs a password and no TTY available — run 'sudo -v' first, then re-run this script"; exit 1; }
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
sudo apt-get update -qq
sudo apt-get install -y -qq \
  zsh stow curl wget ca-certificates build-essential unzip \
  zsh-autosuggestions zsh-syntax-highlighting fzf jq \
  python3 python3-venv python3-pip \
  snapd

# ---------------------------------------------------------------- 3. snap nvim
# Always prefer snap (current stable) over apt (0.9.5 on noble — too old for
# mason-lspconfig 2.x which calls vim.lsp.enable, available from nvim 0.11).
if [ ! -x /snap/bin/nvim ]; then
  LOG "ensuring snapd is running"
  if ! sudo systemctl is-active --quiet snapd 2>/dev/null; then
    sudo systemctl daemon-reload || true
    sudo systemctl enable --now snapd.socket snapd.service 2>&1 | tail -3 || true
  fi
  LOG "waiting for snap seed"
  sudo snap wait system seed.loaded 2>&1 | tail -1 || true
  LOG "installing nvim via snap"
  sudo snap install nvim --classic
fi
# Prepend /snap/bin so the snap nvim wins over any apt-installed nvim that
# happens to live in /usr/bin (the base bootstrap.yml installs that one).
export PATH="/snap/bin:$PATH"

# ---------------------------------------------------------------- 4. clone lifesupport
mkdir -p "$HOME/dev"
if [ ! -d "$REPO_DIR" ]; then
  LOG "cloning lifesupport"
  git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"
git config submodule.recurse true
LOG "syncing submodules"
git submodule update --init --recursive

# ---------------------------------------------------------------- 5. stow + nvim symlink
LOG "stowing zsh + tmux"
ts=$(date +%Y%m%d-%H%M%S)
backup="$HOME/.dotfiles-backup-$ts"
for f in .zshrc .tmux.conf; do
  if [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
    mkdir -p "$backup"
    mv "$HOME/$f" "$backup/"
    LOG "  backed up $f → $backup/"
  fi
done
stow -t "$HOME" zsh tmux

LOG "linking ~/.config/nvim"
mkdir -p "$HOME/.config"
if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  mkdir -p "$backup"
  mv "$HOME/.config/nvim" "$backup/"
  LOG "  backed up ~/.config/nvim → $backup/"
fi
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
