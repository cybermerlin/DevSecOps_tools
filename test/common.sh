#!/usr/bin/env sh
set -eu

set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"; set -u
. "${ROOT}/common/colors.sh"
TEMP_OUT="$ROOT/.test_tmp.out"
FAILED=0


#region [colors]
# Функция для проверки наличия ожидаемого текста и ANSI цветового кода
assert_color_out() {
    _func=$1; shift
    _expect_text=$1; shift
    _expect_ansi_code=$1; shift || true
    # Запускаем функцию и ловим вывод
    _OUTPUT=$( ( . "${ROOT}/common/colors.sh"; $_func "$@" ) | stdbuf -o0 cat )

    _escape_for_grep() {
        echo "$1" | sed 's/\[/\\[/g; s/\]/\\]/g'
    }

    # Проверяем наличие текста
    if ! echo "$_OUTPUT" | grep -qE "$_expect_text"; then
        error "FAIL: [$_func] — ожидаемый текст '$_expect_text' не найден" 10
        FAILED=$((FAILED+1))
        return
    fi

    # Если указан цветовой код, проверяем его наличие
    if [ -n "$_expect_ansi_code" ]; then
        if ! echo "$_OUTPUT" | grep -F -q "${_expect_ansi_code}"; then
            error "FAIL: [$_func] — ожидаемый ANSI код '$(_escape_for_grep "$_expect_ansi_code")' не найден в <$_OUTPUT>" 10
            FAILED=$((FAILED+1))
            return
        fi
    fi

    success "PASS: [$_func]" 10
}

info "[ Запускаем ] BDD-тесты…" 5

# Тесты цветного вывода с проверкой ANSI-кодов
assert_color_out info ".*Загрузка завершена" "$(printf $BLUE)" "Загрузка завершена"
assert_color_out error ".*Файл не найден" "$(printf $RED)" "Файл не найден"
assert_color_out warning ".*Недостаточно места" "$(printf $YELLOW)" "Недостаточно места"
assert_color_out success ".*Установка завершена" "$(printf $GREEN)" "Установка завершена"
assert_color_out ask ".*Продолжить установку" "$(printf $PURPLE)" "Продолжить установку?"
assert_color_out debug "DEBUG.*: Ошибка в строке 5" "$(printf $CYAN)" "Ошибка в строке 5"
assert_color_out say "ERROR: L:666> текст сообщения" "$(printf $RED)" "$RED" "🔴" "ERROR" "L:666> текст сообщения" 10
assert_color_out say "сообщения" '' "" "🔴" "" "сообщения" 10

# Тесты с отступами проверяем просто наличие табуляций
assert_color_out info "^[[:blank:]]{2}.*:.*Тест 2 tab" "" "Тест 2 tab" 2
assert_color_out error "^[[:blank:]]{4}.*:.*Ошибка 4 tab" "" "Ошибка 4 tab" 4
#endregion [colors]


#region [handler]
echo ""
# Обертка команд handler
. "$ROOT/common/handler.sh"
handler_test() {
    set +e
    if handler "${1}" "${2}" "${3:-0}" >/dev/null 2>&1; then
        echo "HANDLER_OK"
    else
        echo "HANDLER_FAIL"
    fi
    set -e
}

if [ "$(handler_test 'ls /tmp' 'Проверка временной директории')" = "HANDLER_OK" ]; then
    success "PASS: [handler] успешный – OK" 10
else
    error "FAIL: [handler] успешный – FAIL" 10
    FAILED=$((FAILED+1))
fi

if handler_test "ls /nonexistent" "Проверка несуществующей директории" 2>&1 | grep -q HANDLER_FAIL; then
    success "PASS: [handler] неуспешный – OK (ожидали fail)" 10
else
    error "FAIL: [handler] неуспешный – FAIL" 10
    FAILED=$((FAILED+1))
fi

_OUTPUT=$( ( . "${ROOT}/common/colors.sh"; handler "echo 'test'" 'Тестовая команда' 4 ) | stdbuf -o0 cat )
if echo "$_OUTPUT" | grep -qE "^[[:blank:]]{4}.*"; then
    success "PASS: [handler] c отступом – OK" 10
else
    error "FAIL: [handler] c отступом – FAIL" 10
    FAILED=$((FAILED+1))
fi
#endregion [handler]


#region [progress]
echo ""
# Поэтапная проверка прогресс-бара (0%, 50%, 100%)
progress_test() {
    _percent=$1
    _expected_percent=$2
    shift 2
    ( . "$ROOT/common/progress.sh"; progress_bar "$_percent" ) > "$TEMP_OUT" 2>&1

    grep -q "${_expected_percent}%" "$TEMP_OUT" || return 1
    for pattern in "$@"; do
        grep -q "$pattern" "$TEMP_OUT" || return 1
    done
}

progress_test 0 "0" '\[' '\.' '\]' \
    && success "PASS: [progress] 0%" 10 || { error "FAIL: [progress] 0%" 10 ; FAILED=$((FAILED+1)); }

progress_test 50 "50" '#' '\.' \
    && success "PASS: [progress] 50%" 10 || { error "FAIL: [progress] 50%" 10 ; FAILED=$((FAILED+1)); }

progress_test 100 "100" '#' \
    && success "PASS: [progress] 100%" 10 || { error "FAIL: [progress] 100%" 10 ; FAILED=$((FAILED+1)); }
#endregion [progress]


#region [trim]
echo ""
. "${ROOT}/common/string.sh"
input="   some text with spaces   "
expected="some text with spaces"
output=$(trim "$input")

if [ "$output" = "$expected" ]; then
success "PASS: [trim]" 10
else
error "FAIL: [trim]. Expected: '$expected'. Got: '$output'." 10
FAILED=$((FAILED+1))
fi
#endregion


#region chmod-x
test_chmod_x() {
  # Создаем временную директорию для теста
  _TMPDIR=$(mktemp -d)
  trap 'rm -rf "$_TMPDIR"' EXIT

  # Создаем тестовые файлы
  touch "$_TMPDIR/file1"
  touch "$_TMPDIR/file2"
  touch "$_TMPDIR/file3.sh"

  # Устанавливаем флаг исполнения только для file3.sh
  chmod +x "$_TMPDIR/file3.sh"

  # Проверяем исходные права
  ls -l "$_TMPDIR"

  # Вызываем функцию из вашего скрипта, передавая путь к _TMPDIR
  . ./chmod-x.sh
  your_function_name "$_TMPDIR"  # замените на реальное имя функции

  # Проверяем права после вызова функции
  echo "Права после вызова функции:"
  ls -l "$_TMPDIR"

  # Проверки:
  if [ ! -x "$_TMPDIR/file1" ] && [ ! -x "$_TMPDIR/file2" ] && [ -x "$_TMPDIR/file3.sh" ]; then
    echo "PASS: Флаги установлен/снят корректно"
    return 0
  else
    echo "FAIL: Ошибка установки/снятия флагов"
    return 1
  fi
}

test_chmod_x
#endregion


rm -f "$TEMP_OUT"
info "[ Выполнили ] BDD-тесты…" 5


if [ "$FAILED" -eq 0 ]; then
    success "ВСЕ ТЕСТЫ ПРОЙДЕНЫ" 5
else
    error "ТЕСТОВ ПРОВАЛЕНО: $FAILED" 5
    return 1
fi
