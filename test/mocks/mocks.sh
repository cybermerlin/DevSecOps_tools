#!/bin/sh


# Mock функций которые выполняют системные вызовы
git() {
    echo "MOCK: git config --global $*"
}

mkdir() {
    echo "MOCK: mkdir $*"
}

tee() {
    echo "MOCK: tee $*"
    cat  # Просто пропускаем stdin
}

systemctl() {
    echo "MOCK: systemctl $*"
}

find() {
    echo "MOCK: find $*"
    # Возвращаем фиктивный сокет для тестирования
    echo "/tmp/ssh-1000/agent.1234"
}

pgrep() {
    echo "MOCK: pgrep $*"
    # Возвращаем пустой результат (процесс не найден)
    return 1
}
