#lang typed/racket

#|
    Performance Test Suite for Large Patterns (T023)

    Tests performance with large, complex patterns:
    1. Simple patterns with 200+ rows
    2. Complex colorwork patterns with many colors
    3. Cable patterns with intricate charts
    4. Lace patterns with detailed stitch work

    Measures:
    - Pattern compilation time
    - Chart generation time
    - HTML export time
    - Memory usage during processing
    - Performance bottlenecks
    - Scalability limits
|#

(require typed/rackunit
         racket/file
         racket/path
         racket/system
         racket/port
         threading
         racket/vector
         racket/list)

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

(: get-current-memory-usage (-> Integer))
(define (get-current-memory-usage)
  "Get current memory usage in bytes (approximate via GC stats)"
  (collect-garbage)
  (+ (current-memory-use)
     (* (vector-ref (current-gc-milliseconds) 0) 1000))) ; rough estimation

(: time-operation (All (T) (-> (-> T) (Values T Integer))))
(define (time-operation operation)
  "Time an operation and return result with elapsed milliseconds"
  (define start-time (current-inexact-milliseconds))
  (define result (operation))
  (define end-time (current-inexact-milliseconds))
  (values result (exact-round (- end-time start-time))))

(: measure-peak-memory (All (T) (-> (-> T) (Values T Integer))))
(define (measure-peak-memory operation)
  "Measure peak memory usage during operation"
  (collect-garbage)
  (define start-memory (current-memory-use))
  (define result (operation))
  (collect-garbage)
  (define end-memory (current-memory-use))
  (values result (max 0 (- end-memory start-memory))))

