#!/usr/bin/env sh
set -eu
set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"; set -u
${RED+:} . "${ROOT}/common/colors.sh"


installer() {
  debug "installer() called with arg=$1"

  _s=$1
  _pkg=${2:-$1}

  if ! command -v "$_s" >/dev/null 2>&1; then
    error "[${_s}] not found." 5
    info "Installing [${_s}]…" 5
    if command -v apt >/dev/null 2>&1; then
        sudo apt update -qq && sudo apt install -y "$_pkg"
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -qq && sudo apt-get install -y "$_pkg"
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "$_pkg"
    elif command -v brew >/dev/null 2>&1; then
        brew install "$_pkg"
    else
        error "no supported package-manager found – please install [${_s}] manually" 5 >&2
        return 1
    fi
    echo $?
  else
    success "[${_s}] are exists."
  fi
}


# Determine if script is executed or sourced
if [ "${0##*/}" = "installer.sh" ]; then
    debug "installer.sh called from=${0##*/} with args=${*}" >&2
    installer "$@"
fi
