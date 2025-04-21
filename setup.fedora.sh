NODE_VERSION=22
NVM_VERSION=0.40.2
PYTHON_VERSION=3.12

dnf install gcc-c++
dnf install bpytop
dnf install ripgrep
dnf install xz-devel
yum install bzip2-devel
dnf install openssl-devel
dnf install libsqlite3x-devel
dnf install golang



curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh" | bash
sudo chown -R $USER /usr/local/lib/
sudo chown -R $USER /usr/local/bin/
nvm install $NODE_VERSION
npm i -g yarn tsx ts-node typescript @mistweaverco/kulala-ls

mkdir -p $HOME/Tools/
curl -fL "https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz" | gzip -d > $HOME/Tools/cs
chmod 700 $HOME/Tools/cs
cat 'export $PATH="$HOME/Tools/:$PATH"' > $HOME/.bashrc


rustup component add rustfmt

curl -s "https://get.sdkman.io" | bash

curl -fsSL https://pyenv.run | bash
pyenv install $PYTHON_VERSION 
pyenv global $PYTHON_VERSION 

git clone https://github.com/stryukovsky/my-editor ~/.config/nvim/
 
