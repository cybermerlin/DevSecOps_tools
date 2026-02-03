#!/usr/bin/env sh
set -eu


# Run this cmd to sync admin tools from local machine to WSL
#   mkdir -p ~/dev/admin && time sudo rsync -av /mnt/f/dev/projects/admin/wsl-prep ~/dev/admin/ && cd ~/dev/admin/wsl-prep


# import
set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"; set -u;
. "${ROOT}/common/colors.sh"
. "${ROOT}/common/progress.sh"
. "${ROOT}/common/handler.sh"

_USERPROFILE=$(wslpath "$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null)" | tr -d '\r')


fixnetwork() {
  ping ya.ru -A -c 3 >/dev/null || { echo 'fixing...'; echo "nameserver 9.9.9.9" | sudo tee /etc/resolv.conf; }
  ping ya.ru -A -c 3 >/dev/null || { error "Network connectivity test failed"; exit 1; }
}

test() {
  handler 'sleep 2' "Sleep" $1
}

wslconfiguration() {
  sudo cp -f ${ROOT}/wsl-prep/.wslconfig ${_USERPROFILE}/

  warning "Please reboot this system ('wsl --shutdown' in powershell)"
#   powershell.exe -Command "wsl --shutdown"
}

prep() {
  mkdir -p ~/dev/admin ~/cli
  sudo chown -R "$(id -u):$(id -u)" ~/dev/admin
  cp ${ROOT}/tools/sync-history.sh ~/cli/sync-history.sh
  chmod -R +x ~/cli/

  sudo rm -rf /etc/apt/* || { error "Failed to clean apt directory"; exit 1; }
  sudo mkdir -p /etc/apt/apt.conf.d /etc/apt/sources.list.d /etc/apt/preferences.d /var/lib/apt/lists/partial /var/cache/apt/archives/partial
  sudo chmod -R 755 /etc/apt/
  handler "sudo cp -r ${ROOT}/wsl-prep/wsl-files/* /" "Copying wsl-files are accomplished" 10
  fixnetwork
  sudo rm -rf /root/dev/admin

  sudo apt update
  sudo apt install locales -y
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  sudo dpkg-reconfigure locales

  warning "Please reboot this system ('wsl --shutdown' in powershell)"
#   powershell.exe -Command "wsl --shutdown"
}

# for any troubles with APT - use [->prep() + ->fix()]
fix() {
    _lvl=10

    fixnetwork

    handler 'sudo mkdir -p /etc/apt/trusted.gpg.d/ /etc/apt/keyrings/ /var/lib/apt/lists/partial /var/cache/apt/archives/partial' "Создание структуры директорий" $_lvl
    handler 'sudo chmod 755 /etc/apt/trusted.gpg.d/ /etc/apt/keyrings/' "Установка прав" $_lvl

    handler 'curl -fsSL http://archive.ubuntu.com/ubuntu/project/ubuntu-archive-keyring.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/ubuntu-archive.gpg' "Скачивание ключей Ubuntu" $_lvl
    progress_bar 5 "Ключи установлены"

    handler "${ROOT}/wsl-prep/apt-auto-config.sh -f" "Force recreate APT/sources.list" $_lvl
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

    sleep 1
    sudo rm -rf /var/lib/apt/lists/* || { error "${_lvl}Failed to clean apt directory"; exit 1; }
    sudo cp "${ROOT}/wsl-prep/apt-auto-config.sh" /usr/local/bin/
    sudo chmod +x /usr/local/bin/apt-auto-config.sh
    handler 'sudo /usr/local/bin/apt-auto-config.sh' "Run apt-auto-config" $_lvl
    progress_bar 30

    sudo groupadd --system polkitd 2>/dev/null || true
    sudo useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin --comment "polkitd user" --gid polkitd polkitd 2>/dev/null || true
    handler 'sudo systemctl reload dbus 2>/dev/null || true' "Reload the D-Bus configuration (if D-Bus is running)" $_lvl
    handler 'sudo dpkg --configure -a' "Configuring the dpkg" $_lvl
    sleep 1
    handler 'sudo apt --fix-missing update' "APT fixes 1" $_lvl
    handler 'sudo apt --fix-broken install' "APT fixes 2" $_lvl
    sleep 1
    handler 'sudo apt upgrade -y' "APT upgrade to apply fixes" $_lvl

    handler 'sudo apt install -y needrestart debian-goodies kexec-tools' 'Install tools for rebooting wo rebooting' $_lvl
    sudo dpkg-reconfigure kexec-tools   # choose “Yes”
    progress_bar 100

    warning "Please reboot this system ('wsl --shutdown' in powershell)"
}

# reset all services instead of reboot the system (use after upgrading)
reset_wo_reboot() {
    sudo systemctl daemon-reexec
    services="rsyslog cron apparmor dbus networking procps ssh"
    for svc in $services; do
        systemctl is-active -q "$svc" && systemctl restart "$svc"
    done
    needrestart -r a 2>/dev/null || checkrestart 2>/dev/null || true

    # sudo kexec -l /boot/vmlinuz-$(uname -r) \
    #        --initrd=/boot/initrd.img-$(uname -r) \
    #        --command-line="$(cat /proc/cmdline)" \
    #        --reuse-cmdline
    # sudo kexec -e          # immediate jump, no confirmation
    sudo systemctl kexec   # same as above, but via systemd
}

upgrade() {
  _lvl=10
  has_new_ver=$(do-release-upgrade -c | grep -q "There is no development version")

  if $has_new_ver; then
    handler 'sudo snap refresh' "Update snap packages" $_lvl
    progress_bar 90 "Обновление завершено"
    handler 'clean main' "Cleanup after upgrade" $_lvl
    progress_bar 100 "Обновление завершено"
  else
    progress_bar 0 "Начало обновления"
    handler 'sudo apt update -qq' "Обновление списка пакетов" $_lvl
    progress_bar 25 "Список обновлен"
    handler 'sudo apt upgrade -y' "Обновление пакетов" $_lvl
    progress_bar 50 "Пакеты обновлены"
    handler 'DEBIAN_FRONTEND=noninteractive sudo apt full-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"' "Обновление зависимостей" $_lvl
    reset_wo_reboot
    progress_bar 70 "Зависимости обновлены"

    warning "do-release-upgrade может запрашивать подтверждение"
    sudo rm -rf /etc/apt/sources.list
    handler 'sudo do-release-upgrade -m server' "Обновление релиза" $_lvl || { exit 1; }
    # At this line happens not so good. it's stuck on an old distrib...
    #   handler 'sudo do-release-upgrade -f DistUpgradeViewNonInteractive' "${_lvl}Обновление релиза - без интерактива"
    reset_wo_reboot
    progress_bar 80 "Обновление завершено"

    warning "Please reboot this system ('wsl --shutdown' in powershell) \n AND restart this _cmd: `./ubuntu_upgrade.sh upgrade`"
  fi
}

git_prep() {
  info "Check and generate ssh keys for git" 20
  mkdir -p ~/.ssh
  . "${ROOT}/secrets/secrets.sh"
  ([ -d "${ROOT}/secrets" ] && cp -r "${ROOT}/secrets/.ssh/*" ~/.ssh/) || ssh-keygen -t rsa -b 4096 -C "${useremail}" -N "" -f ~/.ssh/github;

  info "Configuring git Credential Manager" 20
  git config --global user.email "${useremail}"
  git config --global user.name "${username}"
  git config --global credential.credentialStore cache
  # git config --global credential.helper manager
  git config --global credential.cacheOptions "--timeout 300"
  git config --global credential.gitHubAccountFiltering "false"
  git config --global credential.gitLabAuthModes "browser"
  git config --global init.defaultBranch master

  if [ -z "$(pgrep -a ssh-agent)" ]; then
    info "running ssh-agent service..." 20

    if [ -z "$(systemctl --user list-unit-files | grep ssh)" ]; then
      info "making ssh-agen.service..." 20;

      mkdir -p ~/.config/systemd/user/
      _TMPDIR=$(mktemp -d)
      touch "$_TMPDIR/sshass"
      trap 'rm -rf "$_TMPDIR"' EXIT
      tee "$_TMPDIR/sshass" <<EOF
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
      tee ~/.config/systemd/user/ssh-agent.service > /dev/null < "${_TMPDIR}/sshass"
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
            export SSH_AUTH_SOCK="$(echo "$sockets" | head -n1)"
        # Fallback: start new agent if nothing found
        # else
        #     eval "$(ssh-agent -s)" > /dev/null
        fi
    fi
    # eval "$(ssh-agent -s)"
  fi
  eval "$(ssh-agent -s)" && ssh-add ~/.ssh/github
}

inst_base() {
  warning "Do not forget to press N on question about replacing updatedb.conf from installation package!"

  sudo apt install -y flatpak htop || { exit 1; }
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install flathub git mc screen plocate || { exit 1; }
  sudo updatedb&
  handler 'git_prep' "Prepare Git..." 10
  handler 'clean main' "Cleaning after installation" 10
}

# how to use more isolations for apps [too old?]
tryFlatseal() {
  flatpak install flathub com.github.tchx84.Flatseal -y
  # CLI equivalent for reference
  flatpak override --nofilesystem=home com.visualstudio.code
  flatpak override --filesystem=xdg-documents com.visualstudio.code
}

# Install dev tools (VS Code, Git, etc.) to ~/.bashrc
#
# This function is intended to be used by the main script (run.sh) and
# should not be called directly.
# This function modifies the ~/.bashrc file by isolating the dev tools
# section into a region that can be easily modified or removed.
#
# Note: This function depends on the availability of the "awk" command.
#
# Usage:
#   code_bashrc
code_bashrc() {
  # Set up section markers
  _section_start="#region Dev tools section"
  _section_end="#endregion Dev tools section"
  
  # Create temporary file
  _tmpfile="$(mktemp 2>/dev/null || echo "/tmp/bashrc.$$")"
  trap 'rm -f "${_tmpfile}"' EXIT
  # cut section from .bashrc
  if [ -f ~/.bashrc ]; then
      # Remove our section if it exists
      awk -v start="${_section_start}" -v end="${_section_end}" '
          $0 ~ start { in_section=1; next }
          $0 ~ end && in_section { in_section=0; next }
          !in_section { print }
      ' ~/.bashrc > "${_tmpfile}" || return 1
  fi

  # Add our section
  # echo "${_section_start}" >> "${_tmpfile}"
  # echo "\n# VS Code in Docker with X11 support" >> "${_tmpfile}"
  # echo 'xhost +local:docker >/dev/null 2>&1 || true' >> "${_tmpfile}"
  # echo 'alias code="docker run --rm \
  #         -v \"$(pwd):/workspace\" -w /workspace -v /tmp/.X11-unix:/tmp/.X11-unix \
  #         -e DISPLAY=$DISPLAY \
  #         -v $HOME/.Xauthority:/root/.Xauthority:ro \
  #         $([ -e /dev/dri ] && echo \"--device /dev/dri\") \
  #         linuxserver/code-server \
  #         code --user-data-dir=/config"' >> "${_tmpfile}"
  # echo "${_section_end}" >> "${_tmpfile}"

  echo "${_section_start}" >> "${_tmpfile}"
  echo "\n# VS Code in Docker with X11 support" >> "${_tmpfile}"
  echo 'xhost +local:docker >/dev/null 2>&1 || true' >> "${_tmpfile}"
  echo 'alias code="docker run --rm \
          -v \"\$(pwd):/workspace\" -w /workspace \
          -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY \
          -v $HOME/.Xauthority:/root/.Xauthority:ro \
          --device=/dev/dri:rw 2>/dev/null || true \
          mcr.microsoft.com/devcontainers/base:ubuntu \
          bash -c \"apt update && apt install -y code code-vscode && exec code --user-data-dir=/config \""' >> "${_tmpfile}"
  echo "${_section_end}" >> "${_tmpfile}"

  # vs.code as code-server to use it in a browser or in vs.code desktop client through a connection
  # echo 'alias code="docker run -it --rm \
  #       -v \"$(pwd):/workspace\" -w /workspace -v /tmp/.X11-unix:/tmp/.X11-unix \
  #       -e DISPLAY=$DISPLAY -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
  #       -v $HOME/.Xauthority:/root/.Xauthority:ro \
  #       --entrypoint /bin/sh codercom/code-server:latest \
  #       -c \"code-server --bind-addr 0.0.0.0:8080 --auth none && exec bash\""' >> ~/.bashrc

  # Verify the content
  if ! grep -q "${_section_start}" "${_tmpfile}" || ! grep -q "${_section_end}" "${_tmpfile}"; then
      error "Error: Failed to generate configuration" >&2
      return 1
  fi
  # Create backup and replace
  if [ -f ~/.bashrc ]; then
      cp ~/.bashrc ~/.bashrc.bak
  fi
  mv "${_tmpfile}" ~/.bashrc
}

# Install Vs.Code and all around needest.
inst_code() {
  code_bashrc

  # Apply X11 settings for current session
  xhost +local:docker >/dev/null 2>&1 || true

  #region flatpak install flathub com.visualstudio.code
  # flatpak install flathub com.visualstudio.code -y
  # 
  # # File access (adjust as needed)
  # flatpak override --filesystem=home com.visualstudio.code
  # # Network/portal access for extensions
  # flatpak override --talk-name=org.freedesktop.portal.* com.visualstudio.code
  # 
  # echo "alias code='flatpak run com.visualstudio.code'" >> ~/.bashrc
  #endregion flatpak

  # Reload .bashrc
  . ~/.bashrc
}

clean() {
  _cmd="${1:-}"

  ../cleaner/freeup.sh ${_cmd}
}


setAsNAT() {
  sudo cp -f ${ROOT}/wsl-prep/wsl-nat/.wslconfig ${_USERPROFILE}/

  ip addr show
  ip route

  # Включить пересылку пакетов
  # sudo sysctl -w net.ipv4.ip_forward=1
  # sudo echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
  CONFIG_FILE="/etc/sysctl.conf"
  FORWARD_LINE="net.ipv4.ip_forward=1"
  # Using sed to remove the # symbol and any spaces before it in the line with ip_forward
  sudo sed -i 's/^[[:space:]]*#\?[[:space:]]*net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' "$CONFIG_FILE" >/dev/null 2>&1
  # Apply changes immediately (without rebooting)
  sudo sysctl -p

  # Настроить NAT (маскарадинг) на исходящем интерфейсе eth0
  sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

  # Разрешить прохождение трафика (forwarding)
  if ! ip addr show eth1 >/dev/null 2>&1; then
    error "Reboot this system or add eth1 as [bridge]. And rerun this script again."
    exit 1
  fi
  sudo iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
  sudo iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT

  fixnetwork
  warning 'Please reboot this system'
}


case "${1:-}" in
  full)
    handler 'prep' 'Prepare'
    handler 'fix' 'Fix'
    handler 'upgade' 'Upgrade'
    handler 'inst' 'Install base software' || { error "Try to use '-> fix()'"; exit 1; }
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
      handler 'inst_base' "Install base packages" || { error "Try to use '-> fix()'"; exit 1; };;

  clean) handler 'clean' "Clean up" ;;

  inst_registry) handler 'inst_registry' 'Install local registry...' ;;
  inst_code) handler 'inst_code' "Install coder IDE and tools" ;;
  gitprep) handler 'git_prep' "Git prep" ;;
  nat) handler 'setAsNAT' 'Run [setAsNAT] to preset this system as NAT router' ;;
  wslconf) handler 'wslconfiguration' 'Run copying .wslconfig to win-host' ;;
  fixnetwork) handler 'fixnetwork' 'Run fix network';;
  test) handler "test ${2}" "Run test";;

  *) warning 'Undefined parameter';;
esac
