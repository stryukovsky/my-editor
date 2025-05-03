export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

zstyle ':omz:update' mode disabled  # disable automatic updates
plugins=(git docker dnf docker-compose golang pip pyenv python rust sbt scala zsh-interactive-cd)

source $ZSH/oh-my-zsh.sh
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi
export ARCHFLAGS="-arch $(uname -m)"

export PATH="$PATH:/opt/homebrew/bin/"
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

. "$HOME/.cargo/env"            # Cargo: For sh/bash/zsh/ash/dash/pdksh

export PATH="$PATH:$HOME/Library/Application Support/Coursier/bin"
export PATH="$PATH:$HOME/Tools"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
