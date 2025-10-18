NODE_VERSION=22
NVM_VERSION=0.40.2

curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh" | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install $NODE_VERSION
npm i -g yarn tsx ts-node typescript 

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. "$HOME/.cargo/env"            
rustup component add rustfmt

curl -s "https://get.sdkman.io" | bash

curl -L https://foundry.paradigm.xyz | bash
git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

curl -L https://foundry.paradigm.xyz | bash
foundryup

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
