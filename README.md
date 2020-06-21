
### Install Oh-my-zsh

Make sure zsh has been installed from package manager and then

From [robbyrussell/oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
```bash
make zsh
```

### Install .tmux
From [gpakosz/.tmux](https://github.com/gpakosz/.tmux)
```bash
git clone https://github.com/gpakosz/.tmux.git ~/.tmux && ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf
```

### Install Vim-Plug for Neovim
From [junegunn/vim-plug](https://github.com/junegunn/vim-plug)
```bash
make vim-plug
```

### Kitty
Install kitty from package manager and then 
```bash
make kitty
```

### Nvim
Install neovim from package manager and then
```bash
make neovim
```

## chunkwm for macOS
```bash
brew install chunkwm
brew install koekeishiya/formulae/skhd

# Enable as services
brew services start chunkwm
brew services skbd
```

## Use Mirrors for Repo - Ubuntu
```bash
make ubuntu-mirror
sudo make ubuntu-mirror
```

## Themes

### xfce4 termianl theme
xfce4-terminal themes should be put under /usr/share/xfce4/terminal/colorschemes/

### Meslo Fonts
From [powerline/fonts](https://github.com/powerline/fonts/blob/master/Meslo%20Dotted/Meslo%20LG%20M%20DZ%20Regular%20for%20Powerline.ttf)
