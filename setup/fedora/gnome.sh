gsettings set org.gnome.mutter overlay-key ''
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
gnome-extensions list --enabled | xargs -n1 gnome-extensions disable
