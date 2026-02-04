#!/usr/bin/env sh
set -eu

set +u; [ -n "${ROOT:-}" ] || export ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"; set -u
. "${ROOT}/common/colors.sh"


_cmd="${1:-up}"
_host="${2:-localhost}"
_lvl=10


# region secrets to .env
_ENV="${ROOT}/registry/.env"

cleanup() {
  rm -f "${_ENV}"
}
if [ "${_cmd}" != 'env' ]; then
  trap cleanup EXIT INT TERM
fi

_env() {
  if [ -f "${ROOT}/secrets/secrets.sh" ]; then
    . "${ROOT}/secrets/secrets.sh" > /dev/null
    env > "${_ENV}"

    if ! grep "^WSL_VLM=" ${_ENV} > /dev/null; then
      error 'Need $WSL_VLM variable to place volumes for the Registry'
      exit 1
    fi
  elif [ -f "${_ENV}" ]; then
    error "Have no .env. Fix it before start."
    exit 1
  fi
  # endregion secrets

  cat >> "${_ENV}" <<EOF
REGISTRY_HOST=${_host}
APT_PROXY_URL=http://${_host}:3142
DOCKER_PROXY_URL="http://${_host}:5000"
NPM_PROXY_URL="http://${_host}:4873/"
PYPI_PROXY_URL="http://${_host}:3141/root/pypi/+simple/"
MVN_PROXY_URL="http://${_host}:8081/repository/maven-public/"
EOF

  . "${ROOT}/common/apply_env.sh"
}


if ! command -v docker > /dev/null; then
  "${ROOT}/run.sh" inst-docker || exit 1;
fi

up() {
  _env
  #  create dirs for volumes
  docker compose config --volumes | xargs -I {} mkdir -p "${WSL_VLM}/{}"
  # "${ROOT}/sync.sh" syncVols
  docker compose -f "${ROOT}/registry/docker-compose.yml" up -d
  docker ps --format "table {{.Names}}\t{{.ID}}\t{{.Status}}\t{{.Ports}}"
}

down() {
  docker compose -f "${ROOT}/registry/docker-compose.yml" down --remove-orphans
  # "${ROOT}/sync.sh" syncVolsToHost
}

rm_volumes() {
  # docker volume rm $(docker volume ls -q) 2>/dev/null
  docker compose down --volumes --remove-orphans
  # docker-compose down --volumes --rmi all                 # and remove images too
  # docker volume rm $(docker compose config --volumes | xargs -I {} echo "$(basename $(pwd))_{}")
}


#  test manual using docker devpi to get local pip registry with wheel dist
probepy() {
  DEVPI_PASSWORD=123

  docker run -d --name devpi \
      --publish 3141:3141 \
      --volume ~/volumes/wheelhouse:/wheelhouse \
      --volume ~/volumes/devpi_data:/data \
      --env=DEVPI_PASSWORD=${DEVPI_PASSWORD} \
      --restart unless-stopped \
      muccg/devpi
}


# docker volume inspect [name-of-volume-of-docker]
#  ... look at the line "Mountpooint": "/home/user/.local/share/docker/volumes/registry_docker_registry/_data"
#  rsync 

case "${_cmd}" in
  restart) down; up;;
  up) up;;
  down) down;;
  
  env) _env;; # this command need just to create .env and set_env_var
  cln_env) cleanup;;
  rm-vlms) rm_volumes;;
  logs) docker compose -f "${ROOT}/registry/docker-compose.yml" logs -f --tail=200;;
  ps) docker compose -f "${ROOT}/registry/docker-compose.yml" ps;;
  test) "${ROOT}/registry/test.sh" "${_host}" "0" "--inner";;
  probepy) probepy;;
  
  # configurating you host to use local proxy \ cacher
  conf)
    _act="${2:-}"
    _host="${3:-localhost}"
    _dirout="${4:-${ROOT}/registry/out}"

    case "${_act}" in
        check|write|reset|apply) ;;
        *)
          error "Usage: "
          justSay "  $0 conf {check|write|apply|reset} [host] [out_dir]" $_lvl
          exit 2
        ;;
    esac

    _env;
    "${ROOT}/registry/configure.sh" "${_act}" "${_host}" "${_dirout}"
    ;;

  *)
    error "Usage:";
    justSay "  $0 restart" $_lvl
    justSay "  $0 up" $_lvl
    justSay "  $0 down" $_lvl
    echo ''
    justSay "  $0 rm-vlms" $_lvl
    justSay "  $0 logs" $_lvl
    justSay "  $0 ps" $_lvl
    justSay "  $0 test [host]" $_lvl
    justSay "  $0 probepy" $_lvl
    echo ''
    justSay "  $0 conf $(${ROOT}/registry/configure.sh help)" $_lvl
    exit 2
    ;;
esac
