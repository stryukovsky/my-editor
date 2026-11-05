#!/usr/bin/env bash
# Fedora setup: requires Bash 4+, GNU sort, Coursier, Java, curl and unzip.
# Prefetch Metals and the presentation-compiler bridge for one Scala version.
#
# Metals does not load bridges from a folder you pick. It resolves them with
# Coursier (FileCache), same default cache as `cs`:
#   ${COURSIER_CACHE:-$HOME/.cache/coursier}
# `cs fetch` writes the Maven layout there. Leave the jars in that cache.
# If COURSIER_CACHE is set, start Neovim with the same value.
#
# Tables below match Metals 1.6.9 (org.scalameta:metals_2.13:1.6.9):
#   built-in presentation compiler: Scala 2.13.18 (no extra mtags)
#   Scala 2 and older Scala 3: org.scalameta:mtags_<scala>:<metals>
#   Scala 3 >= 3.3.4-RC1: org.scala-lang:scala3-presentation-compiler_3:<scala>
#   Scala 2 compiler plugin: org.scalameta:semanticdb-scalac_<scala>  (<= 4.17.4)
set -euo pipefail

METALS_RELEASE=1.6.9
BUILTIN_SCALA=2.13.18
SCALAMETA_VERSION=4.17.4

declare -A REMOVED=(
  ["2.13.1"]="0.11.10"
  ["2.13.2"]="0.11.10"
  ["2.13.3"]="0.11.12"
  ["2.13.4"]="1.0.1"
  ["2.13.5"]="1.2.2"
  ["2.13.6"]="1.3.0"
  ["2.12.9"]="0.11.10"
  ["2.12.10"]="0.11.12"
  ["2.12.11"]="1.2.2"
  ["3.0.0"]="0.11.10"
  ["3.0.1"]="0.11.10"
  ["3.0.2"]="0.11.12"
  ["3.1.0"]="1.3.0"
  ["3.1.1"]="1.3.0"
  ["3.1.2"]="1.3.0"
  ["3.2.0"]="1.3.0"
  ["3.2.1"]="1.3.0"
  ["3.2.2-RC1"]="0.11.10"
  ["3.3.0-RC1"]="0.11.10"
  ["3.3.0-RC2"]="0.11.11"
  ["3.3.0-RC3"]="0.11.12"
  ["3.3.0-RC4"]="0.11.12"
  ["3.3.0-RC5"]="0.11.12"
  ["3.3.0-RC6"]="0.11.12"
  ["3.3.1-RC1"]="0.11.12"
  ["3.3.1-RC2"]="0.11.12"
  ["3.3.1-RC3"]="0.11.12"
  ["3.3.1-RC4"]="1.0.0"
  ["3.3.1-RC5"]="1.0.0"
  ["3.3.1-RC6"]="1.0.1"
  ["3.3.1-RC7"]="1.0.1"
  ["3.3.0"]="1.2.2"
  ["3.3.2-RC1"]="1.2.2"
  ["3.3.2-RC2"]="1.2.2"
  ["3.3.2-RC3"]="1.2.2"
  ["3.1.3"]="1.3.2"
  ["2.12.12"]="1.3.3"
  ["2.12.13"]="1.3.3"
  ["2.12.14"]="1.3.3"
  ["2.12.15"]="1.3.3"
  ["2.12.16"]="1.3.5"
  ["2.12.17"]="1.6.4"
  ["2.13.7"]="1.3.3"
  ["2.13.8"]="1.3.3"
  ["2.13.9"]="1.3.3"
  ["2.13.10"]="1.3.3"
  ["2.13.11"]="1.3.5"
  ["2.13.12"]="1.5.1"
  ["2.13.13"]="1.6.2"
  ["2.13.14"]="1.6.3"
  ["3.2.2"]="1.3.5"
  ["3.3.2"]="1.3.5"
  ["3.3.1"]="1.5.1"
  ["3.3.3"]="1.5.1"
  ["2.11.12"]="1.6.7"
)

declare -A MTAGS_INTERFACES=(
  ["3.5.0"]="1.3.1"
  ["3.4.3"]="1.3.0"
  ["3.4.2"]="1.3.0"
  ["3.4.1"]="1.2.1"
  ["3.4.0"]="1.2.0"
)

