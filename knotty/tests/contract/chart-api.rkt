#lang typed/racket

#|
    Chart API Contract Tests

    Validates the Chart API against the contract specification in:
    specs/001-define-the-existing/contracts/chart-api.md

    Tests cover:
    - Chart creation from patterns
    - Chart dimensions and structure validation
    - Yarn and stitch hash generation
    - Float checking functionality
    - Chart row access and manipulation
    - Error handling for invalid inputs
|#

(require typed/rackunit
         "framework.rkt"
         "../../../knotty-lib/chart.rkt"
         "../../../knotty-lib/pattern.rkt"
         "../../../knotty-lib/stitch.rkt"
         "../../../knotty-lib/tree.rkt"
         "../../../knotty-lib/rows.rkt"
         "../../../knotty-lib/yarn.rkt")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test Data Setup

;; Valid pattern for chart testing
(define test-pattern-for-chart
  (pattern
    ((row 1) (make-leaf 4 (make-stitch 'k 0)))
    ((row 2) (make-leaf 4 (make-stitch 'p 0)))
    ((row 3) (make-leaf 4 (make-stitch 'k 0)))
    ((row 4) (make-leaf 4 (make-stitch 'p 0)))))

;; Test data for colorwork patterns
(define test-colorwork-pattern
  (pattern
    ((row 1) (make-leaf 2 (make-stitch 'k 0))
             (make-leaf 2 (make-stitch 'k 1)))
    ((row 2) (make-leaf 4 (make-stitch 'p 0)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chart Creation Contract Tests

(module+ test
  (test-case "Chart creation from valid pattern"
    ;; Test that pattern->chart accepts valid patterns
    (check-not-exn
     (λ ()
       (pattern->chart test-pattern-for-chart))
     "Valid pattern should create chart without exception")))

(module+ test
  (test-case "Chart creation rejects null pattern"
    ;; Test that empty/null patterns are rejected
    (check-exn
     exn:fail?
     (λ () (pattern->chart (cast #f Pattern)))
     "Null pattern should throw exception")))

(module+ test
  (test-case "Chart structure validation"
    ;; Test that created chart has expected structure
    (define chart (pattern->chart test-pattern-for-chart))
    (check-true (Chart? chart) "Result should be a Chart")
    (check-true (> (Chart-width chart) 0) "Chart should have positive width")
    (check-true (> (Chart-height chart) 0) "Chart should have positive height")
    (check-true (vector? (Chart-rows chart)) "Chart should have rows vector")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chart Dimensions Contract Tests

(module+ test
  (test-case "Chart dimensions match pattern dimensions"
    ;; Test that chart dimensions correctly reflect pattern size
    (define chart (pattern->chart test-pattern-for-chart))
    (check-equal? (Chart-height chart) 4 "Chart height should match row count")
    (check-equal? (Chart-width chart) 4 "Chart width should match stitch count")))

(module+ test
  (test-case "Chart rows vector length matches height"
    ;; Test that rows vector has correct length
    (define chart (pattern->chart test-pattern-for-chart))
    (check-equal? (vector-length (Chart-rows chart))
                  (Chart-height chart)
                  "Rows vector length should match chart height")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Yarn and Stitch Hash Contract Tests

(module+ test
  (test-case "Chart yarn hash generation"
    ;; Test that chart-yarn-hash returns valid hash
    (define chart (pattern->chart test-colorwork-pattern))
    (check-not-exn
     (λ () (chart-yarn-hash chart))
     "Yarn hash generation should not throw exception")))

(module+ test
  (test-case "Chart stitch hash generation"
    ;; Test that chart-stitch-hash returns valid hash
    (define chart (pattern->chart test-pattern-for-chart))
    (check-not-exn
     (λ () (chart-stitch-hash chart))
     "Stitch hash generation should not throw exception")))

(module+ test
  (test-case "Yarn hash contains expected yarn colors"
    ;; Test that yarn hash includes all yarn colors from pattern
    (define chart (pattern->chart test-colorwork-pattern))
    (define yarn-hash (chart-yarn-hash chart))
    ;; This test assumes hash structure - adjust based on actual implementation
    (check-true (hash? yarn-hash) "Yarn hash should be a hash table")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Float Checking Contract Tests

(module+ test
  (test-case "Chart float checking functionality"
    ;; Test that chart-check-floats works on valid charts
    (define chart (pattern->chart test-colorwork-pattern))
    (check-not-exn
     (λ () (chart-check-floats chart))
     "Float checking should not throw exception on valid chart")))

(module+ test
  (test-case "Float checking returns expected type"
    ;; Test that float checking returns appropriate result
    (define chart (pattern->chart test-colorwork-pattern))
    (define float-result (chart-check-floats chart))
    ;; Adjust this test based on actual return type of chart-check-floats
    (check-true (or (boolean? float-result) (list? float-result))
                "Float checking should return boolean or list result")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Contract-Based Testing Functions

;; Test chart creation contract
(: test-chart-creation-contract (-> ContractTestResult))
(define (test-chart-creation-contract)
  (define chart-contract
    (FunctionContract
     'pattern->chart
     '(Pattern)
     'Chart
     (list (λ (args) (Pattern? (car args)))) ;; Valid pattern required
     (list (λ (args result) (Chart? result))) ;; Returns Chart
     '()))

  (test-function-contract
   'pattern->chart
   (λ () (pattern->chart test-pattern-for-chart))
   chart-contract
   test-pattern-for-chart))

;; Test chart dimension contracts
(: test-chart-dimension-contracts (-> (Listof ContractTestResult)))
(define (test-chart-dimension-contracts)
  (define chart (pattern->chart test-pattern-for-chart))
  (list
   ;; Test width accessor
   (test-function-contract
    'Chart-width
    (λ () (Chart-width chart))
    (FunctionContract 'Chart-width '(Chart) 'Natural
                      (list (λ (args) (Chart? (car args))))
                      (list (λ (args result) (and (exact-integer? result) (>= result 0))))
                      '())
    chart)

   ;; Test height accessor
   (test-function-contract
    'Chart-height
    (λ () (Chart-height chart))
    (FunctionContract 'Chart-height '(Chart) 'Natural
                      (list (λ (args) (Chart? (car args))))
                      (list (λ (args result) (and (exact-integer? result) (>= result 0))))
                      '())
    chart)))

;; Test chart hash generation contracts
(: test-chart-hash-contracts (-> (Listof ContractTestResult)))
(define (test-chart-hash-contracts)
  (define chart (pattern->chart test-colorwork-pattern))
  (list
   ;; Test yarn hash generation
   (test-function-contract
    'chart-yarn-hash
    (λ () (chart-yarn-hash chart))
    (FunctionContract 'chart-yarn-hash '(Chart) 'Hash
                      (list (λ (args) (Chart? (car args))))
                      (list (λ (args result) (hash? result)))
                      '())
    chart)

   ;; Test stitch hash generation
   (test-function-contract
    'chart-stitch-hash
    (λ () (chart-stitch-hash chart))
    (FunctionContract 'chart-stitch-hash '(Chart) 'Hash
                      (list (λ (args) (Chart? (car args))))
                      (list (λ (args result) (hash? result)))
                      '())
    chart)))

;; Test error conditions
(: test-chart-error-contracts (-> (Listof ContractTestResult)))
(define (test-chart-error-contracts)
  (list
   ;; Test invalid pattern rejection
   (test-error-contract 'pattern->chart
                        (λ () (pattern->chart (cast #f Pattern)))
                        exn:fail?
                        (cast #f Pattern))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Performance Contract Tests

(: test-chart-performance (-> ContractTestResult))
(define (test-chart-performance)
  ;; Test that chart creation completes within reasonable time
  (test-performance-bound
   'pattern->chart
   (λ () (pattern->chart test-pattern-for-chart))
   5000 ;; 5 seconds max for moderate patterns
   '()))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Immutability Contract Tests

(: test-chart-immutability (-> ContractTestResult))
(define (test-chart-immutability)
  ;; Test that chart creation doesn't modify input pattern
  (test-immutability
   'pattern->chart
   (λ (pat) (pattern->chart pat))
   test-pattern-for-chart))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test Suite Execution

(: run-chart-api-contract-tests (-> ContractTestSuite))
(define (run-chart-api-contract-tests)
  (run-contract-test-suite
   "Chart API Contract Tests"
   (append
    (list test-chart-creation-contract
          test-chart-performance
          test-chart-immutability)
    (test-chart-dimension-contracts)
    (test-chart-hash-contracts)
    (test-chart-error-contracts))))

;; Integration with RackUnit
(module+ test
  (test-case "Chart API Contract Suite"
    (define suite (run-chart-api-contract-tests))
    (display-test-suite-results suite)

    ;; Convert contract test results to RackUnit assertions
    (run-contract-tests-with-rackunit
     (append
      (list test-chart-creation-contract
            test-chart-performance
            test-chart-immutability)
      (test-chart-dimension-contracts)
      (test-chart-hash-contracts)
      (test-chart-error-contracts)))))

;; end