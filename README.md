
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

### Install Vim-Plug for Neovim
From [junegunn/vim-plug](https://github.com/junegunn/vim-plug)
```bash
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
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
