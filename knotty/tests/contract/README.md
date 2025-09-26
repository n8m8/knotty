# Knotty Contract Test Framework

A comprehensive framework for validating API contracts against specifications in Typed Racket. This framework provides utilities for testing function contracts, parameter validation, return value verification, error handling compliance, and performance characteristics.

## Overview

The contract testing framework consists of several components:

- **`framework.rkt`**: Core framework with contract testing utilities
- **`pattern-api.rkt`**: Contract tests for the Pattern API
- **`chart-api.rkt`**: Contract tests for the Chart API
- **`cli-api.rkt`**: Contract tests for the CLI API
- **`integration.rkt`**: Integration tests and framework validation

## Quick Start

### Running Contract Tests

```racket
#lang typed/racket
(require "framework.rkt"
         "pattern-api.rkt")

;; Run pattern API contract tests
(define suite (run-pattern-api-contract-tests))
(display-test-suite-results suite)
```

### Creating Custom Contract Tests

```racket
;; Define a function contract
(define my-contract
  (FunctionContract 'my-function
                    '(String Natural)     ;; Parameter types
                    'String               ;; Return type
                    (list (λ (args) (> (cadr args) 0)))  ;; Preconditions
                    (list (λ (args result) (> (string-length result) 0)))  ;; Postconditions
                    '()))                 ;; Error conditions

;; Test the contract
(define result
  (test-function-contract 'my-function my-function my-contract "input" 5))

(check-true (ContractTestResult-passed? result))
```

## Framework Components

### Core Data Structures

#### `ContractTestResult`
Represents the result of a single contract test:

```racket
(struct ContractTestResult
  ([function-name : Symbol]
   [test-name : String]
   [passed? : Boolean]
   [expected : Any]
   [actual : Any]
   [error-message : (Option String)]))
```

#### `FunctionContract`
Defines a contract specification for a function:

```racket
(struct FunctionContract
  ([name : Symbol]
   [parameter-types : (Listof Any)]
   [return-type : Any]
   [preconditions : (Listof (Any -> Boolean))]
   [postconditions : (Listof (Any Any -> Boolean))]
   [error-conditions : (Listof (Any -> Boolean))]))
```

#### `ContractTestSuite`
Aggregates multiple test results:

```racket
(struct ContractTestSuite
  ([name : String]
   [tests : (Listof ContractTestResult)]
   [passed : Natural]
   [failed : Natural]))
```

### Core Testing Functions

#### `test-function-contract`
Tests a function against a contract specification:

```racket
(: test-function-contract (Symbol (-> Any) FunctionContract Any * -> ContractTestResult))
```

**Example:**
```racket
(test-function-contract 'add (λ () (+ 2 3)) addition-contract 2 3)
```

#### `test-error-contract`
Tests that a function throws expected exceptions:

```racket
(: test-error-contract (Symbol (-> Any) (Any -> Boolean) Any * -> ContractTestResult))
```

**Example:**
```racket
(test-error-contract 'divide-by-zero (λ () (/ 1 0)) exn:fail:contract:divide-by-zero?)
```

### Enhanced Testing Helpers

#### Performance Testing
```racket
;; Test execution time bounds
(test-performance-bound 'my-function my-func 1000 args...)  ;; 1000ms max

;; Test memory usage bounds
(test-memory-bounds 'my-function my-func 50)  ;; 50MB max
```

#### Property Testing
```racket
;; Test idempotency
(test-idempotency 'my-function my-func input)

;; Test determinism
(test-determinism 'my-function my-func input 10)  ;; 10 calls

;; Test referential transparency
(test-referential-transparency 'my-function my-func input)
```

#### Robustness Testing
```racket
;; Test null input handling
(test-null-input-handling 'my-function my-func)

;; Test bounds checking
(test-bounds-checking 'my-function my-func valid-index invalid-index)

;; Test thread safety
(test-thread-safety 'my-function my-func 5)  ;; 5 threads
```

#### Type Validation
```racket
;; Test return type validation
(test-return-type 'my-function my-func 'String args...)

;; Test immutability
(test-immutability 'my-function my-func input)
```

## API-Specific Contract Tests

### Pattern API Tests (`pattern-api.rkt`)

Tests for pattern creation and validation:

- Pattern creation with valid rows
- Row number validation (consecutive, starting from 1)
- Stitch count consistency across rows
- Pattern validation functions
- Error handling for invalid patterns

**Key Tests:**
```racket
;; Pattern creation
(test-case "Pattern creation with valid rows" ...)

;; Stitch consistency
(test-case "Stitch count consistency across rows" ...)

;; Error cases
(test-case "Inconsistent stitch counts are rejected" ...)
```

