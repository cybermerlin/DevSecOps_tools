#!/bin/sh

if [ "$(id -u)" -eq 0 ]; then
    echo "Nothing to do for [$(id -u)]. Login to a non-root user."
    exit 1
fi


if [ "$(ps -p 1 -o comm= | xargs)" = "systemd" ]; then
    echo "[systemd] are online. To be continue..."
else
    echo "[systemd] are offline. Prepare it..."
    #TODO: add script to start [systemd]
    exit 1
fi


# DBus is active?
if ! systemctl --user is-active dbus > /dev/null 2>&1; then
    echo ">>> dbus activating..."
    
    if ! apt list --installed 2>/dev/null | grep -q "dbus-user-session"; then
        sudo apt update && sudo apt install -y dbus-user-session
    else
        echo "No need to install packets"
    fi

    # Start the user bus
    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ] || [ ! -S "$XDG_RUNTIME_DIR/bus" ]; then
        echo "Start the user bus manually..."

        export XDG_RUNTIME_DIR=/run/user/$(id -u)
        sudo mkdir -p "$XDG_RUNTIME_DIR/bus"
        sudo chown -R $(id -u):$(id -g) "$XDG_RUNTIME_DIR/bus"
        echo "export XDG_RUNTIME_DIR=/run/user/$(id -u)" >> ~/.bashrc
        . ~/.bashrc
        if ! grep -q "dbus-launch" ~/.profile; then
            cat > ~/.profile <<EOF
# Automate DBus session for user services
if test -z "$DBUS_SESSION_BUS_ADDRESS"; then
    eval `dbus-launch --sh-syntax --exit-with-session`
fi
EOF
        fi
        
        # 1st try
        if [ ! -S "$XDG_RUNTIME_DIR/bus" ]; then
            echo "RUN 1st try..."
            /usr/bin/dbus-daemon --session --address=unix:path=$XDG_RUNTIME_DIR/bus --nofork --nopidfile --systemd-activation &
            sleep 1; alert
        fi
        if [ ! -S "$XDG_RUNTIME_DIR/bus" ]; then
            echo "FALL 1st try"
        fi
        
        # alternative try
        if ! systemctl --user is-active dbus >/dev/null 2>&1; then
            echo "RUN alt try..."

            echo $XDG_RUNTIME_DIR                   # should be `/run/user/1000`
            sudo loginctl enable-linger $(id -un)
            sudo systemctl restart systemd-logind
            eval `dbus-launch --sh-syntax --exit-with-session`
            # dbus-launch --sh-syntax --exit-with-session > ~/.dbus-env
            # . ~/.dbus-env
        fi

        if ! systemctl --user is-system-running --quiet 2>/dev/null; then
            /usr/lib/systemd/systemd --user &
            sleep 2; alert
        fi
        if ! systemctl --user is-system-running --quiet 2>/dev/null; then
            echo "FALL systemd running"
        fi

        mkdir -p ~/.config/systemd/user/
        if [ ! -e ~/.config/systemd/user/user-systemd.service ]; then
            cat > ~/.config/systemd/user/user-systemd.service <<EOF
[Unit]
Description=User Systemd Service (WSL Workaround)

[Service]
ExecStart=/usr/bin/systemd --user
Restart=always
EOF
        fi
        if [ ! -e ~/.config/systemd/user/dbus.service ]; then
            cat > ~/.config/systemd/user/dbus.service <<EOF
[Unit]
Description=D-Bus User Message Bus
After=systemd-user-sessions.service

[Service]
ExecStart=/usr/bin/dbus-daemon --session --address=systemd: --nofork --nopidfile --systemd-activation
Restart=on-failure
EOF
        fi
        
        # DBUS troubleshooting
        if ! systemctl --user is-active dbus >/dev/null 2>&1; then
            
            systemctl --user daemon-reload
            systemctl --user enable --now user-systemd.service
            systemctl --user restart user-systemd.service
            if ! systemctl --user is-active user-systemd.service > /dev/null 2>&1; then
                echo "(!) Not started user-scoped [systemd]"
                exit 1
            fi
        else
            echo "DBus is active. Checking around..."
            
            systemctl --user list-units     # Check services
            busctl --user status            # Check bus status
        
            echo "SUCCESS. [dbus, systemd] systems are online."
        fi

        if systemctl --user is-active dbus >/dev/null 2>&1; then
            echo "SUCCESS [dbus] is online"
            
            if ! grep -q "# Systemd user session initialization" ~/.bashrc; then
                cat > ~/.bashrc <<EOF
