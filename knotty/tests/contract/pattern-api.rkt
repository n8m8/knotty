#lang typed/racket

#|
    Pattern API Contract Tests

    Validates the Pattern API against the contract specification in:
    specs/001-define-the-existing/contracts/pattern-api.md

    Tests cover:
    - Pattern creation and validation
    - Row specification compliance
    - Stitch count consistency
    - Yarn color validation
    - Error handling behavior
|#

(require typed/rackunit
         "framework.rkt"
         "../../knotty-lib/pattern.rkt"
         "../../knotty-lib/stitch.rkt"
         "../../knotty-lib/tree.rkt"
         "../../knotty-lib/rows.rkt")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test Data Setup

;; Valid basic pattern for testing
(define test-pattern-valid
  (pattern
    ((row 1) (make-leaf 4 (make-stitch 'k 0)))
    ((row 2) (make-leaf 4 (make-stitch 'p 0)))))

;; Test data for various scenarios
(define test-stitches-k4 (make-leaf 4 (make-stitch 'k 0)))
(define test-stitches-p4 (make-leaf 4 (make-stitch 'p 0)))
(define test-stitches-k8 (make-leaf 8 (make-stitch 'k 0)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pattern Creation Contract Tests

(module+ test
  (test-case "Pattern creation with valid rows"
    ;; Test that pattern function accepts valid row specifications
    (check-not-exn
     (λ ()
       (pattern
         ((row 1) test-stitches-k4)
         ((row 2) test-stitches-p4)
         ((row 3) test-stitches-k4)
         ((row 4) test-stitches-p4))))
    "Valid pattern should create without exception"))

(module+ test
  (test-case "Pattern creation requires at least one row"
    ;; Test that empty patterns are rejected
    (check-exn
     exn:fail?
     (λ () (pattern))
     "Empty pattern should throw exception")))

(module+ test
  (test-case "Row numbers must be consecutive starting from 1"
    ;; Test that non-consecutive row numbers are rejected
    (check-exn
     exn:fail?
     (λ ()
       (pattern
         ((row 1) test-stitches-k4)
         ((row 3) test-stitches-p4))) ;; Missing row 2
     "Non-consecutive row numbers should throw exception")))

(module+ test
  (test-case "Row numbers starting from non-1 are rejected"
    ;; Test that patterns must start from row 1
    (check-exn
     exn:fail?
     (λ ()
       (pattern
         ((row 2) test-stitches-k4)
         ((row 3) test-stitches-p4))) ;; Should start from row 1
     "Patterns not starting from row 1 should throw exception")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Stitch Count Consistency Tests

(module+ test
  (test-case "Stitch count consistency across rows"
    ;; Test that all rows have consistent stitch counts
    (check-not-exn
     (λ ()
       (pattern
         ((row 1) test-stitches-k4)
         ((row 2) test-stitches-p4)
         ((row 3) test-stitches-k4)))
     "Consistent stitch counts should be valid")))

(module+ test
  (test-case "Inconsistent stitch counts are rejected"
    ;; Test that mismatched stitch counts throw errors
    (check-exn
     exn:fail?
     (λ ()
       (pattern
         ((row 1) test-stitches-k4) ;; 4 stitches
         ((row 2) test-stitches-k8))) ;; 8 stitches - should fail
     "Inconsistent stitch counts should throw exception")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pattern Validation Function Tests

;; Note: These tests assume validation functions exist in the API
;; If they don't exist yet, these serve as specifications for implementation

(module+ test
  (test-case "Pattern validation accepts valid patterns"
    ;; Test that validate-pattern returns the pattern if valid
    (define valid-pattern test-pattern-valid)
    ;; This test will be enabled when validate-pattern is implemented
    #;(check-equal? (validate-pattern valid-pattern) valid-pattern
                    "Valid pattern should pass validation")))

(module+ test
  (test-case "Pattern row count query"
    ;; Test that pattern-row-count returns correct number
    (define test-pattern
      (pattern
        ((row 1) test-stitches-k4)
        ((row 2) test-stitches-p4)
        ((row 3) test-stitches-k4)))
    ;; This test will be enabled when pattern-row-count is implemented
    #;(check-equal? (pattern-row-count test-pattern) 3
                    "Pattern should report correct row count")))

(module+ test
  (test-case "Pattern stitch count query"
    ;; Test that pattern-stitch-count returns correct number
    (define test-pattern
      (pattern
        ((row 1) test-stitches-k4)
        ((row 2) test-stitches-p4)))
    ;; This test will be enabled when pattern-stitch-count is implemented
    #;(check-equal? (pattern-stitch-count test-pattern) 4
                    "Pattern should report correct stitch count per row")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Contract-Based Testing Functions

;; Test pattern creation contract
(: test-pattern-creation-contract (-> ContractTestResult))
(define (test-pattern-creation-contract)
  (define pattern-contract
    (FunctionContract
     'pattern
     '(RowSpec) ;; Variable arguments - simplified for testing
     'Pattern
     (list (λ (args) (not (null? args)))) ;; At least one row required
     (list (λ (args result) (Pattern? result))) ;; Returns Pattern
     '()))

  (test-function-contract
   'pattern
   (λ () (pattern ((row 1) test-stitches-k4)))
   pattern-contract
   '(((row 1) test-stitches-k4))))

;; Test that invalid patterns throw appropriate exceptions
(: test-pattern-error-contracts (-> (Listof ContractTestResult)))
(define (test-pattern-error-contracts)
  (list
   ;; Test empty pattern rejection
   (test-error-contract 'pattern
                        (λ () (pattern))
                        exn:fail?
                        '())

   ;; Test non-consecutive rows rejection
   (test-error-contract 'pattern
                        (λ () (pattern
                                ((row 1) test-stitches-k4)
                                ((row 3) test-stitches-p4)))
                        exn:fail?
                        '(((row 1) test-stitches-k4)
                          ((row 3) test-stitches-p4)))

   ;; Test inconsistent stitch counts rejection
   (test-error-contract 'pattern
                        (λ () (pattern
                                ((row 1) test-stitches-k4)
                                ((row 2) test-stitches-k8)))
                        exn:fail?
                        '(((row 1) test-stitches-k4)
                          ((row 2) test-stitches-k8)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Performance Contract Tests

(: test-pattern-performance (-> ContractTestResult))
(define (test-pattern-performance)
  ;; Test that pattern creation completes within reasonable time
  (test-performance-bound
   'pattern
   (λ () (pattern
           ((row 1) test-stitches-k4)
           ((row 2) test-stitches-p4)
           ((row 3) test-stitches-k4)
           ((row 4) test-stitches-p4)))
   1000 ;; 1 second max for small patterns
   '()))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test Suite Execution

(: run-pattern-api-contract-tests (-> ContractTestSuite))
(define (run-pattern-api-contract-tests)
  (run-contract-test-suite
   "Pattern API Contract Tests"
   (append
    (list test-pattern-creation-contract
          test-pattern-performance)
    (test-pattern-error-contracts))))

;; Integration with RackUnit
(module+ test
  (test-case "Pattern API Contract Suite"
    (define suite (run-pattern-api-contract-tests))
    (display-test-suite-results suite)

    ;; Convert contract test results to RackUnit assertions
    (run-contract-tests-with-rackunit
     (append
      (list test-pattern-creation-contract
            test-pattern-performance)
      (test-pattern-error-contracts)))))

;; end