#!/usr/bin/env sh
set -eu

set +u; [ -n "${ROOT:-}" ] || export ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"; set -u
. "${ROOT}/common/colors.sh"

case "$(ps -o cmd= -p $PPID 2>/dev/null | head -1 | awk '{print $2}')" in
  *"run.sh"*) ;;
  *) error "Run this script only through 'run.sh conf ..'"; exit 1;;
esac


_mode="${1:-write}"
_host="${2:-localhost}"
_out="${3:-${ROOT}/registry/out}"

_docker_url="${DOCKER_PROXY_URL}"
_apt_proxy_url="${APT_PROXY_URL}"
_npm_registry_url="${NPM_PROXY_URL}"
_pypi_index_url="${PYPI_PROXY_URL}"
_maven_mirror_url="${MVN_PROXY_URL}"

_DOCKER_CONF_DIR="${HOME}/.config/docker"
_DOCKER_DAEMON_FILE="${_DOCKER_CONF_DIR}/daemon.json"
_M2SETTINGS="${HOME}/.m2/settings.xml"
_PIPCONF="${HOME}/.pip/pip.conf"
_NPMRC="${HOME}/.npmrc"
_SNAP_CONFIG_FILE="/etc/systemd/system/snapd.service.d/snap_proxy.conf"

mkdir -p "${_out}"


#  TODO: sync by apply_host()
write_files() {
#region write_files() {
  mkdir -p "${_out}/apt" "${_out}/npm" "${_out}/pip" "${_out}/maven ${_out}/docker"

  cat > "${_out}/apt/01aptcache" <<EOF
Acquire::http::Proxy "${_apt_proxy_url}";
Acquire::https::Proxy "false";
EOF

  cat > "${_out}/docker/daemon.json" <<EOF
{
  "insecure-registries" : ["${_docker_url}"],
  "registry-mirrors": ["${_docker_url}"]
}
EOF

  cat > "${_out}/npm/.npmrc" <<EOF
registry=${_npm_registry_url}
EOF

  cat > "${_out}/pip/pip.conf" <<EOF
[global]
index-url = ${_pypi_index_url}
trusted-host = ${_host}
EOF

  cat > "${_out}/maven/settings.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <mirrors>
    <mirror>
      <id>registry-mirror</id>
      <name>Local registry mirror</name>
      <url>${_maven_mirror_url}</url>
      <mirrorOf>*</mirrorOf>
    </mirror>
  </mirrors>
</settings>
EOF

  success "Wrote config snippets to ${_out}" 10
  info "APT: ${_out}/apt/01aptcache" 10
  info "npm: ${_out}/npm/.npmrc" 10
  info "pip: ${_out}/pip/pip.conf" 10
  info "maven: ${_out}/maven/settings.xml" 10
#endregion write_files() {
}


reset_host() {
#region reset_host() {
  info "Reset host configs (writes /etc/apt and your HOME dotfiles)."
  #region APT
  if [ -e /etc/apt/apt.conf.d/01aptcache ]; then
    sudo mv /etc/apt/apt.conf.d/01aptcache /etc/apt/apt.conf.d/01aptcache.disabled
  fi

  if [ -e /etc/apt/sources.list.bak ]; then
    sudo mv /etc/apt/sources.list.bak /etc/apt/sources.list
  else
    sudo sed -i "s|${_apt_proxy_url}/archive.ubuntu.com|http://archive.ubuntu.com|g" /etc/apt/sources.list
    sudo sed -i "s|${_apt_proxy_url}/security.ubuntu.com|http://security.ubuntu.com|g" /etc/apt/sources.list
  fi

  if [ -e ~/.bashrc.bak ]; then
    mv ~/.bashrc.bak ~/.bashrc
  else
    # sed -i "s|${_apt_proxy_url}||g" ~/.bashrc
    sed -i "/export http_proxy=/d" ~/.bashrc
    sed -i "/export https_proxy=/d" ~/.bashrc
  fi

  if [ -f "${_SNAP_CONFIG_FILE}.bak" ]; then
    sudo mv "${_SNAP_CONFIG_FILE}.bak" "${_SNAP_CONFIG_FILE}"
  fi
  #endregion APT
  
  if [ -e "${_PIPCONF}.bak" ]; then
    mv "${_PIPCONF}.bak" "${_PIPCONF}"
  elif [ -e "${_PIPCONF}" ]; then
    rm "${_PIPCONF}"
  fi
  if [ -e "${_M2SETTINGS}.bak" ]; then
    mv "${_M2SETTINGS}.bak" "${_M2SETTINGS}"
  elif [ -e "${_M2SETTINGS}" ]; then
    rm "${_M2SETTINGS}"
  fi
  if [ -e "${_NPMRC}.bak" ]; then
    mv "${_NPMRC}.bak" "${_NPMRC}"
  elif [ -e "${_NPMRC}" ]; then
    rm "${_NPMRC}"
  fi
  if [ -e "${_DOCKER_DAEMON_FILE}.bak" ]; then
    mv "${_DOCKER_DAEMON_FILE}.bak" "${_DOCKER_DAEMON_FILE}"
    if [ -f ~/.config/systemd/user/docker.service.d/http-proxy.conf.bak ]; then
      mv ~/.config/systemd/user/docker.service.d/http-proxy.conf.bak ~/.config/systemd/user/docker.service.d/http-proxy.conf
    fi
    systemctl --user restart docker
  fi
  success "Reset host configs (writes /etc/apt and your HOME dotfiles)." 10
#endregion reset_host() {
}


