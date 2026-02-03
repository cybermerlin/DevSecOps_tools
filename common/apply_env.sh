#!/usr/bin/env sh
set -eu

_FILE="${1:-./.env}"

# 
# need to safe extract all vars from .env to current sub-shell
# 

set -a
while IFS='=' read key value; do
  # skip comments and empty lines
  case "$key" in
    '' | '#'* ) continue ;;
  esac
  key=$(printf '%s\n' "$key" | xargs)
  value=$(printf '%s\n' "$value" | xargs)
  export "$key=$value"
done < "${_FILE}"
set +a
