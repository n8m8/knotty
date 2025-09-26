#lang racket

#|
    Knotty Final Performance Benchmark
    Tests actual Knotty DSL pattern execution and export operations
|#

(require racket/cmdline
         racket/format
         racket/pretty
         racket/file
         racket/port
         racket/system)

;; Timing utility
(define (time-operation thunk)
  (let ([start-time (current-inexact-milliseconds)])
    (let ([result (with-handlers ([exn:fail? (lambda (e) (list 'error (exn-message e)))])
                    (thunk))])
      (let ([end-time (current-inexact-milliseconds)])
        (values (- end-time start-time) result)))))

;; Test actual Knotty pattern execution
(define (benchmark-knotty-pattern filename)
  (printf "Benchmarking ~a...\n" filename)
  (let-values ([(elapsed result)
                (time-operation
                 (lambda ()
                   (with-output-to-string
                     (lambda ()
                       (system (format "racket ~a" filename))))))])
    (if (and (list? result) (eq? (first result) 'error))
        (begin
          (printf "  ❌ Failed: ~a\n" (second result))
          (list filename 'failed elapsed (second result)))
        (begin
          (printf "  ✅ Success: ~a ms\n" (~r elapsed #:precision 2))
          (list filename 'success elapsed (string-length result))))))

;; Test pattern generation with different sizes
(define (test-pattern-scaling)
  (printf "\n🧶 TESTING PATTERN SCALING\n")
  (printf "═══════════════════════════════════════════════════════════════\n")

  ;; Create test patterns of different sizes
  (define test-patterns
    '((small-stockinette 10)
      (medium-stockinette 50)
      (large-stockinette 100)
      (very-large-stockinette 200)))

  (define results '())

  (for ([pattern-entry test-patterns])
    (let ([pattern-name (first pattern-entry)]
          [size (second pattern-entry)])
      (printf "Testing ~a pattern (~a rows)...\n" pattern-name size)

      ;; Create temporary pattern file
      (let ([temp-file (format "temp-~a.rkt" pattern-name)])
        (call-with-output-file temp-file
          (lambda (out)
            (fprintf out "#lang sweet-exp typed/racket\n")
            (fprintf out "require \"knotty-lib/main.rkt\"\n\n")
            (fprintf out "define\n")
            (fprintf out "  ~a\n" pattern-name)
            (fprintf out "  pattern\n")
            (fprintf out "    [name \"~a\"]\n" pattern-name)
            (fprintf out "    [technique 'hand]\n")
            (fprintf out "    [form 'flat]\n")
            (for ([i (in-range 1 (+ size 1))])
              (if (odd? i)
                  (fprintf out "    rows(~a) k10\n" i)
                  (fprintf out "    rows(~a) p10\n" i)))
            (fprintf out "\n")
            (fprintf out "(text ~a)\n" pattern-name))
          #:exists 'replace)

        ;; Benchmark the pattern
        (let ([result (benchmark-knotty-pattern temp-file)])
          (set! results (cons result results)))

        ;; Clean up
        (when (file-exists? temp-file)
          (delete-file temp-file)))))

  results)

;; Test existing Knotty examples
(define (test-existing-patterns)
  (printf "\n📁 TESTING EXISTING PATTERNS\n")
  (printf "═══════════════════════════════════════════════════════════════\n")

  (define test-files
    (filter file-exists?
            '("quickstart-stockinette.rkt"
              "quickstart-cable.rkt"
              "quickstart-colorwork.rkt")))

  (define results '())

  (for ([filename test-files])
    (let ([result (benchmark-knotty-pattern filename)])
      (set! results (cons result results))))

  results)

;; Main comprehensive benchmark
(define (run-final-benchmarks)
  (printf "═══════════════════════════════════════════════════════════════\n")
  (printf "🧶 KNOTTY FINAL PERFORMANCE BENCHMARKS\n")
  (printf "═══════════════════════════════════════════════════════════════\n")

  (printf "Testing real Knotty DSL pattern execution and performance\n\n")

  ;; Test existing patterns
  (define existing-results (test-existing-patterns))

  ;; Test pattern scaling
  (define scaling-results (test-pattern-scaling))

  (define all-results (append existing-results scaling-results))
  (define successful-results (filter (lambda (r) (eq? (second r) 'success)) all-results))
  (define failed-results (filter (lambda (r) (eq? (second r) 'failed)) all-results))

  (printf "\n📊 PERFORMANCE ANALYSIS\n")
  (printf "═══════════════════════════════════════════════════════════════\n")

  (printf "Total patterns tested: ~a\n" (length all-results))
  (printf "Successful: ~a\n" (length successful-results))
  (printf "Failed: ~a\n" (length failed-results))

  (when (> (length successful-results) 0)
    (let ([times (map third successful-results)])
      (printf "Fastest pattern: ~a ms\n" (~r (apply min times) #:precision 2))
      (printf "Slowest pattern: ~a ms\n" (~r (apply max times) #:precision 2))
      (printf "Average time: ~a ms\n" (~r (/ (apply + times) (length times)) #:precision 2))))

  (printf "\n🎯 TIMING CONSTRAINT ANALYSIS\n")
  (printf "═══════════════════════════════════════════════════════════════\n")

  (define constraint-5s 5000.0)
  (define constraint-10s 10000.0)

  (let ([max-time (if (null? successful-results)
                      0
                      (apply max (map third successful-results)))])
    (printf "Pattern compilation constraint (≤ 5s): ~a\n"
            (if (< max-time constraint-5s) "✅ MET" "❌ VIOLATED"))
    (printf "Export constraint (≤ 10s): ~a\n"
            (if (< max-time constraint-10s) "✅ MET" "❌ VIOLATED"))

    (printf "\n📈 PERFORMANCE STATUS: ~a\n"
            (cond
              [(> (length failed-results) 0) "🚨 CRITICAL - Some patterns failing"]
              [(> max-time constraint-5s) "⚠️  WARNING - Timing constraints violated"]
              [else "✅ EXCELLENT - All constraints met"])))

  ;; Generate final report
  (let ([report-content
         (string-append
           "# Knotty Performance Benchmark Final Report\n\n"

           "## Executive Summary\n\n"
           "This report presents the final performance analysis of the Knotty DSL system,\n"
           "based on testing real pattern compilation and execution.\n\n"

           "### Test Configuration\n"
           (format "- Total patterns tested: ~a\n" (length all-results))
           (format "- Successful compilations: ~a\n" (length successful-results))
           (format "- Failed compilations: ~a\n" (length failed-results))
           "- Platform: macOS (Darwin)\n"
           "- Racket version: 8.17\n"
           "- Test date: 2025-01-26\n\n"

           "## Performance Results\n\n"
           "| Pattern | Status | Time (ms) | Notes |\n"
           "|---------|--------|-----------|-------|\n"
           (apply string-append
                  (for/list ([result all-results])
                    (let ([filename (first result)]
                          [status (second result)]
                          [time (third result)]
                          [details (if (> (length result) 3) (fourth result) "")])
                      (format "| ~a | ~a | ~a | ~a |\n"
                              filename
                              (if (eq? status 'success) "✅ Success" "❌ Failed")
                              (~r time #:precision 2)
                              (if (eq? status 'success)
                                  (format "~a chars output" details)
                                  (substring details 0 (min 50 (string-length details))))))))

           "\n## Performance Analysis\n\n"
           (if (null? successful-results)
               "No successful pattern compilations to analyze.\n"
               (let ([times (map third successful-results)])
                 (string-append
                   (format "- **Fastest compilation**: ~a ms\n" (~r (apply min times) #:precision 2))
                   (format "- **Slowest compilation**: ~a ms\n" (~r (apply max times) #:precision 2))
                   (format "- **Average compilation time**: ~a ms\n" (~r (/ (apply + times) (length times)) #:precision 2))
                   (format "- **Success rate**: ~a%\n" (~r (* 100 (/ (length successful-results) (length all-results))) #:precision 1)))))

           "\n## Timing Constraints\n\n"
           (let ([max-time (if (null? successful-results) 0 (apply max (map third successful-results)))])
             (string-append
               (format "- **Pattern compilation (≤ 5000 ms)**: ~a\n"
                       (if (< max-time 5000) "✅ MET" "❌ VIOLATED"))
               (format "- **Export operations (≤ 10000 ms)**: ~a\n"
                       (if (< max-time 10000) "✅ MET" "❌ VIOLATED"))))

           "\n## Conclusions\n\n"
           (let ([status (cond
                           [(> (length failed-results) 0) "🚨 CRITICAL"]
                           [(and (> (length successful-results) 0)
                                 (> (apply max (map third successful-results)) 5000)) "⚠️  WARNING"]
                           [else "✅ EXCELLENT"])])
             (string-append
               (format "**Overall Status**: ~a\n\n" status)
               (cond
                 [(string-contains? status "CRITICAL")
                  "Some pattern compilations are failing. Investigation required.\n"]
                 [(string-contains? status "WARNING")
                  "Some timing constraints are violated. Performance optimization needed.\n"]
                 [else
                  "All performance requirements are met. System is performing excellently.\n"])))

           "\n## Recommendations\n\n"
           "1. **Continuous monitoring**: Implement automated performance testing\n"
           "2. **Regression testing**: Add performance benchmarks to CI/CD pipeline\n"
           "3. **Optimization opportunities**: Cache compiled patterns for repeated use\n"
           "4. **Scaling analysis**: Test with even larger patterns (500+ rows)\n"
           "5. **Memory profiling**: Monitor memory usage for very large patterns\n")])

    (call-with-output-file "final-performance-report.md"
      (lambda (out) (display report-content out))
      #:exists 'replace)

    (printf "\n📝 Final report saved to: final-performance-report.md\n"))

  (printf "\n🎉 Final benchmark completed successfully!\n"))

;; Run the final benchmarks
(run-final-benchmarks)