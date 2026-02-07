# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="philips"

zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# setup pyenv before zsh plugins loaded 
COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

plugins=(git docker dnf docker-compose golang pip pyenv python rust sbt scala zsh-interactive-cd)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

. "$HOME/.cargo/env"            # Cargo: For sh/bash/zsh/ash/dash/pdksh

export PATH="$PATH:$HOME/Tools/" # Coursier binary is stored here
export PATH="$PATH:$HOME/.local/share/coursier/bin/" # Coursier binary is stored here
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin/"
export PATH="$PATH:$GOPATH:$GOBIN"
export PATH="$PATH:$HOME/.foundry/bin"

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
#
# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
export FZF_DEFAULT_OPTS='--height 40% --tmux center,40% --layout reverse --border top'

alias top="bpytop"
alias ff="ranger"
alias mc="ranger"

function vllm() {
    # Set the path to the virtual environment and the launch script
    VLLM_DIR="$HOME/.config/nvim/ai/vllm"
    LAUNCH_SCRIPT="$VLLM_DIR/launch.sh"

    # Check if the virtual environment directory exists
    if [ ! -d "$VLLM_DIR" ]; then
        echo "Error: Virtual environment directory not found at $VLLM_DIR" >&2
        return 1
    fi

    # Check if the activation script exists
    if [ ! -f "$VLLM_DIR/.venv/bin/activate" ]; then
        echo "Error: Virtual environment activation script not found" >&2
        return 1
    fi

    # Check if the launch script exists
    if [ ! -f "$LAUNCH_SCRIPT" ]; then
        echo "Error: Launch script not found at $LAUNCH_SCRIPT" >&2
        return 1
    fi

    # Activate the virtual environment
    source "$VLLM_DIR/bin/activate"
    echo "Activated venv: $VLLM_DIR"

    # Execute the launch script
    echo "Executing launch script: $LAUNCH_SCRIPT"
    bash "$LAUNCH_SCRIPT"
}
