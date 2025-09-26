#lang typed/racket

#|
    Contract Test Suite Runner

    Master test runner for the Knotty contract testing framework.
    Runs all contract tests, validates framework compatibility,
    and provides comprehensive reporting.

    Usage:
    1. Run from command line: racket run-all.rkt
    2. Include in other modules: (require "run-all.rkt")
    3. Call programmatically: (run-all-contract-tests)
|#

(require typed/rackunit
         "framework.rkt"
         "compatibility.rkt"
         "pattern-api.rkt"
         "chart-api.rkt"
         "cli-api.rkt"
         "integration.rkt")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Master Test Runner

(: run-all-contract-tests (-> Void))
(define (run-all-contract-tests)
  (printf "╔══════════════════════════════════════════════════════════════════╗\n")
  (printf "║                    Knotty Contract Test Suite                   ║\n")
  (printf "║                      Racket v8.18 Compatible                    ║\n")
  (printf "╚══════════════════════════════════════════════════════════════════╝\n\n")

  ;; Step 1: Check compatibility
  (printf "🔧 Checking Racket v8.18 Compatibility...\n")
  (define compatible? (run-compatibility-tests))
  (when (not compatible?)
    (printf "\n⚠️  WARNING: Compatibility issues detected. Some tests may fail.\n")
    (printf "   Please ensure you're running Racket v8.18 or later.\n\n"))

  ;; Step 2: Run framework validation
  (printf "\n🧪 Validating Contract Test Framework...\n")
  (define framework-suite (validate-framework-functionality))
  (display-test-suite-results framework-suite)

  ;; Step 3: Run API contract tests
  (printf "\n📋 Running API Contract Tests...\n")

  (printf "\n  🔹 Pattern API Tests:\n")
  (define pattern-suite (run-pattern-api-contract-tests))
  (display-test-suite-results pattern-suite)

  (printf "\n  🔹 Chart API Tests:\n")
  (define chart-suite (run-chart-api-contract-tests))
  (display-test-suite-results chart-suite)

  (printf "\n  🔹 CLI API Tests:\n")
  (define cli-suite (run-cli-api-contract-tests))
  (display-test-suite-results cli-suite)

  ;; Step 4: Run integration tests
  (printf "\n🔗 Running Integration Tests...\n")

  (printf "\n  🔹 Performance Integration:\n")
  (define performance-suite (run-performance-integration-tests))
  (display-test-suite-results performance-suite)

  (printf "\n  🔹 Error Handling Integration:\n")
  (define error-suite (run-error-handling-integration-tests))
  (display-test-suite-results error-suite)

  ;; Step 5: Generate comprehensive report
  (generate-test-report
   (list framework-suite pattern-suite chart-suite cli-suite
         performance-suite error-suite))

  (printf "\n✅ Contract test suite execution complete!\n"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Comprehensive Reporting

(: generate-test-report ((Listof ContractTestSuite) -> Void))
(define (generate-test-report suites)
  (printf "\n")
  (printf "╔══════════════════════════════════════════════════════════════════╗\n")
  (printf "║                        COMPREHENSIVE REPORT                     ║\n")
  (printf "╚══════════════════════════════════════════════════════════════════╝\n")

  ;; Calculate totals
  (define total-tests
    (apply + (map (λ (suite)
                    (+ (ContractTestSuite-passed suite)
                       (ContractTestSuite-failed suite)))
                  suites)))

  (define total-passed
    (apply + (map ContractTestSuite-passed suites)))

  (define total-failed
    (apply + (map ContractTestSuite-failed suites)))

  (define success-rate
    (if (= total-tests 0) 100.0
        (exact->inexact (* 100 (/ total-passed total-tests)))))

  ;; Overall statistics
  (printf "\n📊 Overall Statistics:\n")
  (printf "   Total Tests:    %4d\n" total-tests)
  (printf "   Passed:         %4d\n" total-passed)
  (printf "   Failed:         %4d\n" total-failed)
  (printf "   Success Rate:   %5.1f%%\n" success-rate)

  ;; Per-suite breakdown
  (printf "\n📈 Per-Suite Breakdown:\n")
  (for ([suite suites])
    (define suite-total (+ (ContractTestSuite-passed suite)
                           (ContractTestSuite-failed suite)))
    (define suite-rate
      (if (= suite-total 0) 100.0
          (exact->inexact (* 100 (/ (ContractTestSuite-passed suite) suite-total)))))

    (printf "   %-25s %3d/%3d (%5.1f%%)\n"
            (string-append (ContractTestSuite-name suite) ":")
            (ContractTestSuite-passed suite)
            suite-total
            suite-rate))

  ;; Recommendations
  (printf "\n💡 Recommendations:\n")
  (cond
    [(= total-failed 0)
     (printf "   🎉 Excellent! All contract tests are passing.\n")
     (printf "   📦 Your API contracts are well-defined and implemented.\n")]

    [(<= total-failed 2)
     (printf "   ⚠️  Minor issues detected in %d test(s).\n" total-failed)
     (printf "   🔍 Review failed tests for potential contract violations.\n")]

    [(<= total-failed 5)
     (printf "   ⚠️  Several issues detected in %d test(s).\n" total-failed)
     (printf "   🔧 Consider reviewing API implementations and contracts.\n")]

    [else
     (printf "   🚨 Significant issues detected in %d test(s).\n" total-failed)
     (printf "   🏗️  Major contract violations may indicate design issues.\n")])

  ;; Quality metrics
  (printf "\n📋 Quality Metrics:\n")
  (printf "   Contract Coverage:     %s\n"
          (if (>= (length suites) 3) "Good" "Needs Improvement"))
  (printf "   Integration Testing:   %s\n"
          (if (any-integration-tests? suites) "Present" "Missing"))
  (printf "   Performance Testing:   %s\n"
          (if (any-performance-tests? suites) "Present" "Missing"))
  (printf "   Error Testing:         %s\n"
          (if (any-error-tests? suites) "Present" "Missing"))

  (printf "\n")
  (printf "╔══════════════════════════════════════════════════════════════════╗\n")
  (printf "║  Report generated by Knotty Contract Test Framework v1.0        ║\n")
  (printf "╚══════════════════════════════════════════════════════════════════╝\n"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helper Functions for Report Generation

(: any-integration-tests? ((Listof ContractTestSuite) -> Boolean))
(define (any-integration-tests? suites)
  (ormap (λ (suite)
           (string-contains? (ContractTestSuite-name suite) "Integration"))
         suites))

(: any-performance-tests? ((Listof ContractTestSuite) -> Boolean))
(define (any-performance-tests? suites)
  (ormap (λ (suite)
           (ormap (λ (test)
                    (string-contains? (ContractTestResult-test-name test) "performance"))
                  (ContractTestSuite-tests suite)))
         suites))

(: any-error-tests? ((Listof ContractTestSuite) -> Boolean))
(define (any-error-tests? suites)
  (ormap (λ (suite)
           (ormap (λ (test)
                    (or (string-contains? (ContractTestResult-test-name test) "error")
                        (string-contains? (ContractTestResult-test-name test) "exception")))
                  (ContractTestSuite-tests suite)))
         suites))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Command Line Interface

(module+ main
  ;; When run directly, execute all contract tests
  (run-all-contract-tests))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RackUnit Integration

(module+ test
  (test-case "Master Contract Test Suite"
    ;; Run the full test suite and validate it doesn't crash
    (check-not-exn
     (λ () (run-all-contract-tests))
     "Master test suite should run without exceptions")

    ;; Validate compatibility
    (check-true (run-compatibility-tests)
                "Racket v8.18 compatibility should pass")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Export for External Use

(provide run-all-contract-tests
         generate-test-report)

;; end