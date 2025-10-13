#!/bin/sh
set -eu

# import
. ./common/colors.sh
. ./common/progress.sh
. ./common/handler.sh


while true; do
    # Display menu
    echo "\nWelcome!"
    echo "Please select a function to execute:"
    echo "\e$RED\t 0) \e$GREEN run 'Freeup' in interactive mode"
    echo "\e$RED\t 1) \e$GREEN calculate disk usage"
    echo "\e$RED\t 2) \e$GREEN cleanup"
    echo "\e$RED\t 3) \e$GREEN "
    echo "\e$RED\t 4) \e$GREEN "
    echo "\e$RED\t 5) \e$GREEN "
    echo "\e$RED\t 6) \e$GREEN compact FS"
    echo "\e$RED\t 7) \e$GREEN exit"
    echo "\e$NC"
    # Read user input
    read -p "Enter a number: " choice
    echo ""

    # Execute the chosen function
    case $choice in
        0) sudo ./cleaner/freeup.sh ;;
        1) sudo ./cleaner/freeup.sh disk_usage ;;
        2) sudo ./cleaner/freeup.sh clean;;
        3)  ;;
        4)  ;;
        5)  ;;
        6) ./cleaner/freeup.sh compact;;
        7) exit 0 ;;
        *) echo "Invalid input. Please enter a number from the list above" ;;
    esac
done
