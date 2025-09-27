# Integration Validation Tests

This directory contains integration tests that validate system scenarios from the quickstart documentation. These tests are designed to **FAIL initially** since the full integration implementations don't exist yet.

## Test Files

### `test_environment_setup.rkt`
Tests complete environment setup procedures including:
- Platform compatibility verification
- Git and Java availability checks
- Racket environment validation
- Docker environment testing (optional)
- Project structure validation
- Dependency resolution testing

### `test_cross_platform.rkt`
Tests cross-platform compatibility requirements including:
- Platform-specific path handling
- Executable detection across platforms
- Cross-platform build process consistency
- Platform-specific dependency handling
- Performance consistency testing
- Character encoding and internationalization

### `test_saxon_integration.rkt`
Tests Saxon XSLT processor integration including:
- Saxon JAR availability and functionality
- XSLT transformation capabilities
- XSLT 2.0 feature support
- Racket-Saxon programmatic integration
- Error handling and robustness
- Performance and scalability testing

### `run-integration-tests.rkt`
Main test runner that executes all validation tests with detailed reporting.

## Test Results

Current test results (as expected):
- **19 successful tests**: Basic functionality works (platform detection, file operations, etc.)
- **20 failing tests**: Integration features don't exist yet (expected behavior)

The failing tests validate scenarios from `quickstart.md` that haven't been implemented yet:
- Package installation and compilation
- Saxon XSLT transformation
- HTML export functionality
- Cross-platform build artifacts
- Complete dependency resolution

## Usage

Run all integration tests:
```bash
cd tests/validation
racket run-integration-tests.rkt
```

Run individual test suites:
```bash
racket test_environment_setup.rkt
racket test_cross_platform.rkt
racket test_saxon_integration.rkt
```

## Test Framework

All tests use the RackUnit framework with:
- Proper test organization in test suites
- Platform detection utilities
- System command execution helpers
- Temporary file management
- Comprehensive error checking

These tests serve as integration validation for autonomous project reconstruction and provide a comprehensive validation framework for the complete Knotty system implementation.