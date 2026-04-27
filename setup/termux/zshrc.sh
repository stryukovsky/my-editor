export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="philips"
zstyle ':omz:update' mode disabled  # disable automatic updates
COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
plugins=(git)
source $ZSH/oh-my-zsh.sh

pullvault() {
  cd /storage/emulated/0/Documents/
  if [ -d "/storage/emulated/0/Documents/my-vault" ]; then
      echo "Directory exists"
  else
      echo "Directory does not exist"
      git clone git@github.com:stryukovsky/my-vault.git
  fi
  cd my-vault
  git pull
}

pushvault() {
  pullvault
  git add .
  git commit -m "chore: update"
  git push

}

