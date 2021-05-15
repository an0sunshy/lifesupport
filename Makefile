install-brew:
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | sh

brew:
	brew bundle

brew-dump:
	brew bundle dump

ideavimrc:
	ln -s -f $(CURDIR)/config/ideavimrc ~/.ideavimrc

kitty:
	-mkdir -p ~/.config/kitty
	ln -s -f $(CURDIR)/config/kitty.conf ~/.config/kitty/kitty.conf
	ln -s -f $(CURDIR)/config/kitty.theme.conf ~/.config/kitty/theme.conf

neovim:
	-mkdir -p  ~/.config/nvim
	ln -s -f $(CURDIR)/config/init.vim ~/.config/nvim/init.vim

tmux:
	git clone https://github.com/gpakosz/.tmux.git ~/.tmux && ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf
	ln -s -f $(CURDIR)/config/tmux.conf.local ~/.tmux.conf.local

ubuntu-mirror:
	apt install apt-transport-https
	sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu/mirror:\/\/mirrors.ubuntu.com\/mirrors.txt/g' /etc/apt/sources.list

vim-plug:
	curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

yabai:
	-mkdir -p ~/.config/yabai
	ln -s -f $(CURDIR)/config/yabairc ~/.config/yabai/yabairc
	chmod +x ~/.config/yabai/yabairc

skhd:
	ln -s -f $(CURDIR)/config/skhdrc ~/.skhdrc
	ln -s -f $(CURDIR)/scripts ~/.scripts

zsh:
	curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
	ln -s -f $(CURDIR)/config/zshrc ~/.zshrc
