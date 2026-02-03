#!/usr/bin/env sh
set -eu

# trim all whitespaces around current string
trim() {
  _t="$1"
  # 1. leading  whitespace
  _t=${_t#"${_t%%[![:space:]]*}"}
  # 2. trailing whitespace
  _t=${_t%"${_t##*[![:space:]]}"}

  echo "$_t"
}
