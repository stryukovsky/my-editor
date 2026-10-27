#!/usr/bin/env bash
# Run as your regular user. Only system package updates use sudo.
set -o pipefail

usage() {
  cat <<'HELP'
Usage: update.sh [--dry-run] [--rpmfusion-direct] [GROUP ...]
No groups: update all detected groups. Missing tools are skipped.
Groups: system flatpak node rust foundry python jvm shell go
--rpmfusion-direct: bypass RPM Fusion metalinks using the Yandex mirror.
SDKMAN and system package managers may ask for confirmation.
Node stays on the default Node major; npm globals stay within semver ranges.
HELP
}

dry_run=false
rpmfusion_direct=false
groups=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --rpmfusion-direct) rpmfusion_direct=true ;;
    -h|--help) usage; exit 0 ;;
    system|flatpak|node|rust|foundry|python|jvm|shell|go) groups+=("$arg") ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
  esac
done
if (( EUID == 0 )); then
  echo 'Run this script as your regular user, without sudo.' >&2
  exit 2
fi
((${#groups[@]})) || groups=(system flatpak node rust foundry python jvm shell go)
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
export PATH="$HOME/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:$HOME/.foundry/bin:$HOME/Tools/coursier/bin:$HOME/Tools:$PATH"
failed=()
run() {
  printf '\n==> %s\n' "$1"
  local label=$1
  shift
  if "$dry_run"; then
    printf '  '; printf '%q ' "$@"; printf '\n'
  else
    (set -e; "$@")
    local status=$?
    if (( status != 0 )); then
      failed+=("$label")
      printf 'FAILED: %s (continuing)\n' "$label" >&2
    fi
  fi
}
has() { command -v "$1" >/dev/null 2>&1; }

update_system() {
  local -a options=()
  if "$rpmfusion_direct"; then
    # Read each repo's shipped baseurl, including commented defaults. Override
    # only this DNF invocation; preserve enabled states and signature checks.
    local overrides
    overrides=$(python3 - <<'PYREPOS'
import configparser
import pathlib
import re
from urllib.parse import urlsplit

for path in sorted(pathlib.Path("/etc/yum.repos.d").glob("rpmfusion*.repo")):
    text = re.sub(r"(?m)^#(baseurl=)", r"\1", path.read_text())
    config = configparser.ConfigParser(interpolation=None)
    config.read_string(text)
    for section in config.sections():
        url = config.get(section, "baseurl", fallback="").strip()
        parsed = urlsplit(url)
        if parsed.hostname != "download1.rpmfusion.org":
            continue
        for key, value in (
            ("metalink", ""), ("mirrorlist", ""),
            ("baseurl", "https://mirror.yandex.ru/fedora/rpmfusion" + parsed.path),
        ):
            print(f"--setopt={section}.{key}={value}")
PYREPOS
    ) || return
    if [[ -z $overrides ]]; then
      echo 'No RPM Fusion default baseurls found; refusing direct-mirror mode.' >&2
      return 1
    fi
    mapfile -t options <<< "$overrides"
  fi
  run 'Fedora packages' sudo dnf upgrade --refresh "${options[@]}"
}

update_node() {
  local tag installer previous major
  # Resolve the release at runtime rather than pinning an aging installer.
  tag=$(curl -fsSL --connect-timeout 15 --max-time 60 https://api.github.com/repos/nvm-sh/nvm/releases/latest |
    python3 -c 'import json,re,sys; t=json.load(sys.stdin)["tag_name"]; assert re.fullmatch(r"v\d+\.\d+\.\d+",t); print(t)')
  installer=$(mktemp)
  trap 'rm -f -- "$installer"' EXIT
  curl -fsSL --connect-timeout 15 --max-time 120 "https://raw.githubusercontent.com/nvm-sh/nvm/$tag/install.sh" -o "$installer"
  PROFILE=/dev/null bash "$installer"
  # nvm and SDKMAN are sourced without nounset, which they do not support.
  source "$NVM_DIR/nvm.sh" --no-use
  previous=$(nvm version default)
  if [[ $previous != v* ]]; then
    echo 'No default Node version. Set one with nvm alias default <version>.' >&2
    return 1
  fi
  major=${previous%%.*}
  nvm install "$major" --reinstall-packages-from="$previous"
  nvm alias default "$(nvm version "$major")"
  nvm use default
  nvm install-latest-npm
  npm update --global
}
update_sdkman() {
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
  sdk selfupdate
  sdk update
  sdk upgrade
}
update_go() {
  local binary module
  for binary in "${GOBIN:-${GOPATH:-$HOME/go}/bin}"/*; do
    [[ -f $binary && -x $binary ]] || continue
    module=$(go version -m "$binary" | awk '$1 == "path" {print $2}')
    [[ -n $module && $module != command-line-arguments ]] || continue
    # Use the binary's actual module path, including its major-version suffix.
    run "Go: ${binary##*/}" env GOBIN="${binary%/*}" go install "$module@latest"
  done
}

for group in "${groups[@]}"; do
  case "$group" in
    system)
      if has dnf; then
        update_system
        (( $? == 0 )) || failed+=("Fedora repository preparation")
      fi
      ;;
    flatpak)
      if has flatpak; then
        run 'Flatpak user apps/runtimes' flatpak update --user
        run 'Flatpak system apps/runtimes' flatpak update --system
      fi
      ;;
    node)
      [[ ! -s $NVM_DIR/nvm.sh ]] || run 'nvm, default Node major, npm and global packages' update_node
      ;;
    rust)
      if has rustup; then
        run 'rustup itself' rustup self update
        run 'Rust toolchains and components' rustup update
      fi
      ;;
    foundry)
      if has foundryup; then
        run 'foundryup itself' foundryup --update
        run 'Foundry stable toolchain' foundryup
      fi
      ;;
    python)
      if has uv; then
        run 'uv itself (standalone installation)' env UV_NO_MODIFY_PATH=1 uv self update
        run 'uv-installed tools' uv tool upgrade --all
      fi
      has pipx && run 'pipx-installed tools' pipx upgrade-all
      ;;
    jvm)
      [[ ! -s $SDKMAN_DIR/bin/sdkman-init.sh ]] || run 'SDKMAN and SDKs (interactive; may upgrade majors)' update_sdkman
      has cs && run 'Coursier applications' cs update
      ;;
    shell)
      [[ ! -f ${ZSH:-$HOME/.oh-my-zsh}/tools/upgrade.sh ]] ||
        run 'Oh My Zsh' env ZSH="${ZSH:-$HOME/.oh-my-zsh}" zsh "${ZSH:-$HOME/.oh-my-zsh}/tools/upgrade.sh"
      ;;
    go)
      has go && update_go
      ;;
  esac
done
if ((${#failed[@]})); then
  printf '\nFailed updates:\n'; printf '  %s\n' "${failed[@]}"
  exit 1
fi
printf '\nDone. Open a new shell to load updated tools.\n'
