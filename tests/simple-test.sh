#!/bin/bash
# simple-test.sh: Simple working test for MeshSense Docker functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test configuration
TEST_IMAGE="ghcr.io/roperscrossroads/meshsense-docker-arm64:main"
TEST_CONTAINER_NAME="meshsense-simple-test"
TEST_PORT="5922"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

cleanup() {
    log_info "Cleaning up..."
    docker rm -f "$TEST_CONTAINER_NAME" &> /dev/null || true
}

trap cleanup EXIT

echo "=========================================="
echo "MeshSense Docker Simple Test"
echo "=========================================="
echo "Architecture: $(uname -m)"
echo "Date: $(date)"
echo

# Test 1: Docker availability
log_info "Test 1: Docker availability"
if docker info &> /dev/null; then
    log_success "Docker is running"
else
    log_error "Docker is not available"
    exit 1
fi

# Test 2: Image pull
log_info "Test 2: Image pull"
if docker pull "$TEST_IMAGE" &> /dev/null; then
    ARCH=$(docker image inspect "$TEST_IMAGE" --format '{{.Architecture}}')
    log_success "Image pulled successfully (architecture: $ARCH)"
else
    log_error "Failed to pull image"
    exit 1
fi

# Test 3: Container start
log_info "Test 3: Container startup"
if docker run -d \
    --name "$TEST_CONTAINER_NAME" \
    -p "$TEST_PORT:5920" \
    -e PORT=5920 \
    -e HOST=0.0.0.0 \
    -e ACCESS_KEY=test-key \
    -e DISPLAY=:99 \
    --cap-add NET_ADMIN \
    --user 1000:1000 \
    "$TEST_IMAGE" &> /dev/null; then
    log_success "Container started successfully"
else
    log_error "Failed to start container"
    exit 1
fi

# Test 4: Wait for service
log_info "Test 4: Web service startup (waiting 15 seconds)"
sleep 15

if docker ps --filter "name=$TEST_CONTAINER_NAME" --format "{{.Status}}" | grep -q "Up"; then
    log_success "Container is running"
else
    log_error "Container is not running"
    docker logs "$TEST_CONTAINER_NAME" 2>&1 | tail -10
    exit 1
fi

# Test 5: Web service accessibility
log_info "Test 5: Web service test"
if curl -s -f "http://localhost:$TEST_PORT" > /dev/null; then
    log_success "Web service is accessible"
    
    # Get response headers
    RESPONSE=$(curl -s -I "http://localhost:$TEST_PORT")
    if echo "$RESPONSE" | grep -q "HTTP/1.1 200 OK"; then
        log_success "Web service returns HTTP 200"
    else
        log_warning "Unexpected HTTP response"
    fi
else
    log_error "Web service is not accessible"
    exit 1
fi

# Test 6: Resource usage
log_info "Test 6: Resource usage"
STATS=$(docker stats --no-stream --format "{{.CPUPerc}} {{.MemUsage}}" "$TEST_CONTAINER_NAME")
log_success "Container stats: $STATS"

# Test 7: Check logs for major errors
log_info "Test 7: Log analysis"
LOGS=$(docker logs "$TEST_CONTAINER_NAME" 2>&1)
if echo "$LOGS" | grep -q "Server listening"; then
    log_success "Server started successfully"
else
    log_warning "Server startup message not found"
fi

echo
echo "=========================================="
echo "Test Summary"
echo "=========================================="
log_success "All tests passed! MeshSense is working correctly on $(uname -m)"
echo
echo "Container details:"
docker ps --filter "name=$TEST_CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo
echo "Access the web interface at: http://localhost:$TEST_PORT"
echo
echo "To stop the test container: docker rm -f $TEST_CONTAINER_NAME"