apply_host() {
#region apply_host() {
  #region APT
  info "APT configuring..." 5
  # TODO: ------------------------------>> [ ]       find how to use    apt-cacher-ng
  if [ -f /etc/apt/apt.conf.d/01aptcache ]; then
    sudo rm /etc/apt/apt.conf.d/01aptcache
  fi
  sudo mkdir -p /etc/apt/apt.conf.d || true
  sudo tee /etc/apt/apt.conf.d/01aptcache > /dev/null <<EOF
Acquire::http::Proxy "${_apt_proxy_url}";
Acquire::https::Proxy "${_apt_proxy_url}";
EOF

  # sudo cp /etc/apt/sources.list "/etc/apt/sources.list.bak"
  # sudo sed -i "s|http://[a-z0-9\.]*\.archive\.ubuntu\.com|${_apt_proxy_url}/archive.ubuntu.com|g" /etc/apt/sources.list
  # sudo sed -i "s|http://security\.ubuntu\.com|${_apt_proxy_url}/security.ubuntu.com|g" /etc/apt/sources.list

  if ! grep -q "http_proxy=" ~/.bashrc; then
    cp ~/.bashrc ~/.bashrc.bak
    echo "export http_proxy=\"${_apt_proxy_url}\"" >> ~/.bashrc
    echo "export https_proxy=\"${_apt_proxy_url}\"" >> ~/.bashrc
    echo "export no_proxy=\"localhost,127.0.0.1\"" >> ~/.bashrc
  fi
  # sudo apt install -y squid-deb-proxy-client # install it to Proxy Auto Configure (used avahi-daemon)
  sudo apt clean
  sudo apt update -o Debug::Acquire::http=true
  
  info "snap proxy conf..." 10
  sudo mkdir -p /etc/systemd/system/snapd.service.d/
  if [ ! -f "${_SNAP_CONFIG_FILE}" ]; then
    sudo cat > /etc/systemd/system/snapd.service.d/snap_proxy.conf <<EOF
[Service]
Environment="http_proxy=${_apt_proxy_url}"
Environment="https_proxy=${_apt_proxy_url}"
EOF
  else
    sudo cp "${_SNAP_CONFIG_FILE}" "${_SNAP_CONFIG_FILE}.bak"
    if sudo grep -q '^Environment="http_proxy=' "${_SNAP_CONFIG_FILE}"; then
        sudo sed -i "s|^Environment=\"http_proxy=.*|Environment=\"http_proxy=${_apt_proxy_url}\"|" "${_SNAP_CONFIG_FILE}"
    else
        sudo sed -i "/^\[Service\]/a Environment=\"http_proxy=${_apt_proxy_url}\"" "${_SNAP_CONFIG_FILE}"
    fi
    if sudo grep -q '^Environment="https_proxy=' "${_SNAP_CONFIG_FILE}"; then
        sudo sed -i "s|^Environment=\"https_proxy=.*|Environment=\"https_proxy=${_apt_proxy_url}\"|" "${_SNAP_CONFIG_FILE}"
    else
        sudo sed -i "/^\[Service\]/a Environment=\"https_proxy=${_apt_proxy_url}\"" "${_SNAP_CONFIG_FILE}"
    fi
  fi
  sudo systemctl daemon-reload
  sudo systemctl restart snapd
  sudo systemctl show snapd --property=Environment --no-pager
  #endregion APT

  mkdir -p "${HOME}/.config/docker" "${HOME}/.docker" "${HOME}/.config/systemd/user/docker.service.d" "${HOME}/.pip" "${HOME}/.m2" || true

  #region docker
  info "Docker configurating" 5
  info "1. Initialize file if missing or empty" 10
  if [ ! -s "${_DOCKER_DAEMON_FILE}" ]; then
    echo "{}" > "${_DOCKER_DAEMON_FILE}"
  else
    cp "${_DOCKER_DAEMON_FILE}" "${_DOCKER_DAEMON_FILE}.bak"
  fi
  mkdir -p ~/.config/systemd/user/docker.service.d
  if [ -f ~/.config/systemd/user/docker.service.d/http-proxy.conf ]; then
    cp ~/.config/systemd/user/docker.service.d/http-proxy.conf ~/.config/systemd/user/docker.service.d/http-proxy.conf.bak
  fi
  cat > ~/.config/systemd/user/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=${_docker_url}"
Environment="HTTPS_PROXY=${_docker_url}"
Environment="NO_PROXY=localhost,127.0.0.1"
EOF

  info "2. Inject insecure-registries if not present" 10
  # This regex looks for the key. If missing, it adds it before the final brace.
  if ! grep -q "insecure-registries" "${_DOCKER_DAEMON_FILE}"; then
    sed -i "s|}|  \"insecure-registries\": [\"${_docker_url}\"],\n}|" "${_DOCKER_DAEMON_FILE}"
  else
    info "If key exists, ensure our host is in the list (simple append)" 15
    if ! grep -q "${_docker_url}" "${_DOCKER_DAEMON_FILE}"; then
      sed -i "/insecure-registries/ s/\[/\[\"${_docker_url}\", /" "${_DOCKER_DAEMON_FILE}"
    fi
  fi

  info "3. Inject/Overwrite registry-mirrors" 10
  if ! grep -q "registry-mirrors" "${_DOCKER_DAEMON_FILE}"; then
    sed -i "s|}|  \"registry-mirrors\": [\"${_docker_url}\"]\n}|" "${_DOCKER_DAEMON_FILE}"
  else
    # Overwrite the existing mirror line
    sed -i "s|\"registry-mirrors\":.*|\"registry-mirrors\": [\"${_docker_url}\"]|" "${_DOCKER_DAEMON_FILE}"
  fi

  info "4. Cleanup trailing commas (common JSON error after sed injection)" 10
  # Removes comma if it's right before the closing brace
  sed -i 's/,[[:space:]]*}/}/g' "${_DOCKER_DAEMON_FILE}"

  info "5. Restart Rootless Docker" 10
  if systemctl --user is-active docker >/dev/null 2>&1; then
    systemctl --user restart docker || error "Failed to restart user Docker service" 10
  fi
  success "Applied configs to ${_DOCKER_DAEMON_FILE} using sed" 10
  #endregion docker

  #region PIP
  info "PIP configurating" 5
  # sudo cat > /etc/pip.conf > /dev/null <<EOF
  if command -v pip > /dev/null 2>&1; then
    if [ -e "${_PIPCONF}" ]; then
      cp "${_PIPCONF}" "${_PIPCONF}.bak"
    fi
    cat > "${_PIPCONF}" <<EOF
[global]
index-url = ${_pypi_index_url}
trusted-host = ${_host}
EOF
  fi
  #endregion PIP

  #region NPM
  info "NPM configurating" 5
  if command -v npm > /dev/null 2>&1; then
    sudo npm config set registry "${_npm_registry_url}"
    if [ -e "${_NPMRC}" ]; then
      cp "${_NPMRC}" "${_NPMRC}.bak"
    fi
    cat > "${_NPMRC}" <<EOF
registry=${_npm_registry_url}
EOF
  fi
  #endregion NPM

  #region MAVEN
  info "MAVEN configurating" 5
  if command -v mvn > /dev/null 2>&1; then
    if [ -e "${_M2SETTINGS}" ]; then
      cp "${_M2SETTINGS}" "${_M2SETTINGS}.bak"
    fi
    cat > "${_M2SETTINGS}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <mirrors>
    <mirror>
      <id>registry-mirror</id>
      <name>Local registry mirror</name>
      <url>${_maven_mirror_url}</url>
      <mirrorOf>*</mirrorOf>
    </mirror>
  </mirrors>
</settings>
EOF
  fi
  #endregion MAVEN

  success "Applied configs on host" 5
#endregion apply_host() {
}

# check APT use local APT-cache-ng registry
check() {
  info "[start] check changes in this host APT-configs..."
  { ( grep -q "${_apt_proxy_url}" /etc/apt/sources.list \
    ||  [ -f "/etc/apt/apt.conf.d/01aptcache" ] ) \
    && grep -q "${_apt_proxy_url}" ~/.bashrc \
    && apt-config dump | grep -i proxy > /dev/null
  } || error "APT cacher proxy host did not set."
  
  # Test connection to apt-cacher-ng
  [ "$(curl -s -o /dev/null -w "%{http_code}" "${_apt_proxy_url}/acng-report.html")" = "200" ] \
    || error "Cannot connect to apt-cacher-ng" 10
  success "[finish] check changes in this host APT-configs..."
}

help() {
  justSay "{write|apply|reset} [host] [out_dir]"
}


case "${_mode}" in
  write) write_files;;
  apply) apply_host;;
  reset) reset_host;;
  check) check;;
  help) help;;

  *)
    error "Usage: $0 $(help)";
    exit 2
    ;;
esac