### Chart API Tests (`chart-api.rkt`)

Tests for chart generation and manipulation:

- Chart creation from patterns
- Chart dimensions validation
- Yarn and stitch hash generation
- Float checking functionality
- Chart structure validation

**Key Tests:**
```racket
;; Chart creation
(test-case "Chart creation from valid pattern" ...)

;; Dimension validation
(test-case "Chart dimensions match pattern dimensions" ...)

;; Hash generation
(test-case "Chart yarn hash generation" ...)
```

### CLI API Tests (`cli-api.rkt`)

Tests for command-line interface:

- Command-line argument parsing
- File format validation
- Input/output file handling
- Logging level management
- Error handling for invalid inputs

**Key Tests:**
```racket
;; Argument validation
(test-case "CLI validates input format flags" ...)

;; File handling
(test-case "CLI handles existing input files" ...)

;; Error cases
(test-case "CLI handles missing input files gracefully" ...)
```

## Integration Testing

The `integration.rkt` module provides comprehensive integration tests:

### Full Integration Test Suite
```racket
;; Run all contract tests across APIs
(run-full-integration-tests)
```

### Cross-API Integration
Tests that validate API interactions:
```racket
;; Test pattern → chart workflow
(test-case "Pattern to Chart API integration" ...)
```

### Performance Integration
Tests performance characteristics across modules:
```racket
(run-performance-integration-tests)
```

## Best Practices

### 1. Contract Definition
- Define clear preconditions and postconditions
- Include appropriate error conditions
- Use specific parameter and return types

### 2. Test Organization
- Group related tests by functionality
- Use descriptive test names
- Include both positive and negative test cases

### 3. Error Testing
- Test all documented error conditions
- Verify error messages are informative
- Test boundary conditions

### 4. Performance Testing
- Set realistic performance bounds
- Test with representative data sizes
- Include memory usage validation

## Integration with RackUnit

The framework integrates seamlessly with RackUnit:

```racket
(module+ test
  (test-case "My Contract Test Suite"
    (define suite (run-my-contract-tests))
    (display-test-suite-results suite)

    ;; Convert to RackUnit assertions
    (run-contract-tests-with-rackunit my-test-functions)))
```

## Running Tests

### Individual API Tests
```bash
# Run pattern API tests
raco test knotty/tests/contract/pattern-api.rkt

# Run chart API tests
raco test knotty/tests/contract/chart-api.rkt

# Run CLI API tests
raco test knotty/tests/contract/cli-api.rkt
```

### Full Test Suite
```bash
# Run all contract tests
raco test knotty/tests/contract/

# Run with integration tests
raco test knotty/tests/contract/integration.rkt
```

### Via Make
```bash
# Run all tests including contract tests
make test

# Run with error tracing
make test-with-errortrace
```

## Racket v8.18 Compatibility

The framework is designed for compatibility with Racket v8.18:

- Uses Typed Racket for type safety
- Compatible with modern RackUnit testing
- Follows current Racket idioms and patterns
- Uses appropriate thread and memory APIs

## Error Reporting

The framework provides detailed error reporting:

- Clear test failure descriptions
- Expected vs. actual value comparisons
- Performance metrics and bounds
- Aggregated suite statistics

## Extending the Framework

### Adding New Test Types
```racket
;; Define new test helper
(: test-my-property (Symbol (Any -> Any) Any -> ContractTestResult))
(define (test-my-property func-name func input)
  ;; Implementation
  (ContractTestResult func-name "my property test"
                      result expected actual error-msg))
```

### Adding New API Tests
1. Create new `.rkt` file in `knotty/tests/contract/`
2. Follow the pattern of existing API test files
3. Include in integration test suite
4. Add to documentation

## Troubleshooting

### Common Issues

1. **Type Errors**: Ensure proper type annotations in Typed Racket
2. **Contract Failures**: Check preconditions and postconditions are correctly specified
3. **Performance Failures**: Adjust time/memory bounds for your system
4. **Integration Failures**: Verify API dependencies are correctly imported

### Debugging Tips

- Use `display-test-suite-results` for detailed output
- Check individual test results with `ContractTestResult-error-message`
- Run tests with error tracing: `make test-with-errortrace`
- Use integration tests to validate framework functionality

## Contributing

When adding new contract tests:

1. Follow existing patterns and naming conventions
2. Include both positive and negative test cases
3. Add performance bounds appropriate for the functionality
4. Update integration tests if adding new APIs
5. Document new test types and patterns

## License

This contract testing framework is part of the Knotty project and follows the same GPL-3.0 license terms.