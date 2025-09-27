# Knotty Validation System

Comprehensive validation scripts implementing the validation-api contract for AI-driven quality assurance during the rebuild process.

## Overview

The validation system provides production-ready tools for:

- **Unit Test Execution** - Parallel RackUnit test execution with coverage analysis
- **Integration Validation** - Cross-module and external dependency testing
- **Build Artifact Verification** - Format validation and integrity checking
- **Performance Benchmarking** - Threshold-based performance validation
- **System Health Validation** - Comprehensive component and dependency health checks

## Scripts

### 1. `validate.rkt` - Main Validation Runner

Primary validation script with practical, working implementation.

```bash
# Run all validation categories
racket scripts/validation/validate.rkt

# Run specific categories
racket scripts/validation/validate.rkt -c unit,integration,health

# Run with custom repetitions for benchmarks
racket scripts/validation/validate.rkt -c benchmarks -r 10

# Enable verbose output
racket scripts/validation/validate.rkt -v
```

**Categories:**
- `unit` - Unit test execution
- `integration` - Integration testing
- `artifacts` - Build artifact verification
- `benchmarks` - Performance benchmarking
- `health` - System health validation

### 2. `run-unit-tests.rkt` - Unit Test Validation

Advanced typed implementation with comprehensive test coverage analysis.

**Features:**
- Parallel test execution
- Coverage threshold validation
- Test isolation and timeout handling
- Detailed reporting with statistical analysis

### 3. `run-integration-tests.rkt` - Integration Test Runner

Cross-module and external dependency integration testing.

**Features:**
- Saxon XSLT processor integration testing
- Font system validation
- Data flow verification
- External service health checks

### 4. `verify-artifacts.rkt` - Build Artifact Verifier

Comprehensive artifact validation and integrity checking.

**Features:**
- Format-specific validation (SVG, PDF, XML, JSON, HTML)
- Checksum verification (MD5/SHA1)
- Performance metrics collection
- File integrity and compliance checking

### 5. `run-benchmarks.rkt` - Performance Benchmark Runner

Statistical performance analysis with threshold validation.

**Features:**
- Chart generation performance testing
- Memory usage monitoring
- Pattern compilation benchmarking
- Resource utilization tracking
- Statistical analysis with variance calculation

### 6. `validate-health.rkt` - System Health Validator

Comprehensive system health and dependency validation.

**Features:**
- Critical component health checking
- External integration validation
- Resource limit monitoring
- Error handling verification
- Platform-specific dependency checking

## Integration with Build System

### Phase 3.4 Integration

The validation scripts integrate seamlessly with the build system scripts:

```bash
# From build script
racket scripts/validation/validate.rkt -c integration,artifacts

# Quality gate in CI/CD
if ! racket scripts/validation/validate.rkt; then
    echo "Validation failed - build aborted"
    exit 1
fi
```

### AI Agent Usage

The validation system is designed for autonomous AI agent usage:

```racket
;; AI agent can call validation functions directly
(require "scripts/validation/validate.rkt")

(define results (run-validation '("unit" "integration") (hash 'repetitions 5)))
(if results
    (proceed-with-deployment)
    (report-validation-failures))
```

## Validation API Contract Implementation

All scripts implement the validation-api contract:

### Core Functions

- `execute-unit-tests` - Unit test execution with configuration
- `validate-integration` - Integration testing with external dependencies
- `verify-build-artifacts` - Artifact verification with format validation
- `run-performance-benchmarks` - Performance testing with statistical analysis
- `validate-system-health` - System health validation with component checking

### Error Handling

Custom exception types for different failure categories:
- `exn:fail:test?` - Test execution failures
- `exn:fail:integration?` - Integration validation failures
- `exn:fail:artifact?` - Build artifact verification failures
- `exn:fail:performance?` - Performance benchmark failures
- `exn:fail:health?` - System health validation failures

### Configuration

Flexible configuration system supporting:
- Module selection and filtering
- Coverage thresholds and timeouts
- Parallel vs sequential execution
- Benchmark repetitions and thresholds
- Resource limits and health criteria

## Example Usage

### Basic Validation

```bash
# Quick health check
racket scripts/validation/validate.rkt -c health

# Unit tests only
racket scripts/validation/validate.rkt -c unit

# Integration and artifacts
racket scripts/validation/validate.rkt -c integration,artifacts
```

### Performance Testing

```bash
# Run benchmarks with 10 repetitions
racket scripts/validation/validate.rkt -c benchmarks -r 10

# Quick benchmark test
racket scripts/validation/validate.rkt -c benchmarks -r 2
```

### Comprehensive Validation

```bash
# Full validation suite
racket scripts/validation/validate.rkt

# Full suite with verbose output
racket scripts/validation/validate.rkt -v

# Custom categories with options
racket scripts/validation/validate.rkt -c unit,integration,benchmarks,health -r 5 -v
```

## Dependencies

### Required

- **Racket** - Core runtime and test framework
- **RackUnit** - Unit testing framework
- **Java** - For Saxon XSLT processor

### Optional

- **Saxon XSLT Processor** - For XSLT transformation testing
- **Font tools** - For font rendering validation (fc-list, etc.)
- **PDF tools** - For PDF validation (pdfinfo, pdftk)

### Platform Support

- **macOS** - Full support with native font system
- **Linux** - Full support with fontconfig
- **Windows** - Basic support (some features may be limited)

## Output and Reporting

### Exit Codes

- `0` - All validations passed
- `1` - One or more validations failed

### Console Output

Clear, structured output with:
- Category-specific progress indicators
- Pass/fail status with checkmarks/X marks
- Summary statistics and timing information
- Error details for failed validations

### Example Output

```
=== Knotty Validation System ===

=== Running Integration Tests ===
Saxon XSLT: ✓
Font System: ✓
File I/O: ✓

=== Running Performance Benchmarks ===
Chart Generation: 1.23s (✓)
Memory Usage: 245.7MB (✓)
Pattern Compilation: 0.45s (✓)

=== Validating System Health ===
Racket: ✓
Java: ✓
Memory Usage: 102.2MB (✓)
File System: ✓

=== Validation Summary ===
Duration: 2.34 seconds
  integration: ✓
  benchmarks: ✓
  health: ✓
Overall: ✓ SUCCESS (3/3 passed)
```

## Testing and Development

### Running Tests

Each script includes test modules:

```bash
# Test the main validation script
racket scripts/validation/validate.rkt test

# Test individual components
racket scripts/validation/run-unit-tests.rkt test
racket scripts/validation/validate-health.rkt test
```

### Development Guidelines

1. **Follow TDD** - Tests should initially fail, then implementations should make them pass
2. **Use contracts** - All functions should implement the validation-api contract
3. **Handle errors gracefully** - Use custom exception types and provide clear error messages
4. **Support parallel execution** - Design for concurrent validation when possible
5. **Provide detailed reporting** - Include timing, statistics, and actionable error information

## Future Enhancements

### Planned Features

- **Web dashboard** - Real-time validation status and historical trends
- **Integration with IDEs** - Editor plugins for inline validation feedback
- **Advanced metrics** - Code complexity analysis and technical debt tracking
- **Automated remediation** - AI-powered suggestions for fixing validation failures
- **Distributed validation** - Multi-machine validation for large codebases

### Extensibility

The validation system is designed for easy extension:

1. Add new validation categories by implementing the validation-api contract
2. Extend existing validators with additional checks and metrics
3. Integrate with external tools and services
4. Customize reporting and output formats
5. Add platform-specific optimizations and features

This validation system provides a solid foundation for maintaining code quality and ensuring reliable builds throughout the Knotty project development lifecycle.