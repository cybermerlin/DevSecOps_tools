#!/bin/sh
set -eu #o pipefail
# -e: exit on error
# -u: exit on undefined variable
# -o pipefail: exit on pipe failure
sudo chown -R $(id -u):$(id -u) ~/dev/admin
echo "Ver: 0.0.48"


# Run this cmd to sync admin tools from local machine to WSL
#   mkdir -p ~/dev/admin && time sudo rsync -av /mnt/f/dev/projects/admin/wsl-prep ~/dev/admin/ && cd ~/dev/admin/wsl-prep


# import
. ../common/colors.sh
. ../common/progress.sh
. ../common/handler.sh


fixnetwork() {
  ping ya.ru -A -c 3 || { echo "nameserver 9.9.9.9" | sudo tee /etc/resolv.conf; }
  ping ya.ru -A -c 3 || { error "Network connectivity test failed"; exit 1; }
}

test() {
  handler 'sleep 2' "Sleep" $1
}

prep() {
  local userprofile=$(wslpath "$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null)" | tr -d '\r')
  sudo cp -f .wslconfig ./.wslconfig ${userprofile}/
  
  sudo rm -rf /etc/apt/* || { error "Failed to clean apt directory"; exit 1; }
  sudo mkdir -p /etc/apt/apt.conf.d /etc/apt/sources.list.d /etc/apt/preferences.d /var/lib/apt/lists/partial /var/cache/apt/archives/partial
  sudo chmod -R 755 /etc/apt/
  handler 'sudo cp -r wsl-files/* /' "Copying wsl-files are accomplished" 10
  fixnetwork
  sudo rm -rf /root/dev/admin

  warning "Please reboot this system (`wsl --shutdown` in powershell)"
}

# for any troubles with APT - use [->prep() + ->fix()]
fix() {
    local _lvl=10

    fixnetwork

    handler 'sudo mkdir -p /etc/apt/trusted.gpg.d/ /etc/apt/keyrings/ /var/lib/apt/lists/partial /var/cache/apt/archives/partial' "Создание структуры директорий" $_lvl
    handler 'sudo chmod 755 /etc/apt/trusted.gpg.d/ /etc/apt/keyrings/' "Установка прав" $_lvl
    
    handler 'curl -fsSL http://archive.ubuntu.com/ubuntu/project/ubuntu-archive-keyring.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/ubuntu-archive.gpg' "Скачивание ключей Ubuntu" $_lvl
    progress_bar 5 "Ключи установлены"
    handler './apt-auto-config.sh -f' "Force recreate APT/sources.list" $_lvl

    # info "Скачиваем security ключи"
    # if curl -fsSL http://security.ubuntu.com/ubuntu/security.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/ubuntu-security.gpg 2>/dev/null; then
    #     success "Ключи безопасности установлены"
    # else
    #     error "Не удалось скачать ключи безопасности"
    #     exit 1
    # fi
    # 
    # info "Установка пакета ubuntu-keyring..."
    # sudo apt update --allow-unauthenticated -y
    # sudo apt install --allow-unauthenticated -y ubuntu-keyring
    # handler 'sudo apt update' "${_lvl}Проверка исправления" 30
    progress_bar 15 "исправление ключей APT"
    
    sudo rm -rf /var/lib/apt/lists/* || { error "${_lvl}Failed to clean apt directory"; exit 1; }
    sudo cp apt-auto-config.sh /usr/local/bin/
    sudo chmod +x /usr/local/bin/apt-auto-config.sh
    handler 'sudo /usr/local/bin/apt-auto-config.sh' "Run apt-auto-config" $_lvl
    progress_bar 30

    sudo groupadd --system polkitd
    sudo useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin --comment "polkitd user" --gid polkitd polkitd
    handler 'sudo systemctl reload dbus 2>/dev/null || true' "Reload the D-Bus configuration (if D-Bus is running)" $_lvl
    handler 'sudo dpkg --configure -a' "Configuring the dpkg" $_lvl
    handler 'sudo apt --fix-missing update' "APT fixes 1" $_lvl
    handler 'sudo apt --fix-broken install' "APT fixes 2" $_lvl
    handler 'sudo apt upgrade -y' "APT upgrade to apply fixes" $_lvl
    progress_bar 100
    
    warning "Please reboot this system (`wsl --shutdown` in powershell)"
}

upgrade() {
  local _lvl=10
  local has_new_ver=$(do-release-upgrade -c | grep -q "There is no development version")
  
  if $has_new_ver; then
    handler 'sudo snap refresh' "Update snap packages" $_lvl
    progress_bar 90 "Обновление завершено"
    handler 'clean main' "Cleanup after upgrade" $_lvl
    progress_bar 100 "Обновление завершено"
  else
    progress_bar 0 "Начало обновления"
    handler 'sudo apt update' "Обновление списка пакетов" $_lvl
    progress_bar 25 "Список обновлен"
    handler 'sudo apt upgrade -y' "Обновление пакетов" $_lvl
    progress_bar 50 "Пакеты обновлены"
    handler 'sudo apt full-upgrade -y' "Обновление зависимостей" $_lvl
    progress_bar 70 "Зависимости обновлены"
    
    warning "do-release-upgrade может запрашивать подтверждение"
    sudo rm -rf /etc/apt/sources.list
    handler 'sudo do-release-upgrade -m server' "Обновление релиза" $_lvl || { exit 1; }
    # At this line happens not so good. it's stuck on an old distrib...
    #   handler 'sudo do-release-upgrade -f DistUpgradeViewNonInteractive' "${_lvl}Обновление релиза - без интерактива"
    progress_bar 80 "Обновление завершено"
    warning "Please reboot this system (`wsl --shutdown` in powershell) \n AND restart this _cmd: `./ubuntu_upgrade.sh upgrade`"
  fi
}

git_prep() {
  info "Check and generate ssh keys for git" 20
  mkdir -p ~/.ssh
  [ -d "./secrets" ] && cp -r ./secrets/.ssh/* ~/.ssh/ || ssh-keygen -t rsa -b 4096 -C ${user.email} -N "" -f ~/.ssh/github;
  . ./secrets.sh

  info "Configuring git Credential Manager" 20
  git config --global user.email ${user.email}
  git config --global user.name ${user.name}
  git config --global credential.credentialStore cache
  # git config --global credential.helper manager
  git config --global credential.cacheOptions "--timeout 300"
  git config --global credential.gitHubAccountFiltering "false"
  git config --global credential.gitLabAuthModes "browser"

  if [ -z pgrep -a ssh-agent ] then
    info "running ssh-agent service..." 20
    
    if [ -z systemctl --user list-unit-files | grep ssh ] then
      info "making ssh-agen.service..." 20;

      mkdir -p ~/.config/systemd/user/
      tee ~/.config/systemd/user/ssh-agent.service > /dev/null < EOF
[Unit]
Description=SSH key agent
Wants=default.target

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

[Install]
WantedBy=default.target
EOF
      systemctl --user enable ssh-agent
      systemctl --user start ssh-agent
    fi
    
    # Auto SSH-AUTH_SOCK setup
    if [ -z "$SSH_AUTH_SOCK" ]; then
        info "have no SSH_AUTH_SOCK" 20
        # Try XDG_RUNTIME_DIR first (systemd user service)
        if [ -n "$XDG_RUNTIME_DIR" ] && [ -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]; then
            info 'have no $XDG_RUNTIME_DIR/ssh-agent.socket' 20
            export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
        # Try to find any existing ssh-agent socket
        elif sockets=$(find /tmp/ssh-* -user "$USER" -name "agent.*" 2>/dev/null); then
            export SSH_AUTH_SOCK=$(echo "$sockets" | head -n1)
        # Fallback: start new agent if nothing found
        # else
        #     eval "$(ssh-agent -s)" > /dev/null
        fi
    fi
    # eval "$(ssh-agent -s)"
  fi
  ssh-add ~/.ssh/github
}

inst_base() {
  warning "Do not forget to press N on question about replacing updatedb.conf from installation package!"
  
  sudo apt install -y htop mc git plocate screen || { exit 1; }
  sudo updatedb&
  handler 'git_prep' "Prepare Git..." 10
  
  handler 'clean main' "Cleaning after installation" 10
}

clean() {
  local _cmd="${1:-}"

  ../cleaner/freeup.sh ${_cmd}
}


case "${1}" in
  test)
      handler "test ${2}" "Run test"
      ;;
  prep)
      prep
      info "Next step ->fix()"
      ;;
  fix)
      handler 'fix' "Fixes"
      info "Next step ->upgrade()"
      ;;
  upgrade)
      handler 'upgrade' "Upgrade"
      info "Next step ->upgrade() and then ->inst()"
      ;;
  inst)
      handler 'inst_base' "Install base packages" || { error "Try to use `-> fix()`"; exit 1; };;
  clean)
      handler 'clean' "Clean up";;
  *)
      warning 'Undefined parameter'
      ;;
esac
