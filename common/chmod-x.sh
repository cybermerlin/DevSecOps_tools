#!/usr/bin/env sh
set -eu

set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"; set -u
COLORS_PATH="${ROOT}/common/colors.sh"
. "$COLORS_PATH"

# to `chmod -x` all not executable files
# and `chmod +x` for executable files
#
# Safer version using find -exec for better handling of special characters


TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR" ]; then
    error "Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

# Use find with -exec to handle each file individually
find "$TARGET_DIR" -type f -exec sh -c '
    _LIST=""
    COLORS_PATH="$1"
    # Импортируем colors.sh в дочерний shell
    . "$COLORS_PATH"
    shift
    
    for file do
        # Get filename and extension
        filename=$(basename "$file")
        
        # Extract extension
        case "$filename" in
            *.*)
                extension="${filename##*.}"
                ;;
            *)
                extension=""
                ;;
        esac
        
        # Check if extension should be excluded
        case "$extension" in
            sh|bash|exe|bin|run|app|com|bat|cmd|ps)
                chmod +x "$file"
                _LIST="$_LIST $file"
                continue
                ;;
            *)
                # Remove executable permissions
                info "[-] --> $file"
                chmod -x "$file"
                ;;
        esac
    done

    for item in $_LIST; do info "${RED}[+] --> $file"; done
' sh "$COLORS_PATH" {} +

success "[chmod] -/+ x"
