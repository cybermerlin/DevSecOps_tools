#!/usr/bin/env sh
. "${ROOT:-..}/common/set_opts.sh"
save_set_options
set +eu


#region --- Цветовые коды ----
# Использ tput для переносимости.

# Сброс
# COLOR_RESET="\033[0m"
COLOR_RESET="$(tput sgr0 2>/dev/null)"
export NC="${COLOR_RESET}"

# Обычные цвета
export BLACK="\033[0;30m"
# RED="\033[0;31m"
export RED="$(tput setaf 1 2>/dev/null)"
# GREEN="\033[0;32m" # 46
export GREEN="$(tput setaf 46 2>/dev/null)"
# YELLOW="\033[0;33m"
export YELLOW="$(tput setaf 3 2>/dev/null)"
# BLUE="\033[0;34m"
export BLUE="$(tput setaf 4 2>/dev/null)"
# PURPLE="\033[0;35m"
export PURPLE="$(tput setaf 5 2>/dev/null)"
export CYAN="\033[0;36m"
# export CYAN="$(tput setaf 5 2>/dev/null)"
export WHITE="\033[0;37m"
# export WHITE="$(tput setaf 5 2>/dev/null)"

# Жирные цвета
# BOLD_BLACK="\033[1;30m"
# BOLD_RED="\033[1;31m"
# BOLD_GREEN="\033[1;32m"
# BOLD_YELLOW="\033[1;33m"
# BOLD_BLUE="\033[1;34m"
# BOLD_PURPLE="\033[1;35m"
# BOLD_CYAN="\033[1;36m"
# BOLD_WHITE="\033[1;37m"
export BOLD="$(tput bold 2>/dev/null)"

# Фоны
export BG_RED="\033[41m"
export BG_GREEN="\033[42m"
export BG_YELLOW="\033[43m"
export BG_BLUE="\033[44m"

# Функции с форматированием
# @arg text
# @arg level (which \t sybmols need input before the text)


# ----------  внутренние  ----------
_indent() {  # $1 – уровень
  printf "%${1:-0}s"
}

_say() {     # $1=цвет $2=иконка $3=метка $4=текст $5=уровень
  _indent "${5:-0}"
  # printf '%b%b %s: %b%b\n' "$1" "$2" "$3" "$4" "$NC"
  echo "$1$2 ${3:+ $3: }$4$NC"
}

# ----------  публичные  ----------
info()    { _say "${BOLD}${BLUE}"    "ℹ️"  ""                  "$1" "${2:-0}"; }
error()   { _say "${BOLD}${RED}"     "❌"  "${NC}${RED}"       "$1" "${2:-0}"; }
warning() { _say "${BOLD}${YELLOW}"  "⚠️"  "${NC}${YELLOW}"    "$1" "${2:-0}"; }
success() { _say "${BOLD}${GREEN}"   "✅"  "${NC}${GREEN}"     "$1" "${2:-0}"; }
ask()     { _say "${BOLD}${PURPLE}"  "❓"  "${NC}${PURPLE}"    "$1" "${2:-0}"; }
debug()   { _say "${BOLD}${CYAN}"    "🔧"  "DEBUG${NC}${CYAN}" "$1" "${2:-0}"; }
say()     { _say "${1:-}"        "${2:-}" "${3:-}:"           "$4" "${5:-0}"; }
justSay() { _say ""  ""  ""  "$1" "${2:-0}"; }

askExit() {
    ask "Stop? [y/n]"
    read -r answer
    if [ "$answer" = "y" ]; then exit 0; fi
}
#endregion ========


restore_set_options
