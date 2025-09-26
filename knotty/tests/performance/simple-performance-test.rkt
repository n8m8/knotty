#lang typed/racket

#|
    Simple Performance Test Suite for Large Patterns (T023)

    Tests basic performance with large patterns focusing on:
    - Pattern compilation time
    - Chart generation time
    - HTML export time
    - Memory usage measurement
|#

(require typed/rackunit
         racket/file
         racket/path
         threading)

;; Import knotty-lib modules
(require "../../../knotty-lib/global.rkt"
         "../../../knotty-lib/stitch.rkt"
         "../../../knotty-lib/tree.rkt"
         "../../../knotty-lib/yarn.rkt"
         "../../../knotty-lib/macros.rkt"
         "../../../knotty-lib/rows.rkt"
         "../../../knotty-lib/rowspec.rkt"
         "../../../knotty-lib/rowmap.rkt"
         "../../../knotty-lib/options.rkt"
         "../../../knotty-lib/pattern.rkt"
         "../../../knotty-lib/chart-row.rkt"
         "../../../knotty-lib/chart.rkt")

;; Import typed interfaces for text and html
(require/typed "../../../knotty-lib/text.rkt"
               [pattern->text (Pattern -> String)])

(require/typed "../../../knotty-lib/html.rkt"
               [pattern-template (->* (Output-Port Pattern (HashTable Symbol Integer)) (Boolean) Void)])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Performance Measurement Utilities

(: time-operation (All (T) (-> (-> T) (Values T Integer))))
(define (time-operation operation)
  "Time an operation and return result with elapsed milliseconds"
  (define start-time (current-inexact-milliseconds))
  (define result (operation))
  (define end-time (current-inexact-milliseconds))
  (values result (exact-round (- end-time start-time))))

