#!/usr/bin/env sh
set -eu
set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"; set -u;
. "${ROOT}/common/colors.sh"
. "${ROOT}/common/installer.sh"
. "${ROOT}/secrets/secrets.sh"

if [ "$(id -u)" -eq 0 ]; then
    error "Nothing to do for [$(id -u)]. Run it under non-root user."
    exit 1
fi
info "User: $(id -un). ID: $(id -u)"

if ! command -v rsync > /dev/null 2>&1; then
  installer rsync
fi
if ! command -v time > /dev/null 2>&1; then
  installer time
fi


_SRC="${HST_SRC_TooLS}"
_DST="${WSL_SRC_ADM}"
_TGT="${WSL_SRC_TooLS}"
_UID=$(id -u)


# syncChecker  – returns 1 when source differs from dest, else 0
# usage:  syncChecker && ./run.sh || true
syncChecker(){
  # --dry-run + --itemize-changes prints only what *would* be copied
  sudo rsync -avni --progress --delete --delete-after --exclude='.git' "$_SRC" "$_DST/" | grep -E '^[><c].*' && return 1 || return 0
}

# sync from Host w deletion
sync() {
    cd ~
    mkdir -p ~/dev/admin \
        && time sudo rsync -zav --progress --delete-after --delete-excluded "$_SRC" "$_DST/" \
        && cd $_TGT \
        && sudo chown -R user:user . \
        && set +e; ./common/chmod-x.sh >/dev/null 2>/dev/null; set -e
}

# sync wo deletion. only new and changed files.
syncSoft() {
    cd ~
    mkdir -p ~/dev/admin \
        && time sudo rsync -zav --progress "$_SRC" "$_DST/" \
        && cd $_TGT \
        && set +e; ./common/chmod-x.sh >/dev/null 2>/dev/null; set -e
}

# sync from WSL to host
syncToHost() {
    info "Sync $WSL_SRC_TooLS/ to $HST_SRC_TooLS..."
    sudo rsync -avni --delete --delete-after  "$WSL_SRC_TooLS/" "$HST_SRC_TooLS" | grep -E '^[><c].*' >/dev/null && {
       time sudo rsync -za --progress --delete-after --delete-excluded "$WSL_SRC_TooLS/" "$HST_SRC_TooLS" || {
          error "Sync failed: $?" >&2
          return 1
      }
    }
    success "Synced $_TGT to $_SRC successfully"
}

# sync docker-volumes () from WSL to host
syncVolsToHost() {
    info "Sync-backup docker-volumes $WSL_VLM/ to $HST_VLM..."
    sudo rsync -avni --progress --delete --delete-after  "$WSL_VLM/" "$HST_VLM" | grep -E '^[><c].*' > /dev/null && {
       time sudo rsync -za --delete-after --delete-excluded "$WSL_VLM/" "$HST_VLM" || {
          error "Sync failed: $?" >&2
          return 1
      }
    }
    success "Synced $WSL_VLM/ to $HST_VLM successfully"
}

# sync docker-volumes () from host to WSL
syncVols() {
    info "Sync-backup docker-volumes $HST_VLM/ to $WSL_VLM..."
    mkdir -p "${WSL_VLM}"
    sudo rsync -avni --progress --delete --delete-after  "$HST_VLM/" "$WSL_VLM" | grep -E '^[><c].*' > /dev/null && {
       time sudo rsync -za --delete-after --delete-excluded "$HST_VLM/" "$WSL_VLM" || {
          error "Sync failed: $?" >&2
          return 1
      }
    }
    sudo chown -R ${_UID}:${_UID} ~/.local
    success "Synced $HST_VLM/ to $WSL_VLM successfully"
}

# watching for cur dir and sync to Windows src.dir on change
# $1 - target dir
# $2 - interval (s)
# $3 - func [sync by default]
watching() {
  _EVENTS="modify,create,delete,move"
  _WTGT="${1:-${_SRC}}"
  _fstype=$(df -T /mnt/f | tail -1 | awk '{print $2}')
  _CMD="${3:-sync}"

  if [ "${_fstype}" = "ext4" ]; then
    if ! command -v inotifywait > /dev/null 2>&1; then
      installer inotify-tools
    fi
    inotifywait -mre "${_EVENTS}" --format '%w%f' "${_WTGT}" | while read -r _line; do eval "${_CMD}"; done

  else
    warning "Need another way to monitor changes"

    _INTERVAL="${2:-8}"  # Интервал в секундах
    last_check=$(date +%s)

    while true; do
        sleep ${_INTERVAL}
        
        changed_files=$(find "${_WTGT}" -type f -newermt "@${last_check}" 2>/dev/null)
        
        if [ -n "$changed_files" ]; then
            info "[$(date +%H:%M:%S)] Обнаружены изменения:"
            echo "$changed_files" | while read -r file; do
                info "  📄 $file"
            done
            eval "${_CMD}"
            last_check=$(date +%s)
        fi
    done
  fi
}


if [ "${0##*/}" = "sync.sh" ]; then
  if [ $# -gt 0 ]; then
    "$@"
    exit 0
  fi

  syncChecker && { success "OK"; exit 0; }
  warning "Need to sync"
  exit 1
fi
