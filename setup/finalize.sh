#!/bin/bash

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install sbt
sdk install java 17.0.15-tem 
# On x86-64 (aka AMD64)
# On ARM64
foundryup

# Get the machine hardware name
ARCH=$(uname -m)

echo "Installing coursier. Detected Architecture: $ARCH"
if [[ "$ARCH" == "x86_64" || "$ARCH" == "i386" || "$ARCH" == "i686" ]]; then
  curl -fL "https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz" | gzip -d > cs
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" || "$ARCH" == "arm"* ]]; then
  curl -fL "https://github.com/VirtusLab/coursier-m1/releases/latest/download/cs-aarch64-pc-linux.gz" | gzip -d > cs
else
  echo "Unknown architecture detected. Cannot install coursier"
fi

chmod +x cs
./cs setup

cs install metals
rm cs
