install-brew:
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | sh

brew:
	brew bundle

brew-dump:
	brew bundle dump

ubuntu-mirror:
	apt install apt-transport-https
	sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu/mirror:\/\/mirrors.ubuntu.com\/mirrors.txt/g' /etc/apt/sources.list

vim-plug:
	curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

install-omz:
	curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh

zsh-completion:
	git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh}/custom}/plugins/zsh-completions
