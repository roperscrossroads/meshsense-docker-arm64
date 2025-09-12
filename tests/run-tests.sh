#!/bin/bash
# run-tests.sh: Main test runner for MeshSense Docker multi-platform support

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
MeshSense Docker Multi-Platform Test Suite

Usage: $0 [options]

Options:
    --build-only    Run only build and configuration tests
    --runtime-only  Run only runtime and functionality tests
    --quick         Run quick tests (skip time-consuming build tests)
    --cleanup       Clean up test resources and exit
    --help, -h      Show this help message

Test Categories:
    Build Tests:    Dockerfile syntax, multi-platform build capability
    Runtime Tests:  Container startup, web service, API endpoints
    
Examples:
    $0              # Run all tests
    $0 --build-only # Test build system only
    $0 --quick      # Run quick validation tests
EOF
}

run_build_tests() {
    log_info "Running build tests..."
    if [ -f "$SCRIPT_DIR/build-test.sh" ]; then
        bash "$SCRIPT_DIR/build-test.sh"
    else
        log_error "Build test script not found"
        return 1
    fi
}

run_runtime_tests() {
    log_info "Running runtime tests..."
    if [ -f "$SCRIPT_DIR/simple-test.sh" ]; then
        bash "$SCRIPT_DIR/simple-test.sh"
    else
        log_error "Runtime test script not found"
        return 1
    fi
}

cleanup_all() {
    log_info "Cleaning up all test resources..."
    if [ -f "$SCRIPT_DIR/test-runner.sh" ]; then
        bash "$SCRIPT_DIR/test-runner.sh" --cleanup
    fi
    log_success "Cleanup completed"
}

main() {
    cd "$PROJECT_DIR"
    
    echo "========================================================"
    echo "MeshSense Docker Multi-Platform Test Suite"
    echo "========================================================"
    echo "Project: $PROJECT_DIR"
    echo "Architecture: $(uname -m)"
    echo "Date: $(date)"
    echo "========================================================"
    echo
    
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --cleanup)
            cleanup_all
            exit 0
            ;;
        --build-only)
            run_build_tests
            ;;
        --runtime-only)
            run_runtime_tests
            ;;
        --quick)
            QUICK_MODE=true
            run_build_tests
            run_runtime_tests
            ;;
        "")
            run_build_tests
            echo
            run_runtime_tests
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    
    echo
    log_success "All requested tests completed successfully!"
}

main "$@"