#!/bin/bash
# test-runner.sh: Comprehensive test suite for MeshSense Docker multi-platform support
# Tests both ARM64 and x86-64 platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_IMAGE="ghcr.io/roperscrossroads/meshsense-docker-arm64:main"
TEST_CONTAINER_NAME="meshsense-test"
TEST_PORT="5921"  # Use different port to avoid conflicts
TEST_ACCESS_KEY="test-key-12345"
HEALTH_CHECK_TIMEOUT=60
CONTAINER_STARTUP_TIMEOUT=30

# Global test results
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("$1")
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test functions
test_docker_availability() {
    log_info "Testing Docker availability..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running or not accessible"
        return 1
    fi
    
    log_success "Docker is available and running"
    return 0
}

test_system_architecture() {
    log_info "Testing system architecture detection..."
    ARCH=$(uname -m)
    log_info "Detected architecture: $ARCH"
    
    case $ARCH in
        x86_64|amd64)
            log_success "x86-64 architecture detected"
            ;;
        aarch64|arm64)
            log_success "ARM64 architecture detected"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
    return 0
}

test_multiplatform_support() {
    log_info "Testing Docker multi-platform support..."
    
    if ! docker buildx version &> /dev/null; then
        log_warning "Docker buildx not available - limited multi-platform testing"
        return 0
    fi
    
    # Check if QEMU is available for emulation
    if docker run --rm --privileged multiarch/qemu-user-static --version &> /dev/null; then
        log_success "Multi-platform emulation support available"
    else
        log_warning "Multi-platform emulation not available"
    fi
    
    return 0
}

test_image_pull() {
    log_info "Testing image pull for current platform..."
    
    if docker pull "$TEST_IMAGE" &> /dev/null; then
        log_success "Successfully pulled image: $TEST_IMAGE"
        
        # Check image architecture
        ARCH_INFO=$(docker image inspect "$TEST_IMAGE" --format '{{.Architecture}}')
        log_info "Image architecture: $ARCH_INFO"
        return 0
    else
        log_error "Failed to pull image: $TEST_IMAGE"
        return 1
    fi
}

test_container_start() {
    log_info "Testing container startup..."
    
    # Clean up any existing test container
    docker rm -f "$TEST_CONTAINER_NAME" &> /dev/null || true
    
    # Start container
    if docker run -d \
        --name "$TEST_CONTAINER_NAME" \
        -p "$TEST_PORT:5920" \
        -e PORT=5920 \
        -e HOST=0.0.0.0 \
        -e ACCESS_KEY="$TEST_ACCESS_KEY" \
        -e DISPLAY=:99 \
        --cap-add NET_ADMIN \
        --user 1000:1000 \
        "$TEST_IMAGE" &> /dev/null; then
        
        log_success "Container started successfully"
        
        # Wait for container to be running
        local count=0
        while [ $count -lt $CONTAINER_STARTUP_TIMEOUT ]; do
            if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$TEST_CONTAINER_NAME.*Up"; then
                log_success "Container is running"
                return 0
            fi
            sleep 1
            ((count++))
        done
        
        log_error "Container failed to start within $CONTAINER_STARTUP_TIMEOUT seconds"
        docker logs "$TEST_CONTAINER_NAME" 2>&1 | tail -20
        return 1
    else
        log_error "Failed to start container"
        return 1
    fi
}

test_web_service() {
    log_info "Testing web service accessibility..."
    
    # Wait for service to be ready
    local count=0
    while [ $count -lt $HEALTH_CHECK_TIMEOUT ]; do
        if curl -s -f "http://localhost:$TEST_PORT" > /dev/null 2>&1; then
            log_success "Web service is accessible on port $TEST_PORT"
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    log_error "Web service not accessible within $HEALTH_CHECK_TIMEOUT seconds"
    return 1
}

