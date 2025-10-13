#!/bin/sh
set -eu

#region --- Цветовые коды ----
# Сброс
COLOR_RESET="\033[0m"
NC="${COLOR_RESET}"

# Обычные цвета
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"

# Жирные цвета
BOLD_BLACK="\033[1;30m"
BOLD_RED="\033[1;31m"
BOLD_GREEN="\033[1;32m"
BOLD_YELLOW="\033[1;33m"
BOLD_BLUE="\033[1;34m"
BOLD_MAGENTA="\033[1;35m"
BOLD_CYAN="\033[1;36m"
BOLD_WHITE="\033[1;37m"

# Фоны
BG_RED="\033[41m"
BG_GREEN="\033[42m"
BG_YELLOW="\033[43m"
BG_BLUE="\033[44m"

# Функции с форматированием
# @arg text
# @arg level (which \t sybmols need input before the text)
error() {
  local _lvl="${2:-}"
  [ -z "$_lvl" ] || _lvl=$(printf "%${_lvl}s")
  
  echo "${_lvl}${BOLD_RED}❌ ОШИБКА: $1${COLOR_RESET}";
}
success() {
  local _lvl="${2:-}"
  [ -z "$_lvl" ] || _lvl=$(printf "%${_lvl}s")
  
  echo "${_lvl}${BOLD_GREEN}✅ УСПЕХ: $1${COLOR_RESET}";
}
warning() {
  local _lvl="${2:-}"
  [ -z "$_lvl" ] || _lvl=$(printf "%${_lvl}s")
  
  echo "${_lvl}${BOLD_YELLOW}⚠️  ПРЕДУПРЕЖДЕНИЕ: $1${COLOR_RESET}";
}
info() {
  local _lvl="${2:-}"
  [ -z "$_lvl" ] || _lvl=$(printf "%${_lvl}s")
  
  echo "${_lvl}${BOLD_CYAN}ℹ️  ИНФО: $1${COLOR_RESET}";
}
ask() {
  local _lvl="${2:-}"
  [ -z "$_lvl" ] || _lvl=$(printf "%${_lvl}s")
  
  echo "${_lvl}${BOLD_MAGENTA}❓  ВОПРОС: $1${COLOR_RESET}";
}
#endregion ========
