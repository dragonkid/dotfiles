if [ -f /bin/zsh ]; then
    echo "zsh has been installed..."
else
	sudo apt-get install zsh
	chsh -s $(which zsh)
	# install oh-my-zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

# install powerlevel9k
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

# install awesome-terminal-fonts
git clone https://github.com/gabrielelana/awesome-terminal-fonts.git /tmp/awesome-terminal-fonts
bash /tmp/awesome-terminal-fonts/install.sh

# install zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

# modify theme
sed -i 's/ZSH_THEME=.*/ZSH_THEME="powerlevel9ki\/powerlevel9k"/' ~/.zshrc
sed -i '/ZSH_THEME=.*/a \\nPOWERLEVEL9K_MODE='awesome-fontconfig'\nPOWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)\nPOWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status virtualenv time)\nPOWERLEVEL9K_VIRTUALENV_BACKGROUND="yellow"\nPOWERLEVEL9K_TIME_FORMAT="%D{\uf017 %H:%M:%S \uf073 %Y.%m.%d}"\nPOWERLEVEL9K_STATUS_VERBOSE=false' ~/.zshrc

source ~/.zshrc
