gsettings set org.gnome.mutter overlay-key ''
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.desktop.input-sources xkb-options "['altwin:ctrl_rwin']"
gsettings set org.gnome.desktop.wm.keybindings close "['<Alt>F4','<Super>q']"
gsettings set org.gnome.desktop.interface clock-format '24h'

gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click false
gsettings set org.gnome.GPaste save-history false
gsettings set org.gnome.desktop.interface enable-hot-corners false

gsettings set org.gnome.desktop.sound allow-volume-above-100-percent 'true'

gsettings set org.gnome.desktop.a11y.magnifier lens-mode false
gsettings set org.gnome.desktop.a11y.magnifier mouse-tracking 'centered'
gsettings set org.gnome.desktop.a11y.magnifier focus-tracking 'none'
gsettings set org.gnome.desktop.a11y.magnifier caret-tracking 'none'
gsettings set org.gnome.desktop.a11y.magnifier screen-position 'full-screen'
gsettings set org.gnome.desktop.a11y.magnifier scroll-at-edges true
gsettings set org.gnome.desktop.a11y.magnifier mag-factor 2.0