usage() {
  cat << EOF
Usage: metals_for_scala [scala-version]

Prompts for a Scala version when no argument is given, then downloads
Metals ${METALS_RELEASE} and the bridge that version needs into the Coursier
cache. Project dependencies are not fetched.

Examples:
  metals_for_scala
  metals_for_scala 2.12.21
  metals_for_scala 3.3.8
EOF
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
  usage
  exit 0
fi

if ! command -v cs >/dev/null 2>&1; then
  echo "cs is not on PATH" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is not on PATH" >&2
  exit 1
fi

detect_metals_version() {
  local bin
  bin=$(command -v metals || true)
  if [[ -z $bin ]]; then
    return 0
  fi
  unzip -p "$bin" META-INF/coursier/lock-file 2>/dev/null \
    | sed -n 's|.*/metals_2\.13/\([^/]*\)/metals_2\.13-.*|\1|p' \
    | head -n 1
}

# Release versions only (4.9.9 <= 4.17.4). Pre-releases are not compared here.
version_le() {
  [[ $(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n 1) == "$1" ]]
}

# Scala 3 presentation compiler shipped inside the compiler since 3.3.4-RC1.
# GNU sort -V orders 3.3.4 before 3.3.4-RC1, so this is not sort -V.
is_stable_scala3_pc() {
  local v=$1 core maj min pat
  [[ $v == 3.* ]] || return 1
  core=${v%%-*}
  IFS=. read -r maj min pat <<< "$core"
  [[ $maj =~ ^[0-9]+$ && $min =~ ^[0-9]+$ && $pat =~ ^[0-9]+$ ]] || return 1
  if (( maj != 3 )); then
    (( maj > 3 ))
    return
  fi
  if (( min > 3 )); then
    return 0
  fi
  if (( min < 3 )); then
    return 1
  fi
  if (( pat > 4 )); then
    return 0
  fi
  if (( pat < 4 )); then
    return 1
  fi
  if [[ $v == 3.3.4 ]]; then
    return 0
  fi
  if [[ $v =~ ^3\.3\.4-RC([0-9]+) ]]; then
    (( BASH_REMATCH[1] >= 1 ))
    return
  fi
  if [[ $v =~ ^3\.3\.4-M ]]; then
    return 1
  fi
  return 0
}

fetch() {
  echo "==> cs fetch $*"
  cs fetch "$@"
}

semanticdb_version() {
  local scala=$1 xml best ver
  xml=$(curl -fsSL "https://repo1.maven.org/maven2/org/scalameta/semanticdb-scalac_${scala}/maven-metadata.xml") \
    || return 1
  best=""
  while read -r ver; do
    [[ $ver =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
    if version_le "$ver" "$SCALAMETA_VERSION"; then
      if [[ -z $best ]] || ! version_le "$ver" "$best"; then
        best=$ver
      fi
    fi
  done < <(sed -n 's:.*<version>\([^<]*\)</version>:\1:p' <<< "$xml")
  [[ -n $best ]] || return 1
  printf '%s\n' "$best"
}

scala_version=${1:-}
if [[ -z $scala_version ]]; then
  read -r -p "Scala version (for example 2.12.21): " scala_version
fi

# shellcheck disable=SC2001
scala_version=$(printf '%s' "$scala_version" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [[ ! $scala_version =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z]+)*$ ]]; then
  echo "Not a Scala version: ${scala_version:-<empty>}" >&2
  exit 1
fi

installed=$(detect_metals_version || true)
if [[ -n $installed && $installed != "$METALS_RELEASE" ]]; then
  echo "Installed Metals is ${installed}. This script fetches bridges for Metals ${METALS_RELEASE}." >&2
  echo "The fallback tables in this script match ${METALS_RELEASE} only." >&2
  exit 1
fi

cache=${COURSIER_CACHE:-$HOME/.cache/coursier}
echo "Coursier cache (where Metals looks up bridges): ${cache}"

extra_repos=()
if [[ $scala_version == *NIGHTLY* ]]; then
  extra_repos+=(-r scala-nightlies)
fi
if [[ $scala_version == 3.4.* ]]; then
  extra_repos+=(
    -r "https://central.sonatype.com/repository/maven-snapshots/"
    -r "https://oss.sonatype.org/content/repositories/snapshots/"
  )
fi

echo "Fetching Metals ${METALS_RELEASE}"
fetch "org.scalameta:metals_2.13:${METALS_RELEASE}"

if [[ $scala_version == "$BUILTIN_SCALA" ]]; then
  echo "Scala ${scala_version} presentation compiler is embedded in Metals ${METALS_RELEASE}. No mtags download."
elif is_stable_scala3_pc "$scala_version"; then
  echo "Fetching Scala 3 presentation compiler for ${scala_version}"
  force=(
    -V "org.scala-lang:scala3-library_3:${scala_version}"
    -V "org.scala-lang:scala3-compiler_3:${scala_version}"
    -V "org.scala-lang:tasty-core_3:${scala_version}"
  )
  if [[ -n ${MTAGS_INTERFACES[$scala_version]:-} ]]; then
    force+=(-V "org.scalameta:mtags-interfaces:${MTAGS_INTERFACES[$scala_version]}")
  fi
  fetch "${extra_repos[@]}" "${force[@]}" \
    "org.scala-lang:scala3-presentation-compiler_3:${scala_version}"
  echo "Fetching Scala 3 library sources for ${scala_version}"
  fetch "${extra_repos[@]}" --sources "org.scala-lang:scala3-library_3:${scala_version}"
else
  bridge_metals=${REMOVED[$scala_version]:-$METALS_RELEASE}
  if [[ $bridge_metals != "$METALS_RELEASE" ]]; then
    echo "Scala ${scala_version} was dropped from Metals ${METALS_RELEASE}. Using mtags from Metals ${bridge_metals}."
  else
    echo "Fetching mtags for Scala ${scala_version}"
  fi
  if [[ $scala_version == 2.* ]]; then
    fetch "${extra_repos[@]}" \
      -V "org.scala-lang:scala-library:${scala_version}" \
      -V "org.scala-lang:scala-compiler:${scala_version}" \
      -V "org.scala-lang:scala-reflect:${scala_version}" \
      "org.scalameta:mtags_${scala_version}:${bridge_metals}"
    echo "Fetching scala-library sources for ${scala_version}"
    fetch --sources "org.scala-lang:scala-library:${scala_version}"
    if semver=$(semanticdb_version "$scala_version"); then
      echo "Fetching semanticdb-scalac ${semver} for Scala ${scala_version}"
      fetch "org.scalameta:semanticdb-scalac_${scala_version}:${semver}"
    else
      echo "No semanticdb-scalac <= ${SCALAMETA_VERSION} published for Scala ${scala_version}." >&2
      echo "Completions can still work from mtags. Worksheets that need the compiler plugin will not." >&2
    fi
  else
    fetch "${extra_repos[@]}" \
      -V "org.scala-lang:scala3-library_3:${scala_version}" \
      -V "org.scala-lang:scala3-compiler_3:${scala_version}" \
      -V "org.scala-lang:tasty-core_3:${scala_version}" \
      "org.scalameta:mtags_${scala_version}:${bridge_metals}"
    echo "Fetching Scala 3 library sources for ${scala_version}"
    fetch "${extra_repos[@]}" --sources "org.scala-lang:scala3-library_3:${scala_version}"
  fi
fi

# Builtin Scala 2.13.18 still needs the compiler plugin and library sources.
if [[ $scala_version == "$BUILTIN_SCALA" ]]; then
  echo "Fetching scala-library sources for ${scala_version}"
  fetch --sources "org.scala-lang:scala-library:${scala_version}"
  if semver=$(semanticdb_version "$scala_version"); then
    echo "Fetching semanticdb-scalac ${semver} for Scala ${scala_version}"
    fetch "org.scalameta:semanticdb-scalac_${scala_version}:${semver}"
  fi
fi

echo
echo "Done. Bridges are in ${cache}."
echo "Metals reads that cache. Do not copy the jars somewhere else."

