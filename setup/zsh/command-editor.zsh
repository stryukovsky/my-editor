# Keep ordinary external shells' editor unchanged.
if [[ -n $NVIM ]]; then
  unsetopt flowcontrol # Let Ctrl-S reach ZLE instead of pausing terminal output.
  autoload -Uz edit-command-line
  zle -N edit-command-line
  function _nvim_edit_command_line() {
    local -x NVIM_COMMAND_SHELL_PID=$$
    zle edit-command-line
  }
  zle -N _nvim_edit_command_line
  zstyle ':zle:*edit*command*line*' editor "${${(%):-%N}:A:h:h:h}/bin/terminal-command-editor"
  bindkey -M emacs '^F' _nvim_edit_command_line
  bindkey -M emacs '^S' _nvim_edit_command_line
  bindkey -M viins '^F' _nvim_edit_command_line
  bindkey -M viins '^S' _nvim_edit_command_line
  bindkey -M vicmd '^F' _nvim_edit_command_line
  bindkey -M vicmd '^S' _nvim_edit_command_line
fi
