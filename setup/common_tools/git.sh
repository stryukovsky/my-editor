git config --global init.defaultBranch main
git config --global user.email "strukovsky1@gmail.com"
git config --global user.name "Dmitry Stryukovsky"
git config --global status.showUntrackedFiles all
git config --global credential.helper store
# Neovim overrides these via GIT_EDITOR/GIT_SEQUENCE_EDITOR for child processes.
git config --global core.editor nvim
git config --global sequence.editor nvim

