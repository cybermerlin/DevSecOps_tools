#!/usr/bin/env sh

# for all script when you need change `set eu` options only inside of current script.
#
# How to use it
#     (do not forget to set $ROOT if your script placed in another directory)
#     (set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")/../.." && pwd)"; set -u;)
#
# #!/usr/bin/env sh
# . "${ROOT:-..}/common/set_opts.sh"
# save_set_options
# ... your set +-eu...
# restore_set_options
# 

_SET_OPTIONS_OLD_FLAGS=""

save_set_options() {
    _SET_OPTIONS_OLD_FLAGS="$-"
}

restore_set_options() {
    if [ -n "$_SET_OPTIONS_OLD_FLAGS" ]; then
        set +e
        set +u
        case "$_SET_OPTIONS_OLD_FLAGS" in
            *e*) set -e ;;
        esac
        case "$_SET_OPTIONS_OLD_FLAGS" in
            *u*) set -u ;;
        esac
        # Очищаем переменную после использования
        _SET_OPTIONS_OLD_FLAGS=""
    fi
}
