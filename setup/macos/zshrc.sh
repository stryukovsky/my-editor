plugins=(git docker dnf docker-compose golang pip python rust sbt scala zsh-interactive-cd)
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="philips"

zstyle ':omz:update' mode disabled  # disable automatic updates

COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"



source $ZSH/oh-my-zsh.sh

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

. "$HOME/.cargo/env"            # Cargo: For sh/bash/zsh/ash/dash/pdksh

source <(fzf --zsh)
export FZF_DEFAULT_OPTS='--height 40% --tmux center,40% --layout reverse --border top'

alias top="bpytop"
alias htop="bpytop"
alias ff="ranger"
alias mc="ranger"
alias o="xdg-open"
alias activ="source .venv/bin/activate"

# opencode
export PATH="$PATH:$HOME/Tools/" # Coursier binary is stored here
export PATH="$PATH:$HOME/Tools/nvim/bin/" # Neovim
export PATH="$PATH:$HOME/.local/share/coursier/bin/" # Coursier binary is stored here
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin/"
export PATH="$PATH:$GOPATH:$GOBIN"
export PATH="$PATH:$HOME/.foundry/bin"

export PATH=/home/dmitry/.opencode/bin:$PATH

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

