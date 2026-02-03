#!/usr/bin/env sh
set -eu

set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"; set -u
. "${ROOT}/common/colors.sh"


#region --- Progress bar ---
# TODO: need fix or use from my cleaner
#region alternative Draw and Using progress bar
# # Before your loop: Initialize the progress bar at the bottom
# tput sc  # Save cursor position
# tput cup $(( $(tput lines) - 1 )) 0  # Move to the bottom line
# echo -n "Progress: [--------------------] 0%"
# tput rc  # Restore cursor

# # Inside your loop, when updating:
# tput sc  # Save cursor
# tput cup $(( $(tput lines) - 1 )) 0  # Move to progress bar line
# # ... your code to print the updated progress bar ...
# tput rc  # Restore cursor to where it was for other output
#endregion

progress_bar() {
    [ -z "$1" ] && _current=0 || _current="$1"
    _total=100
    _spinner='\|/-'
    _spinner_index=1
    
    # while [ $_current -le $_total ]; do
        percent=$((_current * 100 / _total))
        filled=$((percent / 2))  # 50 characters = 100%
        empty=$((50 - filled))
        
        # Build progress bar string
        bar="["
        # Add filled portion
        i=0
        while [ $i -lt $filled ]; do
            bar="${bar}#"
            i=$((i + 1))
        done
        # Add empty portion  
        i=0
        while [ $i -lt $empty ]; do
            bar="${bar}."
            i=$((i + 1))
        done
        bar="${bar}]"
        
        # Get _current _spinner character
        spin_char=$(echo "$_spinner" | cut -c "$_spinner_index")
        
        # Print progress bar
        printf "${BOLD}${GREEN}Progress: ${NC}%s ${GREEN}[%3d%%]${NC} %s\r" "$spin_char" "$percent" "$bar"
        
        # Update _spinner index (cycle through 1-4)
        _spinner_index=$((_spinner_index % 4 + 1))
        
        sleep .1
        _current=$((_current + 1))
    # done
    echo  # New line after completion
}
#endregion ========
