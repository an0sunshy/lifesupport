
### Install Oh-my-zsh
From [robbyrussell/oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

### Install .tmux
From [gpakosz/.tmux](https://github.com/gpakosz/.tmux)
```bash
cd
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
```

### Install Vim-Plug for Neovim
From [junegunn/vim-plug](https://github.com/junegunn/vim-plug)
```bash
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```


## Themes

### xfce4 termianl theme
xfce4-terminal themes should be put under /usr/share/xfce4/terminal/colorschemes/

### iterm2 theme
From [mhartington/oceanic-next-iterm](https://github.com/mhartington/oceanic-next-iterm)

### Meslo Fonts
From [powerline/fonts](https://github.com/powerline/fonts/blob/master/Meslo%20Dotted/Meslo%20LG%20M%20DZ%20Regular%20for%20Powerline.ttf)

## chunkwm for macOS
```bash
brew install chunkwm
brew install koekeishiya/formulae/skhd

# Enable as services
brew services start chunkwm
brew services skbd
```
