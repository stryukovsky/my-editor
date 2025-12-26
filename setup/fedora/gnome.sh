gsettings set org.gnome.mutter overlay-key ''
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.desktop.input-sources xkb-options "['altwin:ctrl_rwin']"
gsettings set org.gnome.desktop.wm.keybindings close "['<Alt>F4','<Super>q']"
gsettings --schemadir ~/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas/ $schema_dash_to_dock set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS'
gsettings --schemadir ~/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas/ $schema_dash_to_dock set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 16
gsettings --schemadir ~/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas/ $schema_dash_to_dock set org.gnome.shell.extensions.dash-to-dock intellihide false

gsettings set org.gnome.shell favorite-apps "['Alacritty.desktop', 'org.mozilla.firefox.desktop', 'org.telegram.desktop.desktop', 'md.obsidian.Obsidian.desktop']"
