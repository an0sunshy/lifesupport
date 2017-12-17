#!/bin/sh

# Install homebrew for macOS
if [[ `uname` == 'Darwin' ]]; then
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        brew install $(cat pkg) 
        brew cask install google-chrome item2
        cp ./fonts/* ~/Library/Fonts/
        brew cleanup
fi

# configrue Oh-my-zsh
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
rm ~/.zshrc
ln -s ./zshrc ~/.zshrc
source ~/.zshrc

# configure nvim
mkdir ~/.config/nvim
ln -s ./init.vim ~/.config/nvim/init.vim
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
nvim +PlugInstall! +PlugClean! +qall
python ~/.config/nvim/plugged/YouCompleteMe/install.py --clang-completer --go-completer