# Systemd user session initialization
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ] && [ "$(id -u)" -ne 0 ]; then
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
    if [ ! -S "$XDG_RUNTIME_DIR/bus" ]; then
        /usr/bin/dbus-daemon --session --address=unix:path=$XDG_RUNTIME_DIR/bus --nofork --nopidfile --systemd-activation &
        sleep 1; alert
    fi
    if ! systemctl --user is-system-running --quiet 2>/dev/null; then
        /usr/lib/systemd/systemd --user &
        sleep 1; alert
    fi
fi
EOF
            fi
            echo "SUCCESS started [dbus, systemd]   -->> w hot fix in ~/.bashrc"
            exit 0
        fi
    else
        if systemctl --user is-system-running --quiet 2>/dev/null; then
            echo "[systemd] is online."
        fi

        # DBUS troubleshooting
        if systemctl --user is-active dbus >/dev/null 2>&1; then
            echo "[dbus] is online."
        fi
    fi

    if ! pgrep -f "dockerd|containerd|rootless" > /dev/null 2>&1; then
        sudo loginctl enable-linger $(id -un)
        sudo systemctl restart systemd-logind
        systemctl --user start docker.service
        systemctl --user enable docker.service
    fi
    exit 0
fi
exit 0


if pgrep -f "dockerd|containerd|rootless" > /dev/null; then
    sudo pkill -9 -f "dockerd"
    sudo pkill -9 -f "containerd"
    sudo pkill -9 -f "docker-rootless"
    sudo pkill -9 -f "rootlesskit"

    systemctl --user stop docker.service
    systemctl --user disable docker.service
    systemctl --user mask docker.service
fi

if pgrep -f "dockerd|containerd|rootless" > /dev/null; then
    rm -f ~/.config/systemd/user/docker.service
    
    echo "(!) Reboot this system and run this script again"
    exit 0
fi

if [ -d "~/.local/share/docker" ]; then
    dockerd-rootless-setuptool.sh uninstall
    rm -rf ~/.local/share/docker
    rm -rf ~/.local/share/containerd

    sudo apt purge docker-ce docker-ce-cli containerd.io
    rm -rf ~/.docker
    rm -rf ~/.local/share/docker

    echo "(!) Reboot current system"
    echo "And then run this script again"
    exit 0
fi



# install
if [ ! -d "~/.local/share/docker" ]; then
    sudo apt install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    groupadd docker
    useradd docker -g docker
    # usermod -aG docker $USER
    # newgrp docker

    # rootless scenario
    sudo apt install -y dbus-user-session uidmap systemd-container docker-ce-rootless-extras fuse-overlayfs
    sudo apt remove -y docker docker-engine docker.io containerd runc
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl restart apparmor.service
    sudo systemctl disable --now docker.service docker.socket
    
    # try 1
    curl -fsSL https://get.docker.com/rootless | sh
    systemctl --user start docker
    systemctl --user enable docker

    # try 2
    sudo loginctl enable-linger $(whoami)
    dockerd --userns-remap="user:user"
    # dockerd-rootless-setuptool.sh install
    echo "export PATH=/usr/bin:/home/$(whoami)/bin:$PATH" >> ~/.bashrc
    echo "export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock" >> ~/.bashrc
    #echo "export XDG_RUNTIME_DIR=$HOME/.docker/xrd"
    echo "export XDG_RUNTIME_DIR=/run/user/$(id -u)" >> ~/.bashrc
    . ~/.bashrc
    echo $XDG_RUNTIME_DIR                   # should be `/run/user/1000`
    rm -rf $XDG_RUNTIME_DIR
    mkdir -p $XDG_RUNTIME_DIR

    if busctl --user list > /dev/null 2>&1; then
        if ! systemctl --user is-active dbus >/dev/null 2>&1; then
            systemctl --user restart user-systemd.service
        fi
        if ! systemctl --user is-active dbus >/dev/null 2>&1; then
            mkdir -p ~/.config/systemd/user/
            cat > ~/.config/systemd/user/user-systemd.service <<EOF
[Unit]
Description=User Systemd Service (WSL Workaround)

[Service]
ExecStart=/usr/bin/systemd --user
Restart=always
EOF
            
            systemctl --user restart user-systemd.service
            systemctl --user daemon-reload
            systemctl --user enable --now user-systemd.service
            if ! systemctl --user is-active user-systemd.service > /dev/null 2>&1; then
                echo "(!) Not started user systemd"
                exit 1
            fi
        fi
        
        systemctl --user daemon-reload          # Now try systemctl --user
        systemctl --user restart docker
        unshare --user --map-root-user --net --mount
        systemctl --user start docker.service
        systemctl --user enable docker.service
        systemctl --user start docker
    else
        nohup dockerd-rootless.sh > ~/.docker.log 2>&1 &
    fi

fi
