#!/usr/bin/env sh
set -eu

set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"; set -u
. "${ROOT}/common/colors.sh"
. "${ROOT}/common/progress.sh"
. "${ROOT}/common/handler.sh"


syncFromWSL() {
    time sudo rsync -av --delete-after --delete-excluded ../DevSecOps_tools /mnt/f/dev/projects/admin/cleanup/
}

while true; do
    _choice=${1:-}; shift;

    if [ -z ${_choice} ]; then
        # Display menu
        echo "\nWelcome!"
        echo "Please select a function to execute:"
        echo "\e$RED\t 0) \e$GREEN exit"
        echo "\e$RED\t 1) \e$GREEN run 'Freeup' in interactive mode"
        echo "\e$RED\t 2) \e$GREEN calculate disk usage"
        echo "\e$RED\t 3) \e$GREEN cleanup"
        echo "\e$RED\t 4) \e$GREEN "
        echo "\e$RED\t 5) \e$GREEN this WSL prep as NAT router"
        echo "\e$RED\t 6) \e$GREEN sync code of this DevSecOps tools to host"
        echo "\e$RED\t 7) \e$GREEN compact FS"
        echo "\e$RED\t 8) \e$GREEN this WSL prep"
        
        echo "\e$RED\t test) \e$GREEN run tests"
        echo "\e$RED\t code) \e$GREEN run vs.code"
        echo "\e$RED\t wsl-prep) \e$GREEN this WSL prep (eq. 8)"
        echo "\e$RED\t inst-docker) \e$GREEN docker install"
        echo "\e$RED\t del-docker) \e$GREEN docker remove"
        echo "\e$RED\t inst-registry) \e$GREEN install Registries for all packages cacheing (to use it in another machines)"
        echo "\e$RED\t apply-registry) \e$GREEN preset configs to use local Registries"
        
        echo "\e$NC"
        # Read user input
        printf "Enter a number: " >&2
        read -r _choice
        echo ""
    fi

    # Execute the chosen function
    case $_choice in
        0) exit 0 ;;
        1) sudo ./cleaner/freeup.sh ;;
        2) sudo ./cleaner/freeup.sh disk_usage ;;
        3) sudo ./cleaner/freeup.sh clean;;
        4)  ;;
        5) ./wsl-prep/run.sh nat;;
        6) syncFromWSL ;;
        7) ./cleaner/freeup.sh compact;;
        8) ./wsl-prep/run.sh full;;

        test) ./test/run.sh; exit 0;;
        code) ${ROOT}/wsl-prep/run.sh inst_code; exit 0;;
        wsl-prep) ${ROOT}/wsl-prep/run.sh ${1:-full} $@; exit 0;;
        inst-docker) ${ROOT}/dev-prep/docker-inst/install-docker.sh; exit 0;;
        del-docker) ${ROOT}/dev-prep/docker-inst/remove-docker.sh; exit 0;;
        inst-registry) ${ROOT}/registry/run.sh up; exit 0;;
        apply-registry) ${ROOT}/registry/configure.sh apply; exit 0;;

        *)
            error "Invalid input. Please enter a number from the list above"
            if [ ! -z ${_choice} ]; then
                exit 1
            fi
            ;;
    esac
done
