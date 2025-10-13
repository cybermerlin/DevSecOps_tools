#!/bin/sh
set -eu


handler() {
    local _cmd="$1"
    local _description="${2:-$_cmd}"
    local _lvl="${3:-}"
    [ -z "$_lvl" ] || _lvl=$(printf "%${_lvl}s")
    
    # start_spinner "$_description"
    
    info "${_lvl}[ started ]: $_description..."
    if eval "$_cmd"; then
        # stop_spinner
        success "${_lvl}[ finished ]: $_description"
    else
        # stop_spinner
        error "${_lvl}[ failed ]: $_description"
    fi
}
