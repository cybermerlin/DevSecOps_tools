#!/usr/bin/env sh
set -eu
set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"; set -u
. "${ROOT}/common/colors.sh"
. "${ROOT}/wsl-prep/run.sh"


#region code_bashrc()
info "=== Starting test [code_bashrc()] ==="

# Test 2: Create test environment
test_dir="$(mktemp -d)"
_test_rc="${test_dir}/.bashrc"
test_backup="${test_dir}/.bashrc.bak"
trap 'rm -rf "$test_dir"' EXIT

# Test 3: Test with empty .bashrc
info 'Testing with empty .bashrc...'
echo "" > "${_test_rc}"
HOME="$test_dir" code_bashrc
if ! grep -q "Dev tools section" "${_test_rc}"; then
    error 'Test failed: Empty .bashrc test failed'
    exit 1
fi
success "Empty .bashrc test passed"

# Test 4: Test with existing content
info "Testing with existing content..."
echo "existing content" > "${_test_rc}"
HOME="$test_dir" code_bashrc
if ! grep -q "existing content" "$_test_rc" || ! grep -q "Dev tools section" "$_test_rc"; then
    error "Test failed: Existing content test failed"
    exit 1
fi
success "Existing content test passed"

# Test 5: Test backup creation
if [ ! -f "$test_backup" ]; then
    error "Test failed: Backup not created"
    exit 1
fi
success "Backup test passed"

# Test 6: Test idempotency
first_run="$(cat "$_test_rc")"
HOME="$test_dir" code_bashrc
second_run="$(cat "$_test_rc")"
if [ "$first_run" != "$second_run" ]; then
    error "Test failed: Not idempotent"
    exit 1
fi
success "Idempotency test passed"
success "=== All tests passed ==="
#endregion
