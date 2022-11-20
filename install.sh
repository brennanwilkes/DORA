#!/usr/bin/env bash

sudo locale-gen en_US.UTF-8

#Install Node
node -v || {
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
	source $HOME/.bashrc
	export NVM_DIR="$HOME/.nvm"
	source $HOME/.nvm/nvm.sh
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
	nvm install v18.3.0
	nvm use v18.3.0
}

#Install GH
gh --version || {
	type -p curl >/dev/null || sudo apt install curl -y
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	sudo apt update
	sudo apt install gh -y
}

git config --global diff.renameLimit 999999
git config --global rev-list.renameLimit 999999
git config --global merge.renameLimit 999999


ps -aux | grep -v install.sh | grep -Ee '\.(sh|js)' | sed 's/\t/ /g' | tr -s ' ' | cut -d' ' -f2 | xargs -n1 -I {} kill -9 {}
