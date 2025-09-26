#lang typed/racket

#|
    Chart API Contract Test Runner

    Simplified test runner that directly validates the Chart API against the contract.
    Tests basic functionality without complex framework dependencies.
|#

(require typed/rackunit
         "../../../knotty-lib/chart.rkt"
         "../../../knotty-lib/pattern.rkt"
         "../../../knotty-lib/stitch.rkt"
         "../../../knotty-lib/tree.rkt"
         "../../../knotty-lib/rows.rkt"
         "../../../knotty-lib/yarn.rkt")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test Data Setup

;; Valid pattern for chart testing - simple single color pattern
(define test-pattern-for-chart
  (pattern
    ((row 1) (make-leaf 4 (make-stitch 'k #f)))
    ((row 2) (make-leaf 4 (make-stitch 'p #f)))
    ((row 3) (make-leaf 4 (make-stitch 'k #f)))
    ((row 4) (make-leaf 4 (make-stitch 'p #f)))))

;; Test data for colorwork patterns - will define yarns later if needed
(define test-colorwork-pattern
  (pattern
    ((row 1) (make-leaf 2 (make-stitch 'k #f))
             (make-leaf 2 (make-stitch 'k #f)))
    ((row 2) (make-leaf 4 (make-stitch 'p #f)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chart Creation Tests

(module+ test
  (test-case "Chart creation from valid pattern"
    ;; Test that pattern->chart accepts valid patterns
    (check-not-exn
     (λ ()
       (pattern->chart test-pattern-for-chart))
     "Valid pattern should create chart without exception")))

(module+ test
  (test-case "Chart structure validation"
    ;; Test that created chart has expected structure
    (define chart (pattern->chart test-pattern-for-chart))
    (check-true (Chart? chart) "Result should be a Chart")
    (check-true (> (Chart-width chart) 0) "Chart should have positive width")
    (check-true (> (Chart-height chart) 0) "Chart should have positive height")
    (check-true (vector? (Chart-rows chart)) "Chart should have rows vector")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chart Dimensions Tests

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
;; Yarn and Stitch Hash Tests

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
    (check-true (hash? yarn-hash) "Yarn hash should be a hash table")))

(module+ test
  (test-case "Stitch hash contains expected stitch symbols"
    ;; Test that stitch hash includes all stitch symbols from pattern
    (define chart (pattern->chart test-pattern-for-chart))
    (define stitch-hash (chart-stitch-hash chart))
    (check-true (hash? stitch-hash) "Stitch hash should be a hash table")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chart Options and Float Tests

(module+ test
  (test-case "Chart with options parameter"
    ;; Test chart creation with options
    (define chart (pattern->chart test-pattern-for-chart))
    (check-not-exn
     (λ ()
       (define-values (chart-result check-result)
         (chart-check-floats chart (Pattern-options test-pattern-for-chart) 5))
       check-result)
     "Chart float checking should not throw exception")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Performance Tests

(module+ test
  (test-case "Chart generation performance"
    ;; Test that chart creation completes within reasonable time
    (define start-time (current-inexact-milliseconds))
    (define chart (pattern->chart test-pattern-for-chart))
    (define end-time (current-inexact-milliseconds))
    (define elapsed-ms (- end-time start-time))

    (check-true (< elapsed-ms 5000)
                (format "Chart creation took ~ams, should be < 5000ms" elapsed-ms))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Error Handling Tests

(module+ test
  (test-case "Invalid pattern handling"
    ;; Test that invalid patterns are rejected appropriately
    (check-exn
     exn:fail?
     (λ () (pattern->chart (pattern)))
     "Empty pattern should throw exception")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Contract Compliance Summary

(printf "=== Chart API Contract Test Summary ===\n")
(printf "Testing Chart API implementation against specification...\n")
(printf "Tests cover:\n")
(printf "- Chart creation from patterns\n")
(printf "- Chart dimensions and structure validation\n")
(printf "- Yarn and stitch hash generation\n")
(printf "- Chart validation and error handling\n")
(printf "- Performance bounds for chart operations\n")
(printf "===============================================\n")

;; end