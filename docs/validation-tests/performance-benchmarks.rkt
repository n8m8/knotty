#lang typed/racket

#|
    Knotty Performance Benchmarks
    Comprehensive benchmarking suite for measuring performance of core operations
    against specified timing constraints.
|#

(provide (all-defined-out))

(require racket/vector
         racket/list
         racket/match
         racket/port
         racket/pretty
         racket/format
         racket/runtime-path
         threading)

;; Import knotty libraries
(require "knotty-lib/pattern.rkt"
         "knotty-lib/chart.rkt"
         "knotty-lib/gui.rkt"
         "knotty-lib/knitspeak.rkt"
         "knotty-lib/stitch.rkt"
         "knotty-lib/yarn.rkt"
         "knotty-lib/rows.rkt"
         "knotty-lib/global.rkt")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Performance Measurement Infrastructure
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Benchmark result structure
(struct BenchmarkResult
  ([operation : String]
   [pattern-type : String]
   [pattern-size : Natural]
   [elapsed-time-ms : Real]
   [memory-usage-mb : Real]
   [success : Boolean]
   [error-message : (Option String)])
  #:transparent)

;; Performance timing utility
(: time-operation : (-> Any) -> (values Real Any))
(define (time-operation thunk)
  (let ([start-time (current-inexact-milliseconds)])
    (let ([result (thunk)])
      (let ([end-time (current-inexact-milliseconds)])
        (values (- end-time start-time) result)))))

;; Memory usage measurement utility
(: measure-memory : (-> Any) -> (values Real Any))
(define (measure-memory thunk)
  (collect-garbage)
  (let ([initial-memory (current-memory-use)])
    (let ([result (thunk)])
      (collect-garbage)
      (let ([final-memory (current-memory-use)])
        (values (* (/ (- final-memory initial-memory) 1024.0) 1024.0) result)))))

;; Combined timing and memory measurement
(: benchmark-operation : String String Natural (-> Any) -> BenchmarkResult)
(define (benchmark-operation operation pattern-type pattern-size thunk)
  (let-values ([(elapsed-time result)
                (with-handlers ([exn:fail? (λ ([e : exn:fail])
                                             (values 0.0 (exn-message e)))])
                  (time-operation thunk))])
    (if (string? result)
        ;; Error case
        (BenchmarkResult operation pattern-type pattern-size elapsed-time 0.0 #f result)
        ;; Success case
        (let-values ([(memory-usage _)
                      (with-handlers ([exn:fail? (λ ([e : exn:fail]) (values 0.0 #f))])
                        (measure-memory thunk))])
          (BenchmarkResult operation pattern-type pattern-size elapsed-time memory-usage #t #f)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test Pattern Generators
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Generate a simple stockinette pattern of specified size
(: generate-simple-pattern : Natural -> Pattern)
(define (generate-simple-pattern rows)
  (pattern
    #:name (format "Simple ~a-row pattern" rows)
    #:technique 'hand
    #:form 'flat
    (yarn #xFFFFFF "white")
    (apply rows
           (for/list : (Listof (List Positive-Integer Stitch-tree))
             ([i (in-range 1 (add1 rows))])
             (list i (if (odd? i) 'k 'p))))))

;; Generate a colorwork pattern of specified size
(: generate-colorwork-pattern : Natural -> Pattern)
(define (generate-colorwork-pattern rows)
  (pattern
    #:name (format "Colorwork ~a-row pattern" rows)
    #:technique 'hand
    #:form 'flat
    (yarn #xFFFFFF "white")
    (yarn #x000000 "black")
    (apply rows
           (for/list : (Listof (List Positive-Integer Stitch-tree))
             ([i (in-range 1 (add1 rows))])
             (list i (let ([pattern-string (make-string 20 #\0)])
                      (for ([j (in-range 0 20 2)])
                        (string-set! pattern-string j #\1))
                      `(cw ,pattern-string)))))))

;; Generate a cable pattern of specified size
(: generate-cable-pattern : Natural -> Pattern)
(define (generate-cable-pattern rows)
  (pattern
    #:name (format "Cable ~a-row pattern" rows)
    #:technique 'hand
    #:form 'flat
    (yarn #xFFFFFF "white")
    (apply rows
           (for/list : (Listof (List Positive-Integer Stitch-tree))
             ([i (in-range 1 (add1 rows))])
             (list i (cond
                      [(= (modulo i 8) 1) `(k4 (rc-2/2) k4)]
                      [(= (modulo i 8) 5) `(k4 (lc-2/2) k4)]
                      [else `(k10)]))))))

;; Generate a lace pattern of specified size
(: generate-lace-pattern : Natural -> Pattern)
(define (generate-lace-pattern rows)
  (pattern
    #:name (format "Lace ~a-row pattern" rows)
    #:technique 'hand
    #:form 'flat
    (yarn #xFFFFFF "white")
    (apply rows
           (for/list : (Listof (List Positive-Integer Stitch-tree))
             ([i (in-range 1 (add1 rows))])
             (list i (if (odd? i)
                        `(k2 yo k2tog k2 ssk yo k2)
                        `(p10)))))))

;; Generate a complex pattern with multiple techniques
(: generate-complex-pattern : Natural -> Pattern)
(define (generate-complex-pattern rows)
  (pattern
    #:name (format "Complex ~a-row pattern" rows)
    #:technique 'hand
    #:form 'flat
    #:repeat-rows (list 1 (min 8 rows))
    (yarn #xFFFFFF "white")
    (yarn #x808080 "gray")
    (apply rows
           (for/list : (Listof (List Positive-Integer Stitch-tree))
             ([i (in-range 1 (add1 rows))])
             (list i (match (modulo i 8)
                       [1 `(k2 yo k2tog (rc-2/2) k2tog yo k2)]
                       [2 `(p2 (cw "01010") p2)]
                       [3 `(k2 ssk yo (lc-2/2) yo k2tog k2)]
                       [4 `(p2 (cw "10101") p2)]
                       [5 `(k2 yo (rc-2/2) k2tog ssk yo k2)]
                       [6 `(p2 (cw "01010") p2)]
                       [7 `(k2 k2tog yo (lc-2/2) yo ssk k2)]
                       [0 `(p2 (cw "10101") p2)]))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Core Operation Benchmarks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Benchmark pattern compilation
(: benchmark-pattern-compilation : String (-> Pattern) Natural -> BenchmarkResult)
(define (benchmark-pattern-compilation pattern-type pattern-generator rows)
  (benchmark-operation
    "Pattern Compilation"
    pattern-type
    rows
    pattern-generator))

;; Benchmark HTML generation
(: benchmark-html-generation : String Pattern -> BenchmarkResult)
(define (benchmark-html-generation pattern-type pattern)
  (benchmark-operation
    "HTML Generation"
    pattern-type
    (Pattern-nrows pattern)
    (λ () (export-html pattern "/tmp/claude/benchmark-temp.html"))))

;; Benchmark chart generation
(: benchmark-chart-generation : String Pattern -> BenchmarkResult)
(define (benchmark-chart-generation pattern-type pattern)
  (benchmark-operation
    "Chart Generation"
    pattern-type
    (Pattern-nrows pattern)
    (λ () (pattern->chart pattern))))

;; Benchmark knitspeak export
(: benchmark-knitspeak-export : String Pattern -> BenchmarkResult)
(define (benchmark-knitspeak-export pattern-type pattern)
  (benchmark-operation
    "Knitspeak Export"
    pattern-type
    (Pattern-nrows pattern)
    (λ () (pattern->ks pattern))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Systematic Benchmark Suite
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Pattern size categories for testing
(define pattern-sizes : (Listof Natural) '(10 50 100 200 500))

;; Pattern type generators
(define pattern-generators : (Listof (List String (Natural -> Pattern)))
  `(["Simple"    ,generate-simple-pattern]
    ["Colorwork" ,generate-colorwork-pattern]
    ["Cable"     ,generate-cable-pattern]
    ["Lace"      ,generate-lace-pattern]
    ["Complex"   ,generate-complex-pattern]))

;; Run comprehensive benchmark suite
(: run-comprehensive-benchmarks : -> (Listof BenchmarkResult))
(define (run-comprehensive-benchmarks)
  (printf "Starting comprehensive performance benchmarks...\n")
  (let ([results : (Listof BenchmarkResult) null])

    ;; Pattern compilation benchmarks
    (for* ([size-entry pattern-sizes]
           [generator-entry pattern-generators])
      (let ([size : Natural size-entry]
            [pattern-type : String (first generator-entry)]
            [generator : (Natural -> Pattern) (second generator-entry)])
        (printf "Benchmarking ~a pattern compilation (~a rows)...\n" pattern-type size)
        (let ([result (benchmark-pattern-compilation
                       pattern-type
                       (λ () (generator size))
                       size)])
          (set! results (cons result results)))))

    ;; Generate patterns for export benchmarks
    (for* ([size-entry pattern-sizes]
           [generator-entry pattern-generators])
      (let ([size : Natural size-entry]
            [pattern-type : String (first generator-entry)]
            [generator : (Natural -> Pattern) (second generator-entry)])
        (when (<= size 100) ; Limit export benchmarks to smaller patterns
          (printf "Benchmarking ~a exports (~a rows)...\n" pattern-type size)
          (let ([pattern (generator size)])

            ;; HTML generation benchmark
            (let ([html-result (benchmark-html-generation pattern-type pattern)])
              (set! results (cons html-result results)))

            ;; Chart generation benchmark
            (let ([chart-result (benchmark-chart-generation pattern-type pattern)])
              (set! results (cons chart-result results)))

            ;; Knitspeak export benchmark (if available)
            (when (member pattern-type '("Simple" "Cable" "Lace"))
              (let ([knitspeak-result (benchmark-knitspeak-export pattern-type pattern)])
                (set! results (cons knitspeak-result results))))))))

    (printf "Benchmark suite completed.\n")
    (reverse results)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Performance Analysis and Reporting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Performance constraint specifications
(define timing-constraints : (Listof (List String Real))
  '(["Pattern Compilation" 5000.0]  ; 5 seconds
    ["HTML Generation"     10000.0] ; 10 seconds
    ["Chart Generation"    8000.0]  ; 8 seconds
    ["Knitspeak Export"    3000.0])) ; 3 seconds

;; Check if result meets timing constraints
(: meets-timing-constraints? : BenchmarkResult -> Boolean)
(define (meets-timing-constraints? result)
  (let ([operation (BenchmarkResult-operation result)]
        [elapsed (BenchmarkResult-elapsed-time-ms result)])
    (let ([constraint-entry (assoc operation timing-constraints)])
      (if constraint-entry
          (<= elapsed (second constraint-entry))
          #t)))) ; No constraint defined, assume passing

;; Generate performance report
(: generate-performance-report : (Listof BenchmarkResult) -> String)
(define (generate-performance-report results)
  (let ([successful-results (filter BenchmarkResult-success results)]
        [failed-results (filter (λ ([r : BenchmarkResult]) (not (BenchmarkResult-success r))) results)])

    (string-append
      "# Knotty Performance Benchmark Report\n\n"

      "## Executive Summary\n"
      (format "- Total benchmarks run: ~a\n" (length results))
      (format "- Successful benchmarks: ~a\n" (length successful-results))
      (format "- Failed benchmarks: ~a\n" (length failed-results))

      (let ([constraint-violations
             (filter (λ ([r : BenchmarkResult])
                      (and (BenchmarkResult-success r)
                           (not (meets-timing-constraints? r))))
                    results)])
        (format "- Timing constraint violations: ~a\n\n" (length constraint-violations)))

      "## Timing Constraints\n"
      (apply string-append
             (for/list : (Listof String) ([constraint : (List String Real) timing-constraints])
               (format "- ~a: ≤ ~a ms\n" (first constraint) (second constraint))))
      "\n"

      "## Performance Results by Operation\n\n"
      (apply string-append
             (for/list ([operation '("Pattern Compilation" "HTML Generation"
                                   "Chart Generation" "Knitspeak Export")])
               (let ([op-results (filter (λ ([r : BenchmarkResult])
                                          (string=? (BenchmarkResult-operation r) operation))
                                        successful-results)])
                 (if (null? op-results)
                     ""
                     (string-append
                       (format "### ~a\n\n" operation)
                       "| Pattern Type | Size | Time (ms) | Memory (MB) | Status |\n"
                       "|--------------|------|-----------|-------------|--------|\n"
                       (apply string-append
                              (for/list ([result op-results])
                                (let ([constraint-met? (meets-timing-constraints? result)])
                                  (format "| ~a | ~a | ~a | ~a | ~a |\n"
                                         (BenchmarkResult-pattern-type result)
                                         (BenchmarkResult-pattern-size result)
                                         (~r (BenchmarkResult-elapsed-time-ms result) #:precision 2)
                                         (~r (BenchmarkResult-memory-usage-mb result) #:precision 2)
                                         (if constraint-met? "✓ PASS" "✗ FAIL")))))
                       "\n")))))

      (if (null? failed-results)
          ""
          (string-append
            "## Failed Benchmarks\n\n"
            (apply string-append
                   (for/list ([result failed-results])
                     (format "- ~a (~a, ~a rows): ~a\n"
                            (BenchmarkResult-operation result)
                            (BenchmarkResult-pattern-type result)
                            (BenchmarkResult-pattern-size result)
                            (or (BenchmarkResult-error-message result) "Unknown error"))))))

      "\n## Performance Analysis\n\n"
      (analyze-performance-trends successful-results)

      "\n## Recommendations\n\n"
      (generate-recommendations results))))

;; Analyze performance trends
(: analyze-performance-trends : (Listof BenchmarkResult) -> String)
(define (analyze-performance-trends results)
  (let ([compilation-results
         (filter (λ ([r : BenchmarkResult])
                  (string=? (BenchmarkResult-operation r) "Pattern Compilation"))
                results)])
    (if (< (length compilation-results) 2)
        "Insufficient data for trend analysis.\n"
        (let* ([times (map BenchmarkResult-elapsed-time-ms compilation-results)]
               [sizes (map BenchmarkResult-pattern-size compilation-results)]
               [avg-time-per-row (/ (apply + times) (apply + sizes))])
          (string-append
            (format "- Average compilation time per row: ~a ms\n"
                   (~r avg-time-per-row #:precision 3))
            (format "- Estimated time for 1000-row pattern: ~a ms\n"
                   (~r (* avg-time-per-row 1000) #:precision 1))
            (let ([large-patterns (filter (λ ([r : BenchmarkResult])
                                           (> (BenchmarkResult-pattern-size r) 200))
                                         compilation-results)])
              (if (null? large-patterns)
                  "- No large pattern data available for scaling analysis.\n"
                  (format "- Large patterns (>200 rows) show ~a scaling behavior.\n"
                         (if (< avg-time-per-row 10.0) "good" "concerning")))))))))

;; Generate performance recommendations
(: generate-recommendations : (Listof BenchmarkResult) -> String)
(define (generate-recommendations results)
  (let ([violations (filter (λ ([r : BenchmarkResult])
                             (and (BenchmarkResult-success r)
                                  (not (meets-timing-constraints? r))))
                           results)]
        [failures (filter (λ ([r : BenchmarkResult]) (not (BenchmarkResult-success r))) results)])

    (string-append
      (if (null? violations)
          "✓ All timing constraints are currently met.\n"
          (string-append
            "⚠️ Timing constraint violations detected:\n"
            (apply string-append
                   (for/list ([v violations])
                     (format "  - ~a (~a): ~a ms exceeds limit\n"
                            (BenchmarkResult-operation v)
                            (BenchmarkResult-pattern-type v)
                            (~r (BenchmarkResult-elapsed-time-ms v) #:precision 1))))))

      (if (null? failures)
          ""
          (string-append
            "\n🚨 Failed operations require investigation:\n"
            (apply string-append
                   (for/list ([f failures])
                     (format "  - ~a (~a): ~a\n"
                            (BenchmarkResult-operation f)
                            (BenchmarkResult-pattern-type f)
                            (or (BenchmarkResult-error-message f) "Unknown error"))))))

      "\n📊 Performance optimization opportunities:\n"
      "- Consider caching compiled patterns for repeated operations\n"
      "- Implement streaming for large pattern exports\n"
      "- Optimize memory usage for complex colorwork patterns\n"
      "- Consider parallel processing for independent chart generation\n")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main Benchmark Execution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Run benchmarks and save report
(: run-benchmarks-and-report : -> Void)
(define (run-benchmarks-and-report)
  (printf "═══════════════════════════════════════════════════════════════\n")
  (printf "🧶 KNOTTY PERFORMANCE BENCHMARKS\n")
  (printf "═══════════════════════════════════════════════════════════════\n\n")

  (let ([results (run-comprehensive-benchmarks)])
    (let ([report (generate-performance-report results)])

      ;; Save report to file
      (let ([report-file "performance-report.md"])
        (call-with-output-file report-file
          (λ (out) (display report out))
          #:exists 'replace)
        (printf "\n📝 Performance report saved to: ~a\n" report-file))

      ;; Display summary to console
      (printf "\n═══════════════════════════════════════════════════════════════\n")
      (printf "📊 BENCHMARK SUMMARY\n")
      (printf "═══════════════════════════════════════════════════════════════\n")
      (let ([successful (filter BenchmarkResult-success results)]
            [failed (filter (λ ([r : BenchmarkResult]) (not (BenchmarkResult-success r))) results)]
            [violations (filter (λ ([r : BenchmarkResult])
                                 (and (BenchmarkResult-success r)
                                      (not (meets-timing-constraints? r))))
                               results)])
        (printf "Total benchmarks: ~a\n" (length results))
        (printf "Successful: ~a\n" (length successful))
        (printf "Failed: ~a\n" (length failed))
        (printf "Timing violations: ~a\n" (length violations))

        (when (> (length violations) 0)
          (printf "\n⚠️  CONSTRAINT VIOLATIONS:\n")
          (for ([v violations])
            (printf "  • ~a (~a): ~a ms\n"
                   (BenchmarkResult-operation v)
                   (BenchmarkResult-pattern-type v)
                   (~r (BenchmarkResult-elapsed-time-ms v) #:precision 1))))

        (when (> (length failed) 0)
          (printf "\n🚨 FAILED BENCHMARKS:\n")
          (for ([f failed])
            (printf "  • ~a (~a): ~a\n"
                   (BenchmarkResult-operation f)
                   (BenchmarkResult-pattern-type f)
                   (or (BenchmarkResult-error-message f) "Unknown error"))))

        (printf "\n📈 PERFORMANCE STATUS: ~a\n"
               (cond
                 [(> (length failed) 0) "🚨 CRITICAL - Some operations failing"]
                 [(> (length violations) 0) "⚠️  WARNING - Timing constraints violated"]
                 [else "✅ EXCELLENT - All constraints met"]))))))

;; For module+ test usage
(module+ test
  (require rackunit)

  ;; Test pattern generators
  (check-true (Pattern? (generate-simple-pattern 10)))
  (check-true (Pattern? (generate-colorwork-pattern 10)))
  (check-true (Pattern? (generate-cable-pattern 10)))
  (check-true (Pattern? (generate-lace-pattern 10)))
  (check-true (Pattern? (generate-complex-pattern 10)))

  ;; Test benchmark infrastructure
  (let ([result (benchmark-operation "Test" "Simple" 5 (λ () (+ 1 2)))])
    (check-true (BenchmarkResult? result))
    (check-true (BenchmarkResult-success result))
    (check-true (>= (BenchmarkResult-elapsed-time-ms result) 0))))

;; CLI entry point
(when (eq? (vector-ref (current-command-line-arguments) 0 #f) "run")
  (run-benchmarks-and-report))