# dnf copr enable scottames/ghostty
dnf install libubsan libasan lcov fzf zsh neovim golang zlib-devel ripgrep \
gcc-c++ btop make gcc patch zlib-devel bzip2 bzip2-devel readline-devel \
sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz-devel libuuid-devel \
gdbm-libs libnsl2 wireguard-tools postgresql-server postgresql-contrib \
alacritty tmux sassc gtk-murrine-engine \
gnome-extensions-app fd-find libpq-devel uchardet-devel fuse fuse-libs \
audacious pandoc texlive-scheme-full texlive-collection-langcyrillic \
texlive-collection-latexextra gnome-tweaks ranger mpv maven evince atool gpaste \
kitty tree-sitter gpaste-client gpaste-ui python3-devel plantuml ImageMagick \
ImageMagick-devel cmake ninja-build clang clang-tools-extra sushi unrar vmpk -y

sudo dnf install dnf-plugins-core -y

sudo dnf copr enable -y daniel-g-carrasco/wayland-scroll-factor
sudo dnf install wayland-scroll-factor -y

sudo dnf copr enable -y monkeygold/nautilus-open-any-terminal &&
sudo dnf install -y nautilus-open-any-terminal nautilus-python kitty || exit 1


# rpm fusion here
dnf install https://mirror.yandex.ru/fedora/rpmfusion/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirror.yandex.ru/fedora/rpmfusion/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo install -Dm644 "$(dirname "$(realpath "$0")")/rpmfusion-yandex.repo" /etc/dnf/repos.override.d/99-rpmfusion-yandex.repo
dnf config-manager setopt fedora-cisco-openh264.enabled=0
dnf swap ffmpeg-free ffmpeg --allowerasing -y

sudo dnf install 'dnf-command(config-manager)'
sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
sudo dnf install gh -y

dnf install flatpak -y
flatpak install flathub it.mijorus.gearlever -y
flatpak install flathub md.obsidian.Obsidian -y
flatpak install flathub org.telegram.desktop -y
flatpak install flathub com.calibre_ebook.calibre -y
flatpak install flathub io.dbeaver.DBeaverCommunity -y
flatpak install flathub com.sublimehq.SublimeText -y

sudo chown -R $USER /usr/local/lib/
sudo chown -R $USER /usr/local/bin/

sudo mkdir -p /usr/local/share/fonts/
sudo cp -r fonts/*  /usr/local/share/fonts/

