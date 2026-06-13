#!/bin/bash

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install sbt
sdk install java 17.0.15-tem 
# On x86-64 (aka AMD64)
# On ARM64
foundryup

