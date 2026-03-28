
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

Local speech-to-text using [parakeet-mlx](https://github.com/senstella/parakeet-mlx). Runs as a LaunchAgent daemon, triggered via tmux F9 keybinding. Transcribed text is copied to clipboard.

### Setup

```bash
# One-time: create venv, install deps, download model
bin/voice-setup

# Install LaunchAgent daemon (starts on login)
bin/voice-install
```

### Usage

In tmux, press **F9** to start recording, **F9** again to stop. Transcription is copied to clipboard.

### Scripts

| Script | Purpose |
|---|---|
| `voice-setup` | One-time venv + model setup |
| `voice-install` | Install as LaunchAgent |
| `voice-uninstall` | Remove LaunchAgent |
| `voice-restart` | Restart the daemon |
| `voice-toggle` | Tmux F9 handler (start/stop recording) |
| `voice-server` | Python server (unix socket, managed by watchdog) |
| `voice-watchdog` | Retry wrapper (3 attempts, then macOS notification) |

### Troubleshooting

- Logs: `~/Library/Logs/voice-server/voice-server.log`
- Toggle debug log: `~/.cache/voice-toggle.log`
- Ping test: `echo "ping" | socat -t 5 - UNIX-CONNECT:~/.cache/voice-server.sock`
- If watchdog gives up after 3 retries, run `voice-restart`

### Requirements

- macOS with Apple Silicon
- Homebrew packages: `socat`, `ffmpeg`
- Python managed via `uv`
