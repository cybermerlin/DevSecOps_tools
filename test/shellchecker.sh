#!/usr/bin/env sh
set -eu

set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"; set -u
${RED+:} . "${ROOT}/common/colors.sh"
. "${ROOT}/common/string.sh"


_analyze_shellcheck_results() {
    _script=$1
    info "🔍 Analyzing: $_script" 5

    # Run shellcheck and capture output and exit code
    _output=$(shellcheck -f gcc "$_script" 2>&1)
    _exit_code=$?

    if [ "$_exit_code" -eq 0 ]; then
        return 0

    else
        #region Parse output line by line
        # временный файл-флаг: появится, если хоть одна строка прошла фильтр
        printed=$(mktemp)
        trap 'rm -f "$printed"' EXIT

        echo "$_output" | while IFS= read -r line; do
            # Match lines of format file:line:col:severity: message [SCnnnn]
            #  common/colors.sh:15:8: warning: Declare and assign separately to avoid masking return values. [SC2155]

            # 1. быстрая проверка формата  file:line:col:severity:msg
            oldIFS=$IFS; IFS=:
            set -- $line               # $1 $2 $3 $4 ${5-}...
            IFS=$oldIFS

            case $line in
              (*"[SC1090]"*|*"[SC1091]"*|*"[SC2155]"*)
                  continue;
            esac
            case $2$3 in
              (*[!0-9]*) continue ;;  # line или col не число – пропускаем
            esac
            [ $# -ge 5 ] || continue  # меньше 5 полей – пропускаем
            
            # полезная строка найдена – создаём флаг
            # : > "$printed"
            [ ! -s "$printed" ] && printf . >> "$printed"

            # 2. забираем переменные
            file=$1
            line_num=$2
            severity=$(trim $4)
            message="$5."
            # убираем  [SCnnnn]
            message="$(printf '%s\n' "$message" | awk '{sub(/ \[SC[0-9]+\]\.?$/,"");print;}')"
            
            shift 5; while [ $# -gt 0 ]; do message=$message:$1; shift; done
            case "$severity" in
                error)   say "$RED"     "🔴" "ERROR" "L:$line_num> $message" 10 ;;
                warning) say "$YELLOW"  "🟡" "WARNING" "L:$line_num> $message" 10 ;;
                info)    say "$BLUE"    "🔵" "INFO" "L:$line_num> $message" 10 ;;
                *)       say ""         "⚪" "$severity" "L:$line_num> $message" 10 ;;
            esac
        done
        #endregion

        if [ ! -s "$printed" ]; then
            return 0
        fi
        return 1
    fi
}


shellchecker(){
  _failed_checks=0
  _checked_scripts=0
  info 'START shellchecker()\n'
  [ $# -eq 0 ] && { error "Has no parameter..."; return 1; }

  # 1. собираем файлы в переменную
  _tmp_list=$(mktemp)
  trap 'rm -f "$_tmp_list"' EXIT
  find "$1" -name '*.sh' -type f >"$_tmp_list"

  while read -r _script <&3; do
      [ -z "$_script" ] && continue   # на случай пустого find
      _checked_scripts=$((_checked_scripts + 1))
      
      if _analyze_shellcheck_results "$_script"; then
          success "PASS: $_script" 5
      else
          error  "FAIL: $_script" 5
          _failed_checks=$((_failed_checks + 1))
      fi
      echo ""
  done 3<"$_tmp_list"

  info "=== SUMMARY [shellcheck] ==="
  echo "Total scripts checked: $_checked_scripts"
  echo "Failed checks: $_failed_checks"

  [ "$_failed_checks" -eq 0 ] && { success "🎉 All scripts passed ShellCheck!"; return 0; }
  error "💥 ${_failed_checks} scripts have issues"
  return $_failed_checks
}

# just to return count of failed-scripts checks
sc() {
  return "$(shellchecker "$@")"
}

# Determine if script is executed or sourced (POSIX compatible)
if [ "${0##*/}" = "shellchecker.sh" ]; then
    debug "shellchecker.sh called from=${0##*/} with args=${*}" >&2
    shellchecker "$@"
fi
