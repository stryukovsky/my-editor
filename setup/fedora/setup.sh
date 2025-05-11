dnf install libubsan libasan lcov fzf zsh neovim  golang zlib-devel ripgrep gcc-c++ bpytop make gcc patch zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel libuuid-devel gdbm-libs libnsl2 wireguard-tools postgresql-server postgresql-contrib alacritty tmux -y

sudo chown -R $USER /usr/local/lib/
sudo chown -R $USER /usr/local/bin/

mkdir -p $HOME/Tools/
curl -fL "https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz" | gzip -d > $HOME/Tools/cs
chmod 700 $HOME/Tools/cs

PYTHON_VERSION=3.12
curl -fsSL https://pyenv.run | bash
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"
pyenv install $PYTHON_VERSION 
pyenv global $PYTHON_VERSION 


cp fonts/0xProto/*.ttf ~/.local/share/fonts/

desktop-file-install setup/fedora/alacritty/Alacritty.desktop
cp setup/fedora/alacritty/Alacritty.svg /usr/share/pixmaps/Alacritty.svg
update-desktop-database
