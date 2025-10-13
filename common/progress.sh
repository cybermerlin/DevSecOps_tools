#!/bin/sh
set -eu

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
    [ -z "$1" ] && local current=0 || local current=$1
    local total=100
    local spinner='\|/-'
    local spinner_index=1
    
    # while [ $current -le $total ]; do
        percent=$((current * 100 / total))
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
        
        # Get current spinner character
        spin_char=$(echo "$spinner" | cut -c "$spinner_index")
        
        # Print progress bar
        printf "${GREEN}Progress: ${NC}%s ${GREEN}[%3d%%]${NC} %s\r" "$spin_char" "$percent" "$bar"
        
        # Update spinner index (cycle through 1-4)
        spinner_index=$((spinner_index % 4 + 1))
        
        sleep .1
        current=$((current + 1))
    # done
    echo  # New line after completion
}
#endregion ========
