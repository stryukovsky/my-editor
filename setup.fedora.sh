dnf install gcc-c++ -y
dnf install bpytop -y
dnf install ripgrep -y
dnf install libsqlite3x-devel -y
dnf install zlib-devel -y
dnf install golang -y
dnf install neovim  -y
dnf install zsh -y
dnf install fzf -y
dnf install lcov -y
yum install libasan libubsan -y
dnf install make gcc patch zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel libuuid-devel gdbm-libs libnsl2 -y

sudo chown -R $USER /usr/local/lib/
sudo chown -R $USER /usr/local/bin/
