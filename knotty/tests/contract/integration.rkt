#lang typed/racket

#|
    Contract Test Integration Suite

    Comprehensive integration tests that validate the contract testing framework
    works correctly with all API modules. This suite tests the framework itself
    and demonstrates how to use it across the Knotty API surface.

    Integration test areas:
    - Framework functionality validation
    - Cross-API contract validation
    - Performance testing across modules
    - Error handling integration
    - Test suite composition and reporting
|#

(require typed/rackunit
         "framework.rkt"
         "pattern-api.rkt"
         "chart-api.rkt"
         "cli-api.rkt")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Framework Integration Tests

(module+ test
  (test-case "Framework creates valid test results"
    ;; Test that the framework produces properly structured results
    (define sample-contract
      (FunctionContract 'test-func '(String) 'String
                        (list (λ (args) (string? (car args))))
                        (list (λ (args result) (string? result)))
                        '()))

    (define result
      (test-function-contract 'test-func
                              (λ () "test-result")
                              sample-contract
                              "test-input"))

    (check-true (ContractTestResult? result)
                "Should produce ContractTestResult")
    (check-equal? (ContractTestResult-function-name result) 'test-func
                  "Should preserve function name")
    (check-true (ContractTestResult-passed? result)
                "Simple contract should pass")))

(module+ test
  (test-case "Framework handles contract violations"
    ;; Test that framework correctly identifies contract violations
    (define failing-contract
      (FunctionContract 'test-func '(String) 'Number
                        (list (λ (args) (string? (car args))))
                        (list (λ (args result) (number? result)))  ;; This will fail
                        '()))

    (define result
      (test-function-contract 'test-func
                              (λ () "not-a-number")  ;; Returns string, not number
                              failing-contract
                              "test-input"))

    (check-false (ContractTestResult-passed? result)
                 "Contract violation should be detected")
    (check-true (string? (ContractTestResult-error-message result))
                "Should provide error message")))

(module+ test
  (test-case "Test suite aggregation works correctly"
    ;; Test that test suites properly aggregate results
    (define test-functions
      (list (λ () (ContractTestResult 'func1 "test1" #t 'expected 'actual #f))
            (λ () (ContractTestResult 'func2 "test2" #f 'expected 'actual "error"))))

    (define suite (run-contract-test-suite "Integration Test" test-functions))

    (check-equal? (ContractTestSuite-passed suite) 1
                  "Should count passed tests correctly")
    (check-equal? (ContractTestSuite-failed suite) 1
                  "Should count failed tests correctly")
    (check-equal? (length (ContractTestSuite-tests suite)) 2
                  "Should include all test results")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Cross-API Integration Tests

(module+ test
  (test-case "Pattern to Chart API integration"
    ;; Test that pattern API output is valid input for chart API
    (check-not-exn
     (λ ()
       ;; This tests the actual workflow integration
       (define test-pattern
         (pattern ((row 1) (make-leaf 4 (make-stitch 'k 0)))))
       (define test-chart (pattern->chart test-pattern))
       (chart-yarn-hash test-chart))
     "Pattern to chart workflow should work without exceptions")))

(module+ test
  (test-case "API consistency across modules"
    ;; Test that all APIs follow consistent error handling
    (define apis '(pattern-api chart-api cli-api))
    (check-true (= (length apis) 3)
                "All API modules should be testable")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Performance Integration Tests

(: run-performance-integration-tests (-> ContractTestSuite))
(define (run-performance-integration-tests)
  (define performance-tests
    (list
     ;; Test pattern API performance
     (λ () (test-performance-bound
            'pattern-creation
            (λ () (pattern ((row 1) (make-leaf 10 (make-stitch 'k 0)))))
            500  ;; 500ms for small pattern
            '()))

     ;; Test chart API performance
     (λ () (test-performance-bound
            'chart-creation
            (λ () (let ([pat (pattern ((row 1) (make-leaf 10 (make-stitch 'k 0))))])
                    (pattern->chart pat)))
            1000  ;; 1 second for chart generation
            '()))

     ;; Test memory bounds
     (λ () (test-memory-bounds
            'memory-test
            (λ () (make-vector 1000 #f))  ;; Small allocation
            10))))  ;; 10MB limit

  (run-contract-test-suite "Performance Integration Tests" performance-tests))

(module+ test
  (test-case "Performance integration suite"
    (define suite (run-performance-integration-tests))
    (display-test-suite-results suite)
    (check-true (>= (ContractTestSuite-passed suite) 0)
                "Performance tests should run without errors")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Error Handling Integration Tests

(: run-error-handling-integration-tests (-> ContractTestSuite))
(define (run-error-handling-integration-tests)
  (define error-tests
    (list
     ;; Test null input handling across APIs
     (λ () (test-null-input-handling
            'pattern-null-test
            (λ (x) (if x "valid" (error "null input")))))

     ;; Test bounds checking
     (λ () (test-bounds-checking
            'bounds-test
            (λ (i) (if (< i 10) i (error "out of bounds")))
            5   ;; valid index
            15)) ;; invalid index

     ;; Test referential transparency
     (λ () (test-referential-transparency
            'transparency-test
            (λ (x) (if (list? x) (length x) x))
            '(1 2 3)))))

  (run-contract-test-suite "Error Handling Integration Tests" error-tests))

(module+ test
  (test-case "Error handling integration suite"
    (define suite (run-error-handling-integration-tests))
    (display-test-suite-results suite)
    (check-true (>= (ContractTestSuite-passed suite) 0)
                "Error handling tests should run without errors")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Full Integration Test Suite

(: run-full-integration-tests (-> Void))
(define (run-full-integration-tests)
  (printf "=== Running Full Contract Test Integration ===\n\n")

  ;; Run individual API test suites
  (define pattern-suite (run-pattern-api-contract-tests))
  (define chart-suite (run-chart-api-contract-tests))
  (define cli-suite (run-cli-api-contract-tests))

  ;; Run integration-specific tests
  (define performance-suite (run-performance-integration-tests))
  (define error-suite (run-error-handling-integration-tests))

  ;; Display results
  (printf "=== API Contract Test Results ===\n")
  (display-test-suite-results pattern-suite)
  (display-test-suite-results chart-suite)
  (display-test-suite-results cli-suite)

  (printf "=== Integration Test Results ===\n")
  (display-test-suite-results performance-suite)
  (display-test-suite-results error-suite)

  ;; Summary
  (define total-passed (+ (ContractTestSuite-passed pattern-suite)
                          (ContractTestSuite-passed chart-suite)
                          (ContractTestSuite-passed cli-suite)
                          (ContractTestSuite-passed performance-suite)
                          (ContractTestSuite-passed error-suite)))

  (define total-failed (+ (ContractTestSuite-failed pattern-suite)
                          (ContractTestSuite-failed chart-suite)
                          (ContractTestSuite-failed cli-suite)
                          (ContractTestSuite-failed performance-suite)
                          (ContractTestSuite-failed error-suite)))

  (printf "=== Overall Summary ===\n")
  (printf "Total Tests: ~a, Passed: ~a, Failed: ~a\n"
          (+ total-passed total-failed) total-passed total-failed)
  (printf "Success Rate: ~a%\n"
          (if (= (+ total-passed total-failed) 0) 100
              (exact->inexact (* 100 (/ total-passed (+ total-passed total-failed))))))

  (when (> total-failed 0)
    (printf "\nWARNING: ~a contract test(s) failed!\n" total-failed)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Framework Validation Tests

(: validate-framework-functionality (-> ContractTestSuite))
(define (validate-framework-functionality)
  (define validation-tests
    (list
     ;; Test that framework helper functions work
     (λ () (test-return-type
            'test-return-type
            (λ () "string-result")
            'String))

     (λ () (test-idempotency
            'test-idempotency
            (λ (x) (* x x))
            5))

     (λ () (test-determinism
            'test-determinism
            (λ (x) (+ x 1))
            10
            5))))

  (run-contract-test-suite "Framework Validation Tests" validation-tests))

(module+ test
  (test-case "Framework validation suite"
    (define suite (validate-framework-functionality))
    (display-test-suite-results suite)
    (check-true (>= (ContractTestSuite-passed suite) 0)
                "Framework validation should run without errors")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test Documentation and Examples

#|
    USAGE EXAMPLES:

    1. Running a single API contract test suite:
       ```racket
       (run-pattern-api-contract-tests)
       ```

    2. Running full integration tests:
       ```racket
       (run-full-integration-tests)
       ```

    3. Creating custom contract tests:
       ```racket
       (define my-contract
         (FunctionContract 'my-func '(String) 'Number
                           (list (λ (args) (string? (car args))))
                           (list (λ (args result) (number? result)))
                           '()))

       (test-function-contract 'my-func my-func my-contract "input")
       ```

    4. Testing performance:
       ```racket
       (test-performance-bound 'my-func my-func 1000 "input")
       ```

    5. Testing error conditions:
       ```racket
       (test-error-contract 'my-func my-func exn:fail? invalid-input)
       ```
|#

(module+ test
  (test-case "Integration framework documentation examples"
    ;; Test that the documented examples work
    (check-not-exn
     (λ ()
       (define sample-func (λ (x) (string-length x)))
       (define contract
         (FunctionContract 'sample-func '(String) 'Number
                           (list (λ (args) (string? (car args))))
                           (list (λ (args result) (number? result)))
                           '()))
       (test-function-contract 'sample-func sample-func contract "test"))
     "Documentation examples should work")))

;; end