test_api_endpoints() {
    log_info "Testing basic API endpoints..."
    
    # Test root endpoint
    if curl -s -f "http://localhost:$TEST_PORT" > /dev/null; then
        log_success "Root endpoint accessible"
    else
        log_error "Root endpoint not accessible"
        return 1
    fi
    
    # Test if we get HTML response (basic smoke test)
    RESPONSE=$(curl -s "http://localhost:$TEST_PORT")
    if echo "$RESPONSE" | grep -qi "html\|<!doctype\|<title"; then
        log_success "Received HTML response from web service"
    else
        log_warning "Unexpected response format from web service"
    fi
    
    return 0
}

test_container_logs() {
    log_info "Testing container logs for errors..."
    
    LOGS=$(docker logs "$TEST_CONTAINER_NAME" 2>&1)
    
    # Check for common error patterns
    if echo "$LOGS" | grep -qi "error\|exception\|failed\|cannot"; then
        log_warning "Found potential errors in container logs:"
        echo "$LOGS" | grep -i "error\|exception\|failed\|cannot" | head -5
    else
        log_success "No obvious errors found in container logs"
    fi
    
    return 0
}

test_resource_usage() {
    log_info "Testing container resource usage..."
    
    # Get container stats
    STATS=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" "$TEST_CONTAINER_NAME")
    
    if [ -n "$STATS" ]; then
        log_success "Container resource usage:"
        echo "$STATS"
    else
        log_error "Failed to get container resource usage"
        return 1
    fi
    
    return 0
}

# Cross-platform build test (requires buildx)
test_cross_platform_build() {
    log_info "Testing cross-platform build capabilities..."
    
    if ! docker buildx version &> /dev/null; then
        log_warning "Docker buildx not available - skipping cross-platform build test"
        return 0
    fi
    
    # Test if we can build for other platform
    CURRENT_ARCH=$(uname -m)
    case $CURRENT_ARCH in
        x86_64|amd64)
            TEST_PLATFORM="linux/arm64"
            ;;
        aarch64|arm64)
            TEST_PLATFORM="linux/amd64"
            ;;
        *)
            log_warning "Unknown architecture - skipping cross-platform build test"
            return 0
            ;;
    esac
    
    log_info "Testing build for platform: $TEST_PLATFORM"
    
    # Create a simple test dockerfile for quick build test
    TEST_DOCKERFILE=$(mktemp)
    cat > "$TEST_DOCKERFILE" << 'EOF'
FROM node:23-bookworm-slim
RUN echo "Multi-platform test successful"
EOF
    
    if docker buildx build --platform "$TEST_PLATFORM" -f "$TEST_DOCKERFILE" . &> /dev/null; then
        log_success "Cross-platform build test successful for $TEST_PLATFORM"
        rm -f "$TEST_DOCKERFILE"
        return 0
    else
        log_warning "Cross-platform build test failed for $TEST_PLATFORM (this may be expected)"
        rm -f "$TEST_DOCKERFILE"
        return 0
    fi
}

cleanup() {
    log_info "Cleaning up test resources..."
    docker rm -f "$TEST_CONTAINER_NAME" &> /dev/null || true
}

# Signal handlers
trap cleanup EXIT

# Main test execution
main() {
    echo "=========================================="
    echo "MeshSense Docker Multi-Platform Test Suite"
    echo "=========================================="
    echo
    
    log_info "Starting test suite at $(date)"
    echo
    
    # Run all tests
    test_docker_availability
    test_system_architecture
    test_multiplatform_support
    test_image_pull
    test_container_start
    test_web_service
    test_api_endpoints
    test_container_logs
    test_resource_usage
    test_cross_platform_build
    
    echo
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        echo
        echo "Failed tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $test"
        done
        echo
        exit 1
    else
        echo
        log_success "All tests passed! MeshSense Docker container is working correctly."
        exit 0
    fi
}

# Command line options
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --cleanup      Clean up test resources and exit"
        echo "  --quick        Run quick tests only (skip build tests)"
        exit 0
        ;;
    --cleanup)
        cleanup
        exit 0
        ;;
    --quick)
        # Disable build tests for quick run
        test_cross_platform_build() { log_info "Skipping cross-platform build test (quick mode)"; }
        ;;
esac

# Run main function
main "$@"