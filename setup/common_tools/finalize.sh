#!/bin/bash

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install sbt
sdk install java 17.0.15-tem 
sdk install gradle
foundryup

