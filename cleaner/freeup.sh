#!/usr/bin/env sh
set -eu
LANG=en_US.UTF-8
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EUID=$(id -u)


# import
. ${SCRIPT_DIR}/../common/colors.sh
. ${SCRIPT_DIR}/../common/progress.sh
. ${SCRIPT_DIR}/../common/handler.sh


# Function to display disk usage
# $_dir - start directory count
# $_max_depth - Использование: $0 <директория> <максимальный_уровень_вложенности>
# $_size_filter - Пример фильтра: '>2G' для размера больше 2 Гб, '<100M' для размера меньше 100 Мб
# $_name_filter - Пример фильтра имени: 'documents' для директорий, содержащих 'documents' в имени
display_disk_usage() {
    info "Analyze disk usage..."
    _dir="$1"
    _max_depth="${2:-}"
    _size_filter="${3:-}"
    _name_filter="${4:-}"

    df -h $_dir

    # Проверка аргументов
    if [ -z "$_dir" ] || [ -z "$_max_depth" ]; then
        echo "Использование: $0 <директория> <максимальный_уровень_вложенности>"
        echo "Пример фильтра: '>2G' для размера больше 2 Гб, '<100M' для размера меньше 100 Мб"
        echo "Пример фильтра имени: 'documents' для директорий, содержащих 'documents' в имени"
        return 1
    fi
    if [ ! -d "$_dir" ]; then
        echo "Ошибка: Директория $_dir не существует"
        return 1
    fi

    python3 ${SCRIPT_DIR}/find.py "$_dir" "$_max_depth" "$_size_filter" "$_name_filter" | while read -r line; do
        echo "$line"
    done
}


