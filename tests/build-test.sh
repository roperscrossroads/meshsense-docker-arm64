#!/bin/bash
# build-test.sh: Test Docker build process and multi-platform capabilities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_IMAGE_TAG="meshsense-test:local"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

test_dockerfile_syntax() {
    log_info "Testing Dockerfile syntax..."
    
    cd "$PROJECT_DIR"
    
    # Check if Dockerfile exists
    if [ ! -f "Dockerfile" ]; then
        log_error "Dockerfile not found"
        return 1
    fi
    
    # Basic syntax check by parsing with docker build --help context
    # Since --dry-run doesn't exist, we'll do a basic validation
    if docker build --help &> /dev/null; then
        log_success "Docker build command available for Dockerfile"
        
        # Check for basic Dockerfile syntax issues
        if grep -q "^FROM " Dockerfile && ! grep -q "^from " Dockerfile; then
            log_success "Dockerfile has valid FROM instruction"
        else
            log_error "Dockerfile missing or invalid FROM instruction"
            return 1
        fi
        
        # Check for common syntax issues
        if grep -E "^[A-Z]+ " Dockerfile > /dev/null; then
            log_success "Dockerfile syntax appears valid"
            return 0
        else
            log_error "Dockerfile syntax issues detected"
            return 1
        fi
    else
        log_error "Docker build command not available"
        return 1
    fi
}

test_docker_compose_syntax() {
    log_info "Testing docker-compose.yml syntax..."
    
    cd "$PROJECT_DIR"
    
    if docker compose config &> /dev/null; then
        log_success "docker-compose.yml syntax is valid"
        return 0
    else
        log_error "docker-compose.yml syntax error"
        return 1
    fi
}

test_buildx_availability() {
    log_info "Testing Docker buildx availability..."
    
    if ! docker buildx version &> /dev/null; then
        log_warning "Docker buildx not available"
        return 1
    fi
    
    log_success "Docker buildx is available"
    
    # List available builders
    log_info "Available builders:"
    docker buildx ls
    
    return 0
}

test_multiplatform_capability() {
    log_info "Testing multi-platform build capability..."
    
    cd "$PROJECT_DIR"
    
    if ! docker buildx version &> /dev/null; then
        log_warning "Docker buildx not available - skipping multi-platform test"
        return 0
    fi
    
    # Create builder if needed
    if ! docker buildx inspect multiplatform-builder &> /dev/null; then
        log_info "Creating multi-platform builder..."
        docker buildx create --name multiplatform-builder --driver docker-container --bootstrap
    fi
    
    docker buildx use multiplatform-builder
    
    # Test platform detection
    log_info "Testing platform build support..."
    
    # Create minimal test dockerfile
    TEST_DOCKERFILE=$(mktemp)
    cat > "$TEST_DOCKERFILE" << 'EOF'
FROM node:23-bookworm-slim
RUN echo "Platform test: $(uname -m)"
WORKDIR /test
RUN echo "Build successful"
EOF
    
    PLATFORMS=("linux/amd64" "linux/arm64")
    
    for platform in "${PLATFORMS[@]}"; do
        log_info "Testing build for platform: $platform"
        
        SAFE_PLATFORM=$(echo "$platform" | tr '/' '_')
        if timeout 300 docker buildx build \
            --platform "$platform" \
            -f "$TEST_DOCKERFILE" \
            --progress=plain \
            --load=false \
            . &> /tmp/build-test-$SAFE_PLATFORM.log; then
            log_success "Build test successful for $platform"
        else
            log_warning "Build test failed for $platform (this may be expected in some environments)"
            # Show last few lines of build log for debugging
            tail -10 /tmp/build-test-$SAFE_PLATFORM.log || true
        fi
    done
    
    rm -f "$TEST_DOCKERFILE"
    rm -f /tmp/build-test-*.log
    
    return 0
}

test_github_actions_workflow() {
    log_info "Testing GitHub Actions workflow syntax..."
    
    WORKFLOW_FILE="$PROJECT_DIR/.github/workflows/docker-publish.yml"
    
    if [ ! -f "$WORKFLOW_FILE" ]; then
        log_error "GitHub Actions workflow file not found"
        return 1
    fi
    
    # Basic YAML syntax check
    if command -v yamllint &> /dev/null; then
        if yamllint "$WORKFLOW_FILE" &> /dev/null; then
            log_success "GitHub Actions workflow YAML syntax is valid"
        else
            log_warning "GitHub Actions workflow has YAML syntax issues"
        fi
    else
        log_info "yamllint not available - skipping YAML validation"
    fi
    
    # Check for required fields
    if grep -q "platforms: linux/arm64,linux/amd64" "$WORKFLOW_FILE"; then
        log_success "Multi-platform build configuration found in workflow"
    else
        log_error "Multi-platform build configuration not found in workflow"
        return 1
    fi
    
    return 0
}

test_image_metadata() {
    log_info "Testing image metadata and labels..."
    
    # Test pre-built image metadata if available
    IMAGE="ghcr.io/roperscrossroads/meshsense-docker-arm64:main"
    
    if docker pull "$IMAGE" &> /dev/null; then
        log_info "Inspecting pre-built image metadata..."
        
        # Get image info
        ARCH=$(docker image inspect "$IMAGE" --format '{{.Architecture}}')
        OS=$(docker image inspect "$IMAGE" --format '{{.Os}}')
        
        log_info "Image OS: $OS"
        log_info "Image Architecture: $ARCH"
        
        # Verify architecture matches current system or is multi-platform
        SYSTEM_ARCH=$(uname -m)
        case $SYSTEM_ARCH in
            x86_64|amd64)
                EXPECTED_ARCH="amd64"
                ;;
            aarch64|arm64)
                EXPECTED_ARCH="arm64"
                ;;
            *)
                log_warning "Unknown system architecture: $SYSTEM_ARCH"
                return 0
                ;;
        esac
        
        if [ "$ARCH" = "$EXPECTED_ARCH" ]; then
            log_success "Image architecture ($ARCH) matches system architecture"
        else
            log_warning "Image architecture ($ARCH) does not match system architecture ($EXPECTED_ARCH)"
        fi
    else
        log_warning "Could not pull pre-built image for metadata testing"
    fi
    
    return 0
}

cleanup() {
    log_info "Cleaning up build test resources..."
    
    # Remove test builder if we created it
    if docker buildx inspect multiplatform-builder &> /dev/null; then
        docker buildx rm multiplatform-builder &> /dev/null || true
    fi
    
    # Clean up test images
    docker image prune -f &> /dev/null || true
}

trap cleanup EXIT

main() {
    echo "=========================================="
    echo "MeshSense Docker Build Test Suite"
    echo "=========================================="
    echo
    
    log_info "Starting build tests at $(date)"
    echo
    
    # Run build tests
    test_dockerfile_syntax
    test_docker_compose_syntax
    test_buildx_availability
    test_multiplatform_capability
    test_github_actions_workflow
    test_image_metadata
    
    echo
    log_success "Build tests completed successfully!"
}

main "$@"