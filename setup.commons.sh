NODE_VERSION=22
NVM_VERSION=0.40.2
PYTHON_VERSION=3.12

curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh" | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install $NODE_VERSION
npm i -g yarn tsx ts-node typescript @mistweaverco/kulala-ls

mkdir -p $HOME/Tools/
curl -fL "https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz" | gzip -d > $HOME/Tools/cs
chmod 700 $HOME/Tools/cs

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. "$HOME/.cargo/env"            
rustup component add rustfmt

curl -s "https://get.sdkman.io" | bash

curl -fsSL https://pyenv.run | bash
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

pyenv install $PYTHON_VERSION 
pyenv global $PYTHON_VERSION 

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

curl -L https://foundry.paradigm.xyz | bash
curl -fsSL https://deno.land/install.sh | sh

nvim
