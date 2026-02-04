#!/usr/bin/env sh
set -eu
set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")" && pwd)/../.."; set -u

# import
. "${ROOT}/common/colors.sh"
. "${ROOT}/common/progress.sh"
. "${ROOT}/common/handler.sh"

if [ "$(id -u)" -eq 0 ]; then
    error "Nothing to do for [$(id -u)]. Login to a non-root user."
    exit 1
fi

_ARCH=$(uname -m)
case "$_ARCH" in
    x86_64) _BUILDX_ARCH="amd64" ;;
    aarch64) _BUILDX_ARCH="arm64" ;;
    armv7l) _BUILDX_ARCH="arm-v7" ;;
    *)
        error "Unsupported architecture: $_ARCH"
        exit 1
        ;;
esac

_UID=$(id -u)

{
    docker -v >/dev/null 2>&1 &&
    docker info > /dev/null 2>&1
} || {
    # `which newuidmap dbus-daemon`
    if apt list --installed 2>/dev/null | grep -q "^uidmap/" \
    && apt list --installed 2>/dev/null | grep -q "^dbus-user-session/"; then
        success "dbus, uidmap - installed"
    else
        handler 'sudo apt update; sudo apt install -y uidmap dbus-user-session' "Install `dbus` dependencies"
    fi

    if systemctl list-unit-files | grep docker > /dev/null 2>&1; then
        handler 'sudo systemctl stop docker; sudo systemctl disable docker' "Stop docker service"
    fi

    mkdir -p ~/.config/docker/daemon.json
    cat > ~/.config/docker/daemon.json <<EOF
{
  "ipv6": true,
  "fixed-cidr-v6": "fd00:d0ca:1::/64",
  "experimental": true,
  "ip6tables": true
}
EOF

    info "[ start ] getting and executing rootless script..."
    # unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY
    curl -fsSL https://get.docker.com/rootless | sh || {
        curl --noproxy '*' -fsSL https://get.docker.com/rootless | sh || exit 1
    }
    if ! printf %s "${PATH}" | grep -q "${HOME}/bin:"; then
        export PATH="${HOME}/bin:${PATH}"
    fi
    success "[ finished ] getting and executing rootless script..."

    info "[ start ] applying docker service to start..."
    handler 'sudo loginctl enable-linger "$(whoami)"' 'loginctl enabling...' 10
    
    info '[ start ] prepare to start service...' 10
    if [ ! -d "$XDG_RUNTIME_DIR" ]; then
      sudo mkdir -p $XDG_RUNTIME_DIR
      sudo chmod 0700 $XDG_RUNTIME_DIR
      sudo chown ${_UID}:${_UID} $XDG_RUNTIME_DIR
    fi
    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
        eval $(dbus-launch --sh-syntax)
    fi
    systemd --user &
    success '[ finished ] prepare to start service...' 10
    
    systemctl --user enable --now docker || {
        . "${HOME}/.bashrc"
        dockerd-rootless-setuptool.sh install
        systemctl --user enable --now docker
    }
    
    success "[ finished ] applying docker service to start..."
}

_DOCKER_CONFIG=${_DOCKER_CONFIG:-${HOME}/.docker}
    
docker compose version >/dev/null 2>&1 || {
    info '[ start ] docker compose Installing...'
    mkdir -p "$_DOCKER_CONFIG/cli-plugins"
    curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
        -o "$_DOCKER_CONFIG/cli-plugins/docker-compose"
    chmod +x "$_DOCKER_CONFIG/cli-plugins/docker-compose"
    # sudo apt  install docker-compose -y
    success '[ finished ] docker compose Installing...'
}

docker buildx version >/dev/null 2>&1 || {
    info "[ start ] installing docker buildx..."
    _LATEST_TAG=$(curl -s https://api.github.com/repos/docker/buildx/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    echo "${_LATEST_TAG}"
    if [ -z "${_LATEST_TAG}" ]; then
        error "Failed to get latest buildx version" 10
        exit 1
    fi
    _BUILDX_URL="https://github.com/docker/buildx/releases/download/${_LATEST_TAG}/buildx-${_LATEST_TAG}.linux-${_BUILDX_ARCH}"
    justSay "${_BUILDX_URL}" 10
    # _BUILDX_URL="https://github.com/docker/buildx/releases/latest/download/buildx-linux-${_BUILDX_ARCH}"
    curl -SL "${_BUILDX_URL}" -o "${_DOCKER_CONFIG}/cli-plugins/docker-buildx"
    justSay "${_DOCKER_CONFIG}/cli-plugins/docker-buildx" 10
    chmod +x "${_DOCKER_CONFIG}/cli-plugins/docker-buildx"
    success "[ finished ] installing docker buildx..."

    info "[ start ] setting up buildx default builder..."
    docker buildx create --use --name=default 2>/dev/null || true
    if [ ! -f "${HOME}/bin/docker-build-wrapper" ] || [ ! -s "${HOME}/bin/docker-build-wrapper" ]; then
        cat > "${HOME}/bin/docker-build-wrapper" << 'EOF'
#!/usr/bin/env sh
if [ "$1" = "build" ]; then
    shift
    exec docker buildx build "$@"
else
    exec docker "$@"
fi
EOF
        chmod +x "${HOME}/bin/docker-build-wrapper"
        if [ -f "${HOME}/.bashrc" ]; then
            if ! grep -q "alias docker=" "${HOME}/.bashrc"; then
                echo "alias docker='${HOME}/bin/docker-build-wrapper'" >> "${HOME}/.bashrc"
            fi
        fi
    fi
    success "[ finished ] setting up buildx default builder..."

    info "You can use docker-buildx through Dockerfile:"
    justSay << EOF
FROM docker
COPY --from=docker/buildx-bin /buildx /usr/libexec/docker/cli-plugins/docker-buildx
RUN ["docker", "buildx", "version"]
EOF
}

#sudo mkdir /sys/fs/cgroup/systemd
#sudo mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd

info "Check docker out..."
echo "${GREEN}"
{
    docker -v &&
    sleep 10; docker info > /dev/null 2>&1 &&
    docker compose version &&
    docker buildx version &&
    docker buildx ls >/dev/null 2>&1 &&
    docker run --rm hello-world >/dev/null 2>&1
} && success "All docker tools in access" || { error "One or more Docker checks failed"; exit 1; }
echo "${NC}"
