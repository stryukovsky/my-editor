gsettings set org.gnome.mutter overlay-key ''
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.desktop.input-sources xkb-options "['altwin:ctrl_rwin']"
gsettings set org.gnome.desktop.wm.keybindings close "['<Alt>F4','<Super>q']"
gsettings set org.gnome.desktop.interface clock-format '24h'

gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click false
gsettings set org.gnome.desktop.peripherals.pointingstick scroll-method 'on-button-down'
gsettings set org.gnome.desktop.peripherals.pointingstick accel-profile 'flat'
gsettings set org.gnome.desktop.peripherals.pointingstick speed -1.0
gsettings set org.gnome.GPaste save-history false
gsettings set org.gnome.desktop.interface enable-hot-corners false

# PdfCraft's AppImage desktop integration installs pdfcraft.desktop.
if [[ -f ${XDG_DATA_HOME:-$HOME/.local/share}/applications/pdfcraft.desktop || -f /usr/share/applications/pdfcraft.desktop ]]; then
  xdg-mime default pdfcraft.desktop application/pdf
else
  printf 'Skipping PDF default: install PdfCraft desktop integration first.\n'
fi

gsettings set org.gnome.desktop.sound allow-volume-above-100-percent 'true'

gsettings set org.gnome.desktop.a11y.magnifier lens-mode false
gsettings set org.gnome.desktop.a11y.magnifier mouse-tracking 'centered'
gsettings set org.gnome.desktop.a11y.magnifier focus-tracking 'none'
gsettings set org.gnome.desktop.a11y.magnifier caret-tracking 'none'
gsettings set org.gnome.desktop.a11y.magnifier screen-position 'full-screen'
gsettings set org.gnome.desktop.a11y.magnifier scroll-at-edges true
gsettings set org.gnome.desktop.a11y.magnifier mag-factor 2.0

# Install the Nautilus Open in Kitty action from this dotfiles checkout.
fedora_setup_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# The Lenovo Copilot key emits Super+Shift+F23. Preserve other custom shortcuts.
python3 "$fedora_setup_dir/../../bin/kitty-top" --install-shortcut

# Keep a persistent copy of the desktop wallpaper for both light and dark mode.
wallpaper_source="$fedora_setup_dir/../../MyBackground.jpg"
if [[ -f $wallpaper_source ]]; then
  wallpaper_path="${XDG_DATA_HOME:-$HOME/.local/share}/backgrounds/MyBackground.jpg"
  install -Dm644 -- "$wallpaper_source" "$wallpaper_path"
  wallpaper_uri=$(python3 -c 'import pathlib, sys; print(pathlib.Path(sys.argv[1]).resolve().as_uri())' "$wallpaper_path")
  gsettings set org.gnome.desktop.background picture-uri "$wallpaper_uri"
  gsettings set org.gnome.desktop.background picture-uri-dark "$wallpaper_uri"
  gsettings set org.gnome.desktop.background picture-options 'zoom'
fi

nautilus_extension_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nautilus-python/extensions"
mkdir -p -- "$nautilus_extension_dir"
# Match the system Ghostty module; the provider guards duplicate registrations.
ln -sfn -- "$fedora_setup_dir/nautilus/kitty.py" "$nautilus_extension_dir/ghostty.py"
echo 'Installed Open in Kitty. Run nautilus -q, then reopen Files to load it.'

# Use permanent paths, never an AppImage's temporary /tmp/.mount_* executable.
install_app_autostart() {
  local desktop_id=$1 name=$2 appimage=$3
  shift 3
  local executable='' candidate
  if [[ -x $appimage ]]; then
    executable=$appimage
  else
    for candidate in "$@"; do
      executable=$(command -v "$candidate") || continue
      break
    done
  fi
  if [[ -z $executable || ! -x $executable ]]; then
    printf 'Skipping %s autostart: app not installed.\n' "$name"
    return 0
  fi

  local autostart_dir="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
  local exec_quoted=$executable
  exec_quoted=${exec_quoted//\\/\\\\}
  exec_quoted=${exec_quoted//\"/\\\"}
  exec_quoted=${exec_quoted//\$/\\\$}
  exec_quoted=${exec_quoted//\`/\\\`}
  exec_quoted=${exec_quoted//%/%%}
  mkdir -p -- "$autostart_dir"
  cat > "$autostart_dir/$desktop_id.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=$name
TryExec=$executable
Exec="$exec_quoted"
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP
  printf 'Installed %s autostart.\n' "$name"
}

# Match LocalSend's own filename to avoid launching it twice.
install_app_autostart localsend_app LocalSend "$HOME/AppImages/localsend.appimage" localsend_app localsend
install_app_autostart hiddify Hiddify "$HOME/AppImages/hiddify.appimage" hiddify Hiddify
unset -f install_app_autostart
