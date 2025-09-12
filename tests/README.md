# Testing Guide

This directory contains comprehensive tests for the MeshSense Docker multi-platform support, ensuring the container works correctly on both ARM64 and x86-64 architectures.

## Quick Start

Run all tests:
```bash
./tests/run-tests.sh
```

Run only build tests:
```bash
./tests/run-tests.sh --build-only
```

Run only runtime tests:
```bash
./tests/run-tests.sh --runtime-only
```

Run quick tests (skip time-consuming operations):
```bash
./tests/run-tests.sh --quick
```

## Test Categories

### Build Tests (`build-test.sh`)
- **Dockerfile Syntax**: Validates Dockerfile syntax and structure
- **Docker Compose**: Validates docker-compose.yml configuration
- **Multi-platform Support**: Tests Docker buildx and cross-platform build capabilities
- **GitHub Actions**: Validates CI/CD workflow configuration
- **Image Metadata**: Inspects pre-built images for correct architecture

### Runtime Tests (`test-runner.sh`)
- **Docker Availability**: Verifies Docker is installed and running
- **Architecture Detection**: Identifies system architecture (ARM64/x86-64)
- **Image Pull**: Tests pulling the correct image for current platform
- **Container Startup**: Verifies container starts successfully
- **Web Service**: Tests web UI accessibility on port 5920
- **API Endpoints**: Basic smoke tests for web service functionality
- **Container Health**: Monitors logs and resource usage
- **Cross-platform Build**: Tests building for other architectures

## Platform Support

| Platform | Status | Testing Method |
|----------|--------|----------------|
| x86-64 (Intel/AMD) | ✅ Tested | Direct execution |
| ARM64 (Raspberry Pi) | ✅ Tested | Direct execution + emulation |

## Test Configuration

Key test parameters can be modified in the test scripts:

- **TEST_PORT**: Port for test container (default: 5921)
- **TEST_IMAGE**: Image to test (default: ghcr.io/roperscrossroads/meshsense-docker-arm64:main)
- **HEALTH_CHECK_TIMEOUT**: Time to wait for service startup (default: 60s)

## Troubleshooting

### Network Issues
If build tests fail due to network connectivity:
```bash
./tests/run-tests.sh --runtime-only
```

### Permission Issues
Ensure your user is in the docker group:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Cleanup
Remove test containers and resources:
```bash
./tests/run-tests.sh --cleanup
```

## Integration with CI/CD

These tests are designed to work in GitHub Actions and other CI environments. The multi-platform build tests will automatically adapt to available emulation capabilities.

For GitHub Actions integration, add to your workflow:
```yaml
- name: Run Platform Tests
  run: ./tests/run-tests.sh --quick
```