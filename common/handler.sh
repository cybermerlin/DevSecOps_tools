#!/usr/bin/env sh
set -eu

set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"; set -u
${RED+:} . "${ROOT}/common/colors.sh"


# usage: handler <command> <description> [indent_level]
handler() {
  # debug "handler() called with arg=$1" >&2

  _cmd="$1"
  _description="${2:-$_cmd}"
  _lvl="${3:-0}"

  info "[ started ]: $_description... [${_cmd}]" "${_lvl}"

  sleep 1
#   TODO: when on install a package who ask me something - I will not see that and it will be freeze
  if _out=$(eval "$_cmd 2>&1"); then
    success "[ finished ]: $_description... [${_cmd}]" "${_lvl}"
  else
    error "[ failed ]: $_description... [${_cmd}] :-{\n\t${_out}" "${_lvl}"
    return 1
  fi
}
