#!/usr/bin/env sh
set -eu
set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"; set -u;
. "${ROOT}/common/colors.sh"


# rewrite all E-mail of author whole git history (for all commits)
# rewriteAuthorEmail 'old@email' 'new_username' 'new_email'
rewriteAuthorEmail() {
  # Validate exactly 3 arguments
  case $# in
    3) ;;
    *) error "Usage: $0 old@email newname new@email" >&2; exit 1 ;;
  esac

  _OLD_EMAIL="${1}"
  _CORRECT_NAME="${2}"
  _CORRECT_EMAIL="${3}"

  info "Rewriting: ${_OLD_EMAIL} → ${_CORRECT_NAME} <${_CORRECT_EMAIL}>"

  # git filter-branch env-filter (POSIX sh inside)
  git filter-branch -f --env-filter "
    if [ \"\$GIT_COMMITTER_EMAIL\" = '${_OLD_EMAIL}' ]; then
        GIT_COMMITTER_NAME='${_CORRECT_NAME}'
        GIT_COMMITTER_EMAIL='${_CORRECT_EMAIL}'
        export GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
    fi
    if [ \"\$GIT_AUTHOR_EMAIL\" = '${_OLD_EMAIL}' ]; then
        GIT_AUTHOR_NAME='${_CORRECT_NAME}'
        GIT_AUTHOR_EMAIL='${_CORRECT_EMAIL}'
        export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL
    fi
  " --tag-name-filter cat -- --branches --tags

  rm -rf .git/refs/original/
  git reflog expire --expire=now --all
  git gc --prune=now --aggressive

  ask 'Local rewrite complete.\nForce push? [y/N]: '
  read -r response
  case "${response}" in
    [yY]|[yY][eE][sS]) 
      git push origin --force --all
      git push origin --force --tags
      success 'Force pushed'
      ;;
    *) error 'Run: git push origin --force --all --tags' ;;
  esac
}