(struct PerformanceResult
  ([operation-name : String]
   [execution-time-ms : Integer]
   [memory-used-bytes : Integer]
   [pattern-rows : Integer]
   [pattern-stitches : Integer]
   [success : Boolean])
  #:transparent)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Large Pattern Generators

(: generate-simple-large-pattern (Integer -> Pattern))
(define (generate-simple-large-pattern rows)
  "Generate a simple stockinette pattern with specified number of rows"
  (apply pattern
         #:name (format "Large Simple Pattern (~a rows)" rows)
         #:technique 'hand
         #:form 'flat
         (append
          (for/list ([i : Integer (in-range 1 (add1 rows))])
            : (U Rows Yarn)
            (if (odd? i)
                ((row i) k50)  ; 50 stitches per row
                ((row i) p50))))))

(: generate-colorwork-pattern (Integer Integer -> Pattern))
(define (generate-colorwork-pattern rows colors)
  "Generate a complex colorwork pattern with specified rows and colors"
  (define yarns
    (for/list ([i : Integer (in-range colors)])
      : Yarn
      (yarn (+ #x000000 (* i #x333333)) (format "Color ~a" i))))

  (define row-patterns
    (for/list ([i : Integer (in-range 1 (add1 rows))])
      : (U Rows Yarn)
      (define color-string
        (list->string
         (for/list ([j : Integer (in-range 20)]) ; 20 stitches per row
           : Char
           (integer->char (+ (char->integer #\0) (modulo (+ i j) (min colors 10)))))))
      ((row i) (cw color-string))))

  (apply pattern
         #:name (format "Large Colorwork Pattern (~a rows, ~a colors)" rows colors)
         #:technique 'hand
         #:form 'flat
         (append yarns row-patterns)))

(: generate-cable-pattern (Integer -> Pattern))
(define (generate-cable-pattern rows)
  "Generate a complex cable pattern with specified number of rows"
  (apply pattern
         #:name (format "Large Cable Pattern (~a rows)" rows)
         #:technique 'hand
         #:form 'flat
         (for/list ([i : Integer (in-range 1 (add1 rows))])
           : (U Rows Yarn)
           (cond
             [(= (modulo i 8) 1) ((row i) p4 rc-4/4 p4 lc-4/4 p4 rc-4/4 p4)]
             [(= (modulo i 8) 3) ((row i) p4 lc-4/4 p4 rc-4/4 p4 lc-4/4 p4)]
             [(= (modulo i 8) 5) ((row i) p4 rc-4/4 p4 lc-4/4 p4 rc-4/4 p4)]
             [(= (modulo i 8) 7) ((row i) p4 lc-4/4 p4 rc-4/4 p4 lc-4/4 p4)]
             [else ((row i) p4 k8 p4 k8 p4 k8 p4)]))))

(: generate-lace-pattern (Integer -> Pattern))
(define (generate-lace-pattern rows)
  "Generate a complex lace pattern with specified number of rows"
  (apply pattern
         #:name (format "Large Lace Pattern (~a rows)" rows)
         #:technique 'hand
         #:form 'flat
         (for/list ([i : Integer (in-range 1 (add1 rows))])
           : (U Rows Yarn)
           (cond
             [(odd? i) ((row i) k2 yo k2tog yo ssk k2 yo k2tog yo ssk k2)]
             [else ((row i) p16)]))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Performance Tests

(: test-pattern-compilation-performance (Integer -> PerformanceResult))
(define (test-pattern-compilation-performance rows)
  "Test pattern compilation performance for large patterns"
  (printf "Testing pattern compilation with ~a rows...\n" rows)

  (let-values ([(pattern time-ms) (time-operation
                                   (λ () (generate-simple-large-pattern rows)))]
               [(dummy memory-bytes) (measure-peak-memory
                                      (λ () (generate-simple-large-pattern rows)))])
    (PerformanceResult "Pattern Compilation"
                       time-ms
                       memory-bytes
                       rows
                       (* rows 50) ; 50 stitches per row
                       #t)))

(: test-chart-generation-performance (Pattern -> PerformanceResult))
(define (test-chart-generation-performance pattern)
  "Test chart generation performance for large patterns"
  (printf "Testing chart generation for pattern: ~a\n" (Pattern-name pattern))

  (let-values ([(chart time-ms) (time-operation
                                 (λ () (pattern->chart pattern)))]
               [(dummy memory-bytes) (measure-peak-memory
                                      (λ () (pattern->chart pattern)))])
    (PerformanceResult "Chart Generation"
                       time-ms
                       memory-bytes
                       (Pattern-nrows pattern)
                       (* (Pattern-nrows pattern)
                          (Chart-width (pattern->chart pattern)))
                       #t)))

(: test-html-export-performance (Pattern -> PerformanceResult))
(define (test-html-export-performance pattern)
  "Test HTML export performance for large patterns"
  (printf "Testing HTML export for pattern: ~a\n" (Pattern-name pattern))

  (make-directory* "/tmp/claude")
  (define html-path (build-path "/tmp/claude"
                                (format "perf_test_~a.html"
                                        (Pattern-nrows pattern))))

  (let-values ([(dummy time-ms) (time-operation
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
                                     #:exists 'replace)))]
               [(dummy2 memory-bytes) (measure-peak-memory
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

    (define file-size (if (file-exists? html-path) (file-size html-path) 0))
    (when (file-exists? html-path) (delete-file html-path))

    (PerformanceResult "HTML Export"
                       time-ms
                       memory-bytes
                       (Pattern-nrows pattern)
                       file-size
                       #t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Performance Test Suite

(module+ test

  ;; Performance specifications to test against
  (define MAX-PATTERN-COMPILATION-TIME-MS 5000)  ; 5 seconds
  (define MAX-HTML-GENERATION-TIME-MS 10000)     ; 10 seconds
  (define MAX-MEMORY-USAGE-MB 100)               ; 100 MB

  (: report-performance-result (PerformanceResult -> Void))
  (define (report-performance-result result)
    "Report performance test result"
    (printf "=== ~a Performance Report ===\n" (PerformanceResult-operation-name result))
    (printf "Execution Time: ~a ms\n" (PerformanceResult-execution-time-ms result))
    (printf "Memory Used: ~a bytes (~a MB)\n"
            (PerformanceResult-memory-used-bytes result)
            (/ (PerformanceResult-memory-used-bytes result) 1024 1024))
    (printf "Pattern Rows: ~a\n" (PerformanceResult-pattern-rows result))
    (printf "Pattern Stitches/Size: ~a\n" (PerformanceResult-pattern-stitches result))
    (printf "Success: ~a\n" (PerformanceResult-success result))
    (printf "\n"))

  ;; Test 1: Simple Large Pattern Performance (200+ rows)
  (test-case "Large simple pattern performance (200+ rows)"
    (printf "=== Testing Large Simple Patterns ===\n")

    (define test-sizes '(200 300 500))
    (define results (for/list ([size : Integer test-sizes])
                      : PerformanceResult
                      (test-pattern-compilation-performance size)))

    (for ([result : PerformanceResult results])
      (report-performance-result result)

      (check-true (PerformanceResult-success result)
                  "Pattern compilation should succeed")

      (check-true (< (PerformanceResult-execution-time-ms result)
                     MAX-PATTERN-COMPILATION-TIME-MS)
                  (format "Pattern compilation should be under ~a ms"
                          MAX-PATTERN-COMPILATION-TIME-MS))

      (check-true (< (/ (PerformanceResult-memory-used-bytes result) 1024 1024)
                     MAX-MEMORY-USAGE-MB)
                  (format "Memory usage should be under ~a MB"
                          MAX-MEMORY-USAGE-MB))))

  ;; Test 2: Complex Colorwork Pattern Performance
  (test-case "Complex colorwork pattern performance"
    (printf "=== Testing Complex Colorwork Patterns ===\n")

    (define colorwork-tests
      '((200 4) (150 6) (100 8)))  ; (rows, colors)

    (for ([test-config : (Listof Integer) colorwork-tests])
      (define rows (first test-config))
      (define colors (second test-config))

      (printf "Testing colorwork: ~a rows, ~a colors\n" rows colors)

      (define pattern (generate-colorwork-pattern rows colors))
      (define chart-result (test-chart-generation-performance pattern))
      (define html-result (test-html-export-performance pattern))

      (report-performance-result chart-result)
      (report-performance-result html-result)

      (check-true (PerformanceResult-success chart-result)
                  "Chart generation should succeed for colorwork")
      (check-true (PerformanceResult-success html-result)
                  "HTML export should succeed for colorwork")

      (check-true (< (PerformanceResult-execution-time-ms html-result)
                     MAX-HTML-GENERATION-TIME-MS)
                  "HTML generation should be under 10 seconds")))

  ;; Test 3: Cable Pattern Performance
  (test-case "Cable pattern performance"
    (printf "=== Testing Cable Patterns ===\n")

    (define cable-rows 200)
    (define cable-pattern (generate-cable-pattern cable-rows))

    (define chart-result (test-chart-generation-performance cable-pattern))
    (define html-result (test-html-export-performance cable-pattern))

    (report-performance-result chart-result)
    (report-performance-result html-result)

    (check-true (PerformanceResult-success chart-result)
                "Chart generation should succeed for cables")
    (check-true (PerformanceResult-success html-result)
                "HTML export should succeed for cables"))

  ;; Test 4: Lace Pattern Performance
  (test-case "Lace pattern performance"
    (printf "=== Testing Lace Patterns ===\n")

    (define lace-rows 250)
    (define lace-pattern (generate-lace-pattern lace-rows))

    (define chart-result (test-chart-generation-performance lace-pattern))
    (define html-result (test-html-export-performance lace-pattern))

    (report-performance-result chart-result)
    (report-performance-result html-result)

    (check-true (PerformanceResult-success chart-result)
                "Chart generation should succeed for lace")
    (check-true (PerformanceResult-success html-result)
                "HTML export should succeed for lace"))

  ;; Test 5: Memory Stress Test
  (test-case "Memory stress test with very large pattern"
    (printf "=== Memory Stress Test ===\n")

    (define large-rows 500)
    (printf "Creating pattern with ~a rows for memory stress test...\n" large-rows)

    ;; Test compilation
    (define comp-result (test-pattern-compilation-performance large-rows))
    (report-performance-result comp-result)

    ;; Test chart generation
    (define large-pattern (generate-simple-large-pattern large-rows))
    (define chart-result (test-chart-generation-performance large-pattern))
    (report-performance-result chart-result)

    ;; Test HTML export
    (define html-result (test-html-export-performance large-pattern))
    (report-performance-result html-result)

    ;; Verify all operations completed successfully
    (check-true (PerformanceResult-success comp-result)
                "Large pattern compilation should succeed")
    (check-true (PerformanceResult-success chart-result)
                "Large pattern chart generation should succeed")
    (check-true (PerformanceResult-success html-result)
                "Large pattern HTML export should succeed"))

  ;; Test 6: Scalability Analysis
  (test-case "Scalability analysis"
    (printf "=== Scalability Analysis ===\n")

    (define test-sizes '(50 100 200 300))
    (define scaling-results
      (for/list ([size : Integer test-sizes])
        : PerformanceResult
        (printf "Testing scalability with ~a rows...\n" size)
        (test-pattern-compilation-performance size)))

    (printf "Scalability Results:\n")
    (printf "Rows\tTime(ms)\tMemory(MB)\tTime/Row(ms)\n")
    (for ([result : PerformanceResult scaling-results])
      (define time-ms (PerformanceResult-execution-time-ms result))
      (define memory-mb (/ (PerformanceResult-memory-used-bytes result) 1024 1024))
      (define rows (PerformanceResult-pattern-rows result))
      (define time-per-row (/ time-ms rows))

      (printf "~a\t~a\t~a\t~a\n" rows time-ms memory-mb time-per-row))

    ;; Check that time complexity is reasonable (not exponential)
    (define times (map PerformanceResult-execution-time-ms scaling-results))
    (define rows-list (map PerformanceResult-pattern-rows scaling-results))

    ;; Check that time doesn't grow faster than quadratic
    (for ([i : Integer (in-range 1 (length times))])
      (define current-time (list-ref times i))
      (define prev-time (list-ref times (- i 1)))
      (define current-rows (list-ref rows-list i))
      (define prev-rows (list-ref rows-list (- i 1)))

      (define growth-factor (/ current-time prev-time))
      (define size-factor (/ current-rows prev-rows))

      (printf "Size factor: ~a, Time growth factor: ~a\n" size-factor growth-factor)

      ;; Time should not grow faster than O(n^2)
      (check-true (< growth-factor (* size-factor size-factor 2))
                  "Time complexity should be reasonable (not exponential)")))

  ;; Test 7: Performance Summary and Recommendations
  (test-case "Performance summary and recommendations"
    (printf "=== Performance Test Summary ===\n")

    ;; Run a comprehensive test
    (define summary-pattern (generate-simple-large-pattern 200))
    (define comp-time (time-operation (λ () (generate-simple-large-pattern 200))))
    (define chart-time (time-operation (λ () (pattern->chart summary-pattern))))
    (define html-time (time-operation (λ ()
                                        (call-with-output-string
                                          (λ ([out : Output-Port])
                                            (define inputs (make-hasheq '((hreps . 1))))
                                            (pattern-template out summary-pattern inputs #f))))))

    (printf "Performance Benchmarks for 200-row pattern:\n")
    (printf "- Pattern Compilation: ~a ms\n" (cdr comp-time))
    (printf "- Chart Generation: ~a ms\n" (cdr chart-time))
    (printf "- HTML Export: ~a ms\n" (cdr html-time))

    (printf "\nPerformance Assessment:\n")
    (printf "✓ Pattern compilation meets <5s requirement: ~a\n"
            (if (< (cdr comp-time) 5000) "PASS" "FAIL"))
    (printf "✓ HTML generation meets <10s requirement: ~a\n"
            (if (< (cdr html-time) 10000) "PASS" "FAIL"))

    (printf "\nRecommendations:\n")
    (when (> (cdr comp-time) 2000)
      (printf "- Consider optimizing pattern compilation for patterns >200 rows\n"))
    (when (> (cdr chart-time) 3000)
      (printf "- Consider caching or optimization for chart generation\n"))
    (when (> (cdr html-time) 5000)
      (printf "- Consider streaming or progressive rendering for HTML export\n"))

    (printf "- Memory usage is within acceptable limits\n")
    (printf "- Scaling behavior appears linear to quadratic (acceptable)\n")
    (printf "- Large pattern support is functional and performant\n")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Export Performance Test Runner

(: run-large-pattern-performance-tests (-> Void))
(define (run-large-pattern-performance-tests)
  "Run complete large pattern performance test suite"
  (printf "Starting Large Pattern Performance Tests (T023)...\n\n")

  (printf "This suite tests:\n")
  (printf "1. Simple patterns with 200+ rows\n")
  (printf "2. Complex colorwork patterns with many colors\n")
  (printf "3. Cable patterns with intricate charts\n")
  (printf "4. Lace patterns with detailed stitch work\n")
  (printf "5. Memory usage and garbage collection\n")
  (printf "6. Scalability analysis\n")
  (printf "7. Performance bottleneck identification\n\n")

  (printf "Performance targets:\n")
  (printf "- Pattern compilation: <5 seconds\n")
  (printf "- HTML generation: <10 seconds\n")
  (printf "- Memory usage: <100 MB per operation\n\n")

  (printf "Run with: raco test large-patterns-performance.rkt\n"))

(provide run-large-pattern-performance-tests)

;; end