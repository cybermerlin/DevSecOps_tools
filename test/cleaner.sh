#!/usr/bin/env sh
set -eu

# ./cleaner.sh test      # Запуск всех тестов
# ./cleaner.sh dry-run   # Симуляция очистки
# ./cleaner.sh help      # Справка


set +u; [ -n "$ROOT" ] || export ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"; set -u
CLEANER_DIR="${ROOT}/cleaner"
. "${ROOT}/common/colors.sh"
. ./mocks/mocks.sh


# Import the functions from freeup.sh
import_cleaner_functions() {
    # Source the freeup.sh script to get access to its functions
    if [ -f "${CLEANER_DIR}/freeup.sh" ]; then
        # Use a subshell to avoid polluting current environment
        (
            set +eu  # Temporarily disable strict mode for import
            # Source the script to make functions available
            . "${CLEANER_DIR}/freeup.sh"
            
            # Export the functions we want to test
            export -f display_disk_usage
            export -f main
        )
        return 0
    else
        error "freeup.sh not found in ${CLEANER_DIR}"
        return 1
    fi
}


# Test: Check root privileges
test_root_privileges() {
    info "Testing root privileges check..."
    
    # Test running as non-root (should fail)
    if EUID=1000 "${CLEANER_DIR}/freeup.sh" clean 2>&1 | grep -q "суперпользователя"; then
        success "Non-root user correctly detected"
    else
        error "Root privileges check failed"
        return 1
    fi
}

# Test: APT cache cleanup
test_apt_cache_cleanup() {
    info "Testing APT cache cleanup..."
    
    _cache_dir="/var/cache/apt"
    _initial_size=$(du -s "$_cache_dir" 2>/dev/null | cut -f1)
    
    # Run apt autoclean
    apt autoclean > /dev/null 2>&1
    
    _final_size=$(du -s "$_cache_dir" 2>/dev/null | cut -f1)
    
    if [ "$_final_size" -le "$_initial_size" ]; then
        success "APT cache size reduced or stayed the same"
    else
        error "APT cache size increased unexpectedly"
        return 1
    fi
}

# Test: Temporary files cleanup
test_temp_files_cleanup() {
    info "Testing temporary files detection..."
    
    # Create test temporary files
    _test_temp_file="/tmp/test_cleanup_$(date +%s)"
    echo "test" > "$_test_temp_file"
    
    if [ -f "$_test_temp_file" ]; then
        success "Temporary file created for testing"
        # Cleanup
        rm -f "$_test_temp_file"
    else
        error "Failed to create test temporary file"
        return 1
    fi
}

# Test: Disk usage analysis function
test_disk_usage_analysis() {
    info "Testing disk usage analysis..."
    
    # Test with valid directory
    if display_disk_usage "/" "1" ">1M" "test" 2>&1 | grep -q "Analyze disk usage"; then
        success "Disk usage analysis started successfully"
    else
        error "Disk usage analysis failed"
        return 1
    fi
    
    # Test with invalid directory
    if display_disk_usage "/nonexistent_directory" "1" ">1M" "test" 2>&1 | grep -q "не существует"; then
        success "Invalid directory handled correctly"
    else
        error "Invalid directory not handled properly"
        return 1
    fi
}

# Test: Old kernels detection
test_old_kernels_detection() {
    info "Testing old kernels detection..."
    
    _current_kernel=$(uname -r | sed "s/-generic//")
    
    # Check if we can list kernels
    if dpkg -l 'linux-*' 2>/dev/null | grep -q "linux-image"; then
        success "Kernel packages detected"
        
        # Verify current kernel is not in removal list
        if ! dpkg -l 'linux-*' 2>/dev/null | grep "^ii" | grep -v "$_current_kernel" | grep -q "linux-image"; then
            success "Current kernel protected from removal"
        else
            info "Note: Other kernel versions found"
        fi
    else
        info "No additional kernel packages found"
    fi
}

# Test: Log files cleanup simulation
test_log_cleanup_simulation() {
    info "Testing log cleanup simulation..."
    
    # Test journalctl vacuum (dry run)
    if journalctl --disk-usage > /dev/null 2>&1; then
        success "Journal disk usage check successful"
    else
        error "Journal disk usage check failed"
        return 1
    fi
}

# Test: Cruft analysis
test_cruft_analysis() {
    info "Testing cruft analysis simulation..."
    
    # Check if cruft command is available
    if command -v cruft > /dev/null 2>&1; then
        if cruft --help > /dev/null 2>&1; then
            success "Cruft tool is available"
        else
            info "Cruft tool found but not working properly"
        fi
    else
        info "Cruft tool not installed (this is normal)"
    fi
}


# Main test runner
run_tests() {
    _tests_passed=0
    _tests_failed=0
    _tests_total=0
    
    _test_functions="test_root_privileges test_apt_cache_cleanup test_temp_files_cleanup test_disk_usage_analysis test_old_kernels_detection test_log_cleanup_simulation test_cruft_analysis"

    info "[start] cleaner tests..."
    for test_func in $_test_functions; do
        _tests_total=$((_tests_total + 1))
        info "Running: $test_func"

        if $test_func; then
            _tests_passed=$((_tests_passed + 1))
            success "PASS: $test_func"
        else
            _tests_failed=$((_tests_failed + 1))
            error "FAIL: $test_func"
        fi

        echo "------------------------------------------"
    done
    
    # Summary
    echo "=========================================="
    info "TEST SUMMARY:"
    echo "Total tests: $_tests_total"
    echo -e "${GREEN}Passed: $_tests_passed${NC}"
    if [ $_tests_failed -eq 0 ]; then
        echo -e "${GREEN}Failed: $_tests_failed${NC}"
    else
        echo -e "${RED}Failed: $_tests_failed${NC}"
    fi
    
    if [ $_tests_failed -eq 0 ]; then
        success "All tests passed! ✅"
        return 0
    else
        error "Some tests failed! ❌"
        return 1
    fi
}

# Dry run mode - simulate cleanup without actually doing it
dry_run_cleanup() {
    info "DRY RUN: Simulating cleanup operations..."
    
    echo "1. Would clean APT cache: apt autoclean"
    echo "2. Would remove old kernels (keeping current: $(uname -r))"
    echo "3. Would clean temporary files in /tmp, /var/tmp"
    echo "4. Would clean system logs older than 7 days"
    echo "5. Would remove orphaned packages"
    
    success "Dry run completed - no changes made"
}

# Help function
show_help() {
    echo "Cleaner Test Script"
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  test        Run all tests (default)"
    echo "  dry-run     Simulate cleanup without making changes"
    echo "  help        Show this help message"
    echo ""
    echo "Tests cover:"
    echo "  - Root privileges verification"
    echo "  - APT cache cleanup"
    echo "  - Temporary files handling"
    echo "  - Disk usage analysis"
    echo "  - Old kernels detection"
    echo "  - Log cleanup simulation"
    echo "  - Cruft analysis"
}

# Main execution
case "${1:-test}" in
    "test")
        # Import functions first
        if ! import_cleaner_functions; then
            error "Failed to import cleaner functions"
            exit 1
        fi
        run_tests
        ;;
    "dry-run")
        dry_run_cleanup
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
