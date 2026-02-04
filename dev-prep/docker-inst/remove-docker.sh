#!/usr/bin/env sh
set -eu
set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")/../.." && pwd)"; set -u;
. "${ROOT}/common/colors.sh"


if [ "$(docker info 2>/dev/null | grep -i rootless | awk '{print $1}')" = "rootless" ] ||
    [ -d ~/.local/share/docker ]; then
    info "Installed docker-rootless"

    if systemctl --user is-active docker > /dev/null 2>&1; then
        # Stop the rootless Docker service
        systemctl --user stop docker
    fi

    dockerd-rootless-setuptool.sh uninstall
    rootlesskit rm -rf /home/user/.local/share/docker

    # Remove the rootless Docker binaries and data
    sudo rm -rf ~/.local/share/docker
    sudo rm -rf ~/.local/share/containerd
    sudo rm -rf ~/.config/docker
    sudo rm -rf ~/bin
    sudo rm -f ~/.local/bin/docker*
    sudo rm -f ~/.local/bin/containerd*
    sudo rm -f ~/.local/bin/ctr
    sudo rm -f ~/.local/bin/runc
    sudo rm -f ~/.local/bin/rootlesskit
    sudo rm -f ~/.local/bin/dockerd-rootless.sh
    sudo rm -f ~/.local/bin/dockerd-rootless-setuptool.sh
    rm -rf ~/.docker

    # Remove systemd service files
    rm -rf ~/.config/systemd/user/docker.*
    rm -rf ~/.config/systemd/user/default.target.wants/docker.service

    # Reload systemd user configuration
    systemctl --user daemon-reload

else
    info "Installed docker under root user."

    sudo systemctl stop docker docker.socket containerd
    sudo systemctl disable docker docker.socket containerd

    sudo apt autoremove -y --purge \
            docker \
            docker.io \
            docker-ce \
            docker-ce-cli \
            docker-ce-rootless-extras \
            docker-buildx-plugin \
            docker-compose-plugin \
            containerd.io \
            runc \
            docker-compose
    
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    sudo rm -rf /var/lib/docker-engine
    sudo rm -rf /etc/docker
    sudo rm -rf /var/run/docker
    sudo rm -rf /var/run/docker.sock
    sudo rm -rf /var/run/containerd
    sudo rm -rf /etc/apparmor.d/docker
    sudo rm -rf /etc/systemd/system/docker.service.d

    if getent group docker >/dev/null; then
        sudo gpasswd -d $USER docker
        sudo groupdel docker 2>/dev/null || { error "Could not remove docker group (may have users)"; exit 1; }
    fi

    sudo rm -f /etc/apt/sources.list.d/docker*.list
    sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg
    sudo rm -f /etc/apt/trusted.gpg.d/docker.gpg
    sudo rm -f /etc/systemd/system/docker.service
    sudo rm -f /etc/systemd/system/docker.socket
    sudo rm -f /lib/systemd/system/docker.service
    sudo rm -f /lib/systemd/system/docker.socket
    sudo rm -f /usr/lib/systemd/system/docker.service
    sudo rm -f /usr/lib/systemd/system/docker.socket

    sudo systemctl daemon-reload
    sudo systemctl reset-failed

    sudo rm -f /usr/local/bin/docker
    sudo rm -f /usr/local/bin/dockerd
    sudo rm -f /usr/local/bin/docker-compose


    # Remove Docker aliases from shell config
    sed -i '/alias docker/d' ~/.bashrc ~/.bash_profile ~/.zshrc 2>/dev/null
    # Remove Docker environment variables
    sed -i '/export DOCKER_/d' ~/.bashrc ~/.bash_profile ~/.zshrc 2>/dev/null
    sed -i '/export COMPOSE_/d' ~/.bashrc ~/.bash_profile ~/.zshrc 2>/dev/null
    # Remove docker from PATH if manually added
    sed -i 's|:[^:]*docker[^:]*||g' ~/.bashrc ~/.bash_profile ~/.zshrc 2>/dev/null
    # Reload shell
    . ~/.bashrc 2>/dev/null || . ~/.zshrc 2>/dev/null
fi