# shellcheck disable=SC2120
main() {
    # Проверка прав суперпользователя
    if [ "$EUID" -ne 0 ]; then
        warning "Пожалуйста, запустите этот скрипт с правами суперпользователя: \n sudo ${0} ${*}"
        exit 1
    fi

    info "Remove apt and another old and garbage, temporary, logs"
    askExit
    df -h /

    apt autoremove -y --purge

    info "[ start ] APT packages cache cleanup..." 10
    du -sh /var/cache/apt
    # sudo rm -rf /var/cache/apt/*
    apt autoclean
    apt -s clean
    du -sh /var/cache/apt
    success "[ finished ] APT packages cache cleanup..." 10

    info "[ start ] snapd cache cleaning..." 10
    du -sh /var/lib/snapd/snaps
    snap list --all | awk '/disabled/{print $1, $3}' |
        while read snapname revision; do
            snap remove "$snapname" --revision="$revision"
        done
    du -sh /var/lib/snapd/snaps
    success "[ finished ] snapd cache cleaning..." 10

    info "[ start ] flatpak cleaning..." 10
    du -sh /var/lib/flatpak/app /var/lib/flatpak/repo ~/.local/share/flatpak 2>/dev/null || echo "No flatpaks found"
    flatpak uninstall --unused -y
    sudo flatpak repair
    sudo rm -rf /var/tmp/flatpak-cache-*
    du -sh /var/lib/flatpak/app /var/lib/flatpak/repo ~/.local/share/flatpak 2>/dev/null || echo "No flatpaks found"
    du -sh ~/.cache/flatpak/
    success "[ finished ] flatpak cleaning..." 10

    info "[ start ] Removing old kernels..." 10
    _current_kernel=$(uname -r | sed "s/-generic//")
    # TODO: check sed "/^ii/!d;/${_current_kernel}/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d" <- mb need in qutas "$_current_kernel"
    dpkg -l 'linux-*' | sed "/^ii/!d;/${_current_kernel}/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d" | xargs apt-get -y purge
    success "[ finished ] Removing old kernels..." 10

    info "[ start ] remove unnecessary files..." 10
    # Clear temporary files
    info "Clearing temporary files..." 20
    rm -rf /tmp/* /var/tmp/* /etc/apk/cache/* /var/cache/* /var/lib/apt/lists/* /var/log/* /usr/share/doc/* /usr/share/man/*
    # Empty trash
    info "Emptying trash..." 20
    rm -rf ~/.local/share/Trash/*
    # Remove thumbnail cache
    info "Removing thumbnail cache..." 20
    rm -rf ~/.cache/thumbnails/*
    success "[ finished ] remove unnecessary files..." 10

    info "[ start ] dpkg cleanup..." 10
    LC_ALL=C dpkg -l | awk '/^rc/ {print $2}' | xargs sudo dpkg --purge
    sudo dpkg --purge --pending
    success "[ finished ] dpkg cleanup..." 10

    info "journal systemd" 20
    journalctl --disk-usage
    journalctl --vacuum-time=7d

    warning "\nFor WSL u can use shrinking: 'wsl --shutdown; optimize-vhd -Path D:\vmx\wsl.ubuntu.desktop\ext4.vhdx -Mode full'"

    df -h /
}


# Функция для выполнения очистки файлов не входящих в пакеты Пакетного менеджера
# shellcheck disable=SC2120
cruftCln() {
    # need superuser
    if [ "$EUID" -ne 0 ]; then
        echo "Пожалуйста, запустите этот скрипт с правами суперпользователя:"
        echo "sudo ${0} ${*}"
        exit 1
    fi
    echo "Поиск ненужных файлов..."
    askExit

    # Получаем список ненужных файлов
    cruft_files=$(sed -n '/---- missing: dpkg ----/,/---- unexplained: \/ ----/{
  /---- missing: dpkg ----/d
  /---- unexplained: \/ ----/d
  p
}' cruft.log | grep -v '^end\.$')
    echo "$cruft_files" > cruft-mis-dpkg.log

    # Подсчет общего освобождаемого пространства
    total_space=0
    echo "$cruft_files" | while read -r file; do
        if [ -e "$file" ]; then
            file_size=$(du -sb "$file" 2>/dev/null | cut -f1)
            if [ -n "$file_size" ]; then
                total_space=$(($total_space + $file_size))
            fi
        fi
    done

    # Конвертация размера в удобочитаемый формат
    if [ $total_space -lt 1024 ]; then
        echo "Общее освобождаемое пространство: $total_space байт"
    elif [ $total_space -lt 1048576 ]; then
        echo "Общее освобождаемое пространство: $(echo "scale=2; $total_space/1024" | bc) КБ"
    elif [ $total_space -lt 1073741824 ]; then
        echo "Общее освобождаемое пространство: $(echo "scale=2; $total_space/1048576" | bc) МБ"
    else
        echo "Общее освобождаемое пространство: $(echo "scale=2; $total_space/1073741824" | bc) ГБ"
    fi

    # Подтверждение очистки
    echo "Вы уверены, что хотите выполнить очистку? (y/n)"
    read -r confirm

    if [ "$confirm" = "y" ]; then
        echo "$cruft_files" | while read -r file; do
            if [ -e "$file" ]; then
                if rm -rf "$file"; then
                    echo "Удален: $file"
                else
                    echo "Ошибка при удалении: $file"
                fi
            else
                echo "Пропущен (не существует): $file"
            fi
        done
        echo "Очистка завершена."
    else
        echo "Очистка отменена."
    fi
}

cruftAnal() {
    echo "Выполнение сухой проверки..."
    cruft 2>&1 | tee cruft.log
    echo "Сухая проверка завершена."
}

dockerCln() {
    info "[start] Clean up docker files"
    askExit

    _docker=$(which docker)
    case "$_docker" in
        /home/*)
            info "docker system prune --all --volumes >" 5
            docker system prune --all --volumes
            info "docker image prune --all >"5
            docker image prune --all
            info "docker container prune >" 5
            docker container prune

            info "docker system df >" 5
            docker system df
            info "docker volume prune >" 5
            docker volume prune
            info "docker buildx prune --all >" 5
            docker buildx prune
            ;;
        *)
            info "docker system prune --all --volumes >" 5
            sudo docker system prune --all --volumes
            info "docker image prune --all >"5
            sudo docker image prune --all
            info "docker container prune >" 5
            sudo docker container prune
            
            info "docker system df >" 5
            sudo docker system df
            info "docker volume prune >" 5
            sudo docker volume prune
            info "docker buildx prune --all >" 5
            sudo docker buildx prune
            ;;
    esac

    success "[finish] Clean up docker files"
}


#region --- for the interactive menu ---
compact() {
    handler 'e4defrag /dev/*' "Defragmentation disks"

    powershell.exe -Command "Compact /U /F R:\Temp\ext4.vhdx"
    powershell.exe -Command "optimize-vhd -Path R:\temp\ext4.vhdx -Mode full"
}
disk_usage() {
    echo "Put your arguments:"
    echo "_dir - start directory count"
    echo "_max_depth - Использование: 0 <директория> <максимальный_уровень_вложенности>"
    echo "_size_filter - Пример фильтра: '>2G' для размера больше 2 Гб, '<100M' для размера меньше 100 Мб"
    echo "_name_filter - Пример фильтра имени: 'documents' для директорий, содержащих 'documents' в имени"
    echo "Example: / 1 >1G"
    read ":" args
    echo ""
    set -- $args

    display_disk_usage "${1:-}" "${2:-}" "${3:-}" "${4:-}"
}
#endregion ======


_arg="${1:-}"
case "${_arg}" in
    clean) main ;;
    disk_usage) display_disk_usage  "/" "1" ">1G" ;;
    compact) compact ;;

    *)
        while true; do
            # Display menu
            echo "\nДобро пожаловать в скрипт очистки ненужных файлов!"
            echo "Please select a function to execute:"
            echo "$RED\t 1) $GREEN calculate disk usage"
            echo "$RED\t 2) $GREEN main cleanup function"
            echo "$RED\t 3) $GREEN GC docker's waste products"
            echo "$RED\t 4) $GREEN cruft cleanup from 'missing: dpkg' group"
            echo "$RED\t 5) $GREEN cruft analyze"
            echo "$RED\t 6) $GREEN compact FS"
            echo "$RED\t 7) $GREEN exit"
            echo "$NC"
            # Read user input
            read -p "Enter a number: " choice
            echo ""

            # Execute the chosen function
            case $choice in
                1) disk_usage ;;
                2) main ;;
                3) dockerCln ;;
                4) cruftCln ;;
                5) cruftAnal ;;
                6) compact ;;
                7) exit 0 ;;
                *) echo "Invalid input. Please enter a number from the list above" ;;
            esac
        done ;;
esac