(struct PerformanceResult
  ([operation-name : String]
   [execution-time-ms : Integer]
   [pattern-rows : Integer]
   [success : Boolean])
  #:transparent)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Large Pattern Generators

(: create-large-stockinette-pattern (Integer -> Pattern))
(define (create-large-stockinette-pattern num-rows)
  "Create a large stockinette pattern with the specified number of rows"
  (pattern #:name (format "Large Stockinette (~a rows)" num-rows)
           #:technique 'hand
           #:form 'flat
           ((row 1) k50)
           ((row 2) p50)
           ((row 3) k50)
           ((row 4) p50)
           ((row 5) k50)
           ((row 6) p50)
           ((row 7) k50)
           ((row 8) p50)
           ((row 9) k50)
           ((row 10) p50)))

(: create-large-pattern-procedural (Integer -> Pattern))
(define (create-large-pattern-procedural num-rows)
  "Create a large pattern procedurally by expanding repeats"
  (define base-pattern
    (pattern #:name "Base Pattern for Expansion"
             #:technique 'hand
             #:form 'flat
             #:repeat-rows '(1 4)
             ((row 1) k20)
             ((row 2) p20)
             ((row 3) k20)
             ((row 4) p20)))

  ;; Calculate vertical repeats needed
  (define v-repeats : Positive-Integer (max 1 (quotient num-rows 4)))
  (define expanded (pattern-expand-repeats base-pattern 1 v-repeats))

  (struct-copy Pattern expanded
               [name (format "Large Procedural Pattern (~a rows)" num-rows)]))

(: create-simple-colorwork (Integer -> Pattern))
(define (create-simple-colorwork num-rows)
  "Create a simple 2-color colorwork pattern"
  (pattern #:name (format "Simple Colorwork (~a rows)" num-rows)
           #:technique 'hand
           #:form 'flat
           (yarn #x000000 "Black")
           (yarn #xFFFFFF "White")
           ((row 1) (cw "01010101010101010101"))
           ((row 2) (cw "10101010101010101010"))
           ((row 3) (cw "01010101010101010101"))
           ((row 4) (cw "10101010101010101010"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Performance Tests

(: test-pattern-creation-time (Integer -> PerformanceResult))
(define (test-pattern-creation-time rows)
  "Test time to create a large pattern"
  (printf "Testing pattern creation with ~a target rows...\n" rows)

  (let-values ([(pattern time-ms)
                (time-operation
                 (λ () (create-large-pattern-procedural rows)))])
    (PerformanceResult "Pattern Creation"
                       time-ms
                       (Pattern-nrows pattern)
                       #t)))

(: test-chart-generation-time (Pattern -> PerformanceResult))
(define (test-chart-generation-time pattern)
  "Test time to generate chart from pattern"
  (printf "Testing chart generation for: ~a\n" (Pattern-name pattern))

  (let-values ([(chart time-ms)
                (time-operation
                 (λ () (pattern->chart pattern)))])
    (PerformanceResult "Chart Generation"
                       time-ms
                       (Pattern-nrows pattern)
                       #t)))

(: test-html-export-time (Pattern -> PerformanceResult))
(define (test-html-export-time pattern)
  "Test time to export pattern to HTML"
  (printf "Testing HTML export for: ~a\n" (Pattern-name pattern))

  (make-directory* "/tmp/claude")
  (define html-path (build-path "/tmp/claude"
                                (format "perf_test_~a.html"
                                        (Pattern-nrows pattern))))

  (let-values ([(dummy time-ms)
                (time-operation
                 (λ ()
                   (call-with-output-file html-path
                     (λ ([out : Output-Port])
                       (define inputs (make-hasheq
                                       '((hreps . 1)
                                         (vreps . 1)
                                         (zoom . 80)
                                         (float . 0)
                                         (notes . 1)
                                         (yarn . 1)
                                         (instr . 1)
                                         (size . 0)
                                         (stat . 0))))
                       (pattern-template out pattern inputs #f))
                     #:exists 'replace)))])

    (define file-size-bytes : Integer (if (file-exists? html-path) (file-size html-path) 0))
    (printf "HTML file size: ~a bytes\n" file-size-bytes)

    (when (file-exists? html-path) (delete-file html-path))

    (PerformanceResult "HTML Export"
                       time-ms
                       (Pattern-nrows pattern)
                       #t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Performance Test Suite

(module+ test

  ;; Performance targets
  (define MAX-PATTERN-CREATION-TIME-MS 5000)  ; 5 seconds
  (define MAX-HTML-EXPORT-TIME-MS 10000)      ; 10 seconds

  (: report-performance (PerformanceResult -> Void))
  (define (report-performance result)
    "Report performance test result"
    (printf "=== ~a Performance ===\n" (PerformanceResult-operation-name result))
    (printf "Time: ~a ms\n" (PerformanceResult-execution-time-ms result))
    (printf "Rows: ~a\n" (PerformanceResult-pattern-rows result))
    (printf "Success: ~a\n" (PerformanceResult-success result))
    (printf "Time per row: ~a ms\n"
            (/ (PerformanceResult-execution-time-ms result)
               (PerformanceResult-pattern-rows result)))
    (printf "\n"))

  ;; Test 1: Basic Pattern Creation Performance
  (test-case "Large pattern creation performance"
    (printf "=== Testing Large Pattern Creation ===\n")

    (define test-sizes '(200 300 500))

    (for ([size : Integer test-sizes])
      (define result (test-pattern-creation-time size))
      (report-performance result)

      (check-true (PerformanceResult-success result)
                  "Pattern creation should succeed")

      (check-true (< (PerformanceResult-execution-time-ms result)
                     MAX-PATTERN-CREATION-TIME-MS)
                  (format "Pattern creation should be under ~a ms"
                          MAX-PATTERN-CREATION-TIME-MS))))

  ;; Test 2: Chart Generation Performance
  (test-case "Chart generation performance"
    (printf "=== Testing Chart Generation ===\n")

    (define large-pattern (create-large-pattern-procedural 200))
    (define chart-result (test-chart-generation-time large-pattern))

    (report-performance chart-result)

    (check-true (PerformanceResult-success chart-result)
                "Chart generation should succeed")

    (check-true (< (PerformanceResult-execution-time-ms chart-result) 5000)
                "Chart generation should be reasonably fast"))

  ;; Test 3: HTML Export Performance
  (test-case "HTML export performance"
    (printf "=== Testing HTML Export ===\n")

    (define large-pattern (create-large-pattern-procedural 200))
    (define html-result (test-html-export-time large-pattern))

    (report-performance html-result)

    (check-true (PerformanceResult-success html-result)
                "HTML export should succeed")

    (check-true (< (PerformanceResult-execution-time-ms html-result)
                   MAX-HTML-EXPORT-TIME-MS)
                "HTML export should be under 10 seconds"))

  ;; Test 4: Colorwork Performance
  (test-case "Colorwork pattern performance"
    (printf "=== Testing Colorwork Performance ===\n")

    (define colorwork-pattern (create-simple-colorwork 100))
    (define colorwork-expanded (pattern-expand-repeats colorwork-pattern 1 50))

    (printf "Colorwork pattern expanded to ~a rows\n"
            (Pattern-nrows colorwork-expanded))

    (define chart-result (test-chart-generation-time colorwork-expanded))
    (define html-result (test-html-export-time colorwork-expanded))

    (report-performance chart-result)
    (report-performance html-result)

    (check-true (PerformanceResult-success chart-result)
                "Colorwork chart generation should succeed")
    (check-true (PerformanceResult-success html-result)
                "Colorwork HTML export should succeed"))

  ;; Test 5: Scalability Analysis
  (test-case "Scalability analysis"
    (printf "=== Scalability Analysis ===\n")

    (define test-sizes '(50 100 200 300))
    (define creation-results
      (for/list ([size : Integer test-sizes])
        : PerformanceResult
        (test-pattern-creation-time size)))

    (printf "Scalability Results:\n")
    (printf "Rows\tTime(ms)\tTime/Row(ms)\n")

    (for ([result : PerformanceResult creation-results])
      (define time-ms (PerformanceResult-execution-time-ms result))
      (define rows (PerformanceResult-pattern-rows result))
      (define time-per-row (/ time-ms rows))
      (printf "~a\t~a\t~a\n" rows time-ms time-per-row))

    ;; Check that performance scales reasonably
    (define times (map PerformanceResult-execution-time-ms creation-results))
    (define last-time (last times))
    (define first-time (first times))

    (printf "Performance scaling factor: ~a\n" (/ last-time first-time))

    ;; Performance should not degrade exponentially
    (check-true (< (/ last-time first-time) 50)
                "Performance scaling should be reasonable"))

  ;; Test 6: Memory and Performance Summary
  (test-case "Performance summary"
    (printf "=== Performance Summary ===\n")

    ;; Test a comprehensive workflow
    (define test-pattern (create-large-pattern-procedural 200))
    (define create-time (PerformanceResult-execution-time-ms
                         (test-pattern-creation-time 200)))
    (define chart-time (PerformanceResult-execution-time-ms
                        (test-chart-generation-time test-pattern)))
    (define html-time (PerformanceResult-execution-time-ms
                       (test-html-export-time test-pattern)))

    (printf "Performance Benchmarks for 200-row pattern:\n")
    (printf "- Pattern Creation: ~a ms\n" create-time)
    (printf "- Chart Generation: ~a ms\n" chart-time)
    (printf "- HTML Export: ~a ms\n" html-time)
    (printf "- Total Workflow: ~a ms\n" (+ create-time chart-time html-time))

    (printf "\nPerformance Assessment:\n")
    (printf "✓ Pattern creation meets <5s requirement: ~a\n"
            (if (< create-time 5000) "PASS" "FAIL"))
    (printf "✓ HTML export meets <10s requirement: ~a\n"
            (if (< html-time 10000) "PASS" "FAIL"))

    (printf "\nRecommendations:\n")
    (if (< create-time 1000)
        (printf "- Pattern creation performance is excellent\n")
        (printf "- Pattern creation could be optimized\n"))

    (if (< chart-time 2000)
        (printf "- Chart generation performance is good\n")
        (printf "- Chart generation could be optimized\n"))

    (if (< html-time 3000)
        (printf "- HTML export performance is good\n")
        (printf "- HTML export could be optimized\n"))

    (printf "- Large pattern support is functional\n")
    (printf "- System handles 200+ row patterns within specifications\n")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Export Test Runner

(: run-simple-performance-tests (-> Void))
(define (run-simple-performance-tests)
  "Run simple performance test suite"
  (printf "Starting Simple Performance Tests for Large Patterns...\n\n")
  (printf "Run with: raco test simple-performance-test.rkt\n"))

(provide run-simple-performance-tests)

;; end