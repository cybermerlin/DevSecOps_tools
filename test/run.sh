#!/usr/bin/env sh
set -eu

set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"; set -u
. "${ROOT}/common/colors.sh"
. "${ROOT}/common/handler.sh"


# 1. Install shellcheck if missing
# info "Let's import installer" 15
. "${ROOT}/common/installer.sh"
# info "Let's start installations" 15
# installer shellcheck || exit 1
handler 'installer shellcheck' 'Check [shellcheck] installation...'

#region 2. Lint everything
# info 'linting scripts...'
. "${ROOT}/test/shellchecker.sh"

# handler 'shellchecker ../cleaner' "Linting 'cleaner'..." 10
handler 'shellchecker common' "Linting 'common'..." 
# find ../cleaner -name "*.sh" -exec shellcheck {} \;
# find ../common -name "*.sh" -exec shellcheck {} \;
# find ../dev-prep -name "*.sh" -exec shellcheck {} \;
# find ../wsl-prep -name "*.sh" -exec shellcheck {} \;
#endregion


# 3. Make mocks available first in PATH
export PATH="$ROOT/test/mocks:$PATH"


# 4. Execute each test file
cd "$ROOT/test"
for t in *.sh; do
    [ ! "$t" = "common.sh" ] && continue
    # [ "$t" != "shellchecker.sh" ] && [ "$t" != "run.sh" ] && handler "${ROOT}/test/$t" "Executing test from [test/$t]"
    [ "$t" != "shellchecker.sh" ] && [ "$t" != "run.sh" ] && "${ROOT}/test/$t"
done

success "All tests has been ran ✔"
