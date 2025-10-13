#!/bin/sh

CONFIG_FILE="/etc/apt/apt-autoconfig.conf"
LAST_VERSION_FILE="/var/lib/apt/last-known-version"

# Сохраняем текущую версию
save_current_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$VERSION_CODENAME:$VERSION_ID" > "$LAST_VERSION_FILE"
    fi
}

# Проверяем, изменилась ли версия
check_version_change() {
    if [ ! -f "$LAST_VERSION_FILE" ]; then
        return 1  # Файл не существует, значит версия изменилась
    fi
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        CURRENT_VERSION="$VERSION_CODENAME:$VERSION_ID"
        LAST_VERSION=$(cat "$LAST_VERSION_FILE" 2>/dev/null)
        
        if [ "$CURRENT_VERSION" != "$LAST_VERSION" ]; then
            return 1  # Версия изменилась
        fi
    fi
    
    return 0  # Версия не изменилась
}

# Автоматическое создание sources.list для ЛЮБОЙ версии
create_auto_sources() {
    if [ ! -f /etc/os-release ]; then
        echo "❌ Не могу определить дистрибутив"
        return 1
    fi
    
    . /etc/os-release
    
    # Для Ubuntu-based систем
    if [ "$ID" = "ubuntu" ]; then
        CODENAME=$VERSION_CODENAME
    else
        # Для других Debian-based систем используем stable
        CODENAME="stable"
    fi
    
    echo "=== Создание sources.list для $PRETTY_NAME ==="
    
    sudo tee /etc/apt/sources.list > /dev/null << EOF
# Automatically generated sources.list - DO NOT EDIT MANUALLY
# This file will be regenerated automatically on version change

# Main repositories
deb http://archive.ubuntu.com/ubuntu/ $CODENAME main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $CODENAME-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $CODENAME-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ $CODENAME-backports main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu/ $CODENAME-security main restricted universe multiverse

# Additional mirrors for reliability
# deb http://ports.ubuntu.com/ubuntu-ports/ $CODENAME main restricted universe multiverse
# deb http://ports.ubuntu.com/ubuntu-ports/ $CODENAME-updates main restricted universe multiverse
# deb http://ports.ubuntu.com/ubuntu-ports/ $CODENAME-security main restricted universe multiverse

# Uncomment for source packages
# deb-src http://archive.ubuntu.com/ubuntu/ $CODENAME main restricted universe multiverse
# deb-src http://archive.ubuntu.com/ubuntu/ $CODENAME-updates main restricted universe multiverse
# deb-src http://archive.ubuntu.com/ubuntu/ $CODENAME-security main restricted universe multiverse
EOF

    save_current_version
    echo "✅ sources.list создан для $CODENAME"
}

# Системный сервис для авто-обновления (для systemd)
create_systemd_service() {
    if command -v systemctl >/dev/null 2>&1; then
        sudo tee /etc/systemd/system/apt-auto-config.service > /dev/null << EOF
[Unit]
Description=APT Sources Auto-Configuration
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/apt-auto-config.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

        sudo tee /etc/systemd/system/apt-auto-config.timer > /dev/null << EOF
[Unit]
Description=Check and update APT sources weekly
Requires=apt-auto-config.service

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

        sudo systemctl enable apt-auto-config.timer
        sudo systemctl start apt-auto-config.timer
    fi
}

main() {
    # Проверяем, изменилась ли версия
    if check_version_change && -n $1=='-f'; then
        echo "✅ Версия системы не изменилась"
    else
        echo "🔄 Обнаружена новая версия системы, обновляю sources.list..."
        create_auto_sources
    fi
    
    # Всегда обновляем списки пакетов
    echo "🔄 [ Start ] apt update"
    sudo apt update --fix-missing
    echo "✅ [ Finished ] apt update"
}

# Если скрипт запущен напрямую
if [ "$(basename "$0")" = "apt-auto-config.sh" ]; then
    main
fi
