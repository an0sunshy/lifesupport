
### macOS and homebrew

Install homebrew
```bash
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | sh
```

Load from bundle
```bash
brew bundle
```

Dump to bundle
```bash
brew bundle dump
```

### Install Oh-my-zsh

Make sure zsh has been installed from package manager and then

From [robbyrussell/oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
```bash
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
```

Install zsh-completion
```bash
git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh}/custom}/plugins/zsh-completions
```

### Neovim Configuration

Neovim config is managed as a git submodule. After cloning this repo:

```bash
# Configure git to automatically update submodules
git config --global submodule.recurse true

# Initialize and update submodules
git submodule update --init --recursive

# Use stow to symlink neovim config
stow nvim
```

## yabai and skhd for macOS
```bash
brew install koekeishiya/formulae/yabai
brew install koekeishiya/formulae/skhd
make yabai
make skhd

# Enable as services
yabai --install-service
yabai --start-service
skhd --install-service
skhd --start-service
```

## VSCode settings for macOS
```bash
stow --target $HOME/Library/Application\ Support vscode
```

## VSCode settings for remote linux
```bash
stow --target $HOME/.vscode-server/data/Machine vscode
```

## Use Mirrors for Repo - Ubuntu
```bash
apt install apt-transport-https
sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu/mirror:\/\/mirrors.ubuntu.com\/mirrors.txt/g' /etc/apt/sources.list
```

## Themes

### xfce4 termianl theme
xfce4-terminal themes should be put under /usr/share/xfce4/terminal/colorschemes/

### Font: JetBrainsMono
From [nerd-fonts](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/JetBrainsMono)

## Voice-to-Text (macOS Apple Silicon only)

Local speech-to-text using [parakeet-mlx](https://github.com/senstella/parakeet-mlx). Runs as a LaunchAgent daemon, controlled via the `voice` CLI. Transcribed text is sent to the active tmux pane and clipboard.

### Setup

```bash
# One-time: create venv, install deps, download model
voice setup

# Install LaunchAgent daemon (starts on login)
voice install
```

### Usage

In tmux:

| Key | Action |
|---|---|
| **F9** | Start/stop recording |
| **Shift+F9** | Toggle auto/review mode |
| **F10** | Retry last transcription |

Two modes:
- ✏️ **Review** (default) — text sent to pane + clipboard, you review before submitting
- 🚀 **Auto** — same but also presses Enter

Status bar indicators:

| Icon | Meaning |
|---|---|
| 💤 | Idle |
| ⏺️ 12s ▅ | Recording (duration + audio level) |
| ⏳ | Transcribing |
| ✅ / ⚠️ | Done / error (clears after 3s) |
| 🟢 / 🔴 | Server up / down |
| ✏️ / 🚀 | Review / auto mode |

Last recording is saved to `~/.cache/voice-server/last-recording.wav` as a safety net.

### Commands

| Command | Purpose |
|---|---|
| `voice setup [--force]` | Create venv, install deps, download model |
| `voice install` | Install as macOS LaunchAgent |
| `voice uninstall` | Remove LaunchAgent and clean up |
| `voice start` | Start the voice server |
| `voice stop` | Stop the voice server |
| `voice restart` | Restart the voice server (clears failure count) |
| `voice log` | Tail the server log |
| `voice toggle [pane_id]` | Toggle recording (tmux F9 handler) |
| `voice retry [pane_id]` | Re-transcribe last recording (tmux F10) |
| `voice status [state\|mode]` | Show server/recording status |

`voice-server` and `voice-watchdog` still exist as separate scripts (Python server and LaunchAgent wrapper respectively).

### Troubleshooting

- Server log: `~/Library/Logs/voice-server/voice-server.log`
- Toggle debug log: `~/.cache/voice-toggle.log`
- Tail log: `voice log`
- Ping test: `echo "ping" | socat -t 5 - UNIX-CONNECT:~/.cache/voice-server.sock`
- If watchdog gives up after retries, run `voice restart`

### Requirements

- macOS with Apple Silicon
- Homebrew packages: `socat`, `ffmpeg`
- Python managed via `uv`
