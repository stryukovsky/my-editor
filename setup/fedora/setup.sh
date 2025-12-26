dnf copr enable dejan/lazygit -y
dnf install libubsan libasan lcov fzf zsh neovim  golang zlib-devel ripgrep gcc-c++ bpytop make gcc patch zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel libuuid-devel gdbm-libs libnsl2 wireguard-tools postgresql-server postgresql-contrib alacritty tmux  wl-clipboard sassc gtk-murrine-engine gnome-themes-extra  gnome-extensions-app fd-find lazygit libpq-devel uchardet-devel fuse fuse-libs audacious texlive-scheme-full texlive-collection-langcyrillic texlive-collection-latexextra gnome-tweaks ranger mpv -y

# rpm fusion here
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf swap ffmpeg-free ffmpeg --allowerasing -y

dnf install flatpak -y
flatpak install it.mijorus.gearlever -y

sudo chown -R $USER /usr/local/lib/
sudo chown -R $USER /usr/local/bin/

sudo mkdir -p /usr/local/share/fonts/
sudo cp -r fonts/*  /usr/local/share/fonts/

