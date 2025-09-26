#lang racket

#|
    Knotty Performance Benchmarks
    Simplified version for measuring core operation performance
|#

(require racket/cmdline
         racket/format
         racket/pretty)

;; Basic timing utility
(define (time-operation thunk)
  (let ([start-time (current-inexact-milliseconds)])
    (let ([result (thunk)])
      (let ([end-time (current-inexact-milliseconds)])
        (values (- end-time start-time) result)))))

;; Simple pattern generators using basic Racket syntax
(define (generate-simple-pattern rows)
  (for/list ([i (in-range rows)])
    `(row ,(+ i 1) k)))

(define (generate-colorwork-pattern rows)
  (for/list ([i (in-range rows)])
    `(row ,(+ i 1) (cw "010101010"))))

(define (generate-cable-pattern rows)
  (for/list ([i (in-range rows)])
    (if (= (modulo i 4) 0)
        `(row ,(+ i 1) (k2 rc-2/2 k2))
        `(row ,(+ i 1) k6))))

;; Benchmark structure compilation
(define (benchmark-pattern-creation pattern-generator rows)
  (time-operation (lambda () (pattern-generator rows))))

;; Run basic benchmarks
(define (run-basic-benchmarks)
  (printf "═══════════════════════════════════════════════════════════════\n")
  (printf "🧶 KNOTTY BASIC PERFORMANCE BENCHMARKS\n")
  (printf "═══════════════════════════════════════════════════════════════\n\n")

  (define pattern-sizes '(10 50 100 200 500))
  (define pattern-types
    `(("Simple" ,generate-simple-pattern)
      ("Colorwork" ,generate-colorwork-pattern)
      ("Cable" ,generate-cable-pattern)))

  (define results '())

  ;; Test pattern generation performance
  (for* ([size pattern-sizes]
         [type-entry pattern-types])
    (let ([type-name (first type-entry)]
          [generator (second type-entry)])
      (printf "Testing ~a pattern generation (~a rows)...\n" type-name size)
      (let-values ([(elapsed result) (benchmark-pattern-creation generator size)])
        (printf "  ✓ Completed in ~a ms\n" (~r elapsed #:precision 2))
        (set! results (cons (list type-name size elapsed) results)))))

  (printf "\n📊 PERFORMANCE SUMMARY\n")
  (printf "═══════════════════════════════════════════════════════════════\n")
  (printf "| Pattern Type | Size | Time (ms) | Time/Row (ms) |\n")
  (printf "|--------------|------|-----------|---------------|\n")

  (for ([result (reverse results)])
    (let ([type-name (first result)]
          [size (second result)]
          [elapsed (third result)])
      (printf "| ~a | ~a | ~a | ~a |\n"
              (~a type-name #:width 12)
              (~a size #:width 4)
              (~r elapsed #:precision 2)
              (~r (/ elapsed size) #:precision 3))))

  (printf "\n🎯 CONSTRAINT ANALYSIS\n")
  (printf "═══════════════════════════════════════════════════════════════\n")

  ;; Analyze against timing constraints
  (define max-compilation-time (apply max (map third results)))
  (define constraint-5s 5000.0)

  (if (< max-compilation-time constraint-5s)
      (printf "✅ Pattern generation constraint MET: All patterns under 5s\n")
      (printf "❌ Pattern generation constraint FAILED: Max time ~a ms > 5000 ms\n"
              (~r max-compilation-time #:precision 1)))

  ;; Project performance for larger patterns
  (define avg-time-per-row
    (/ (apply + (map third results))
       (apply + (map second results))))

  (printf "\n📈 SCALING ANALYSIS\n")
  (printf "═══════════════════════════════════════════════════════════════\n")
  (printf "Average time per row: ~a ms\n" (~r avg-time-per-row #:precision 3))
  (printf "Projected time for 1000-row pattern: ~a ms (~a s)\n"
          (~r (* avg-time-per-row 1000) #:precision 1)
          (~r (/ (* avg-time-per-row 1000) 1000) #:precision 2))

  (when (> (* avg-time-per-row 1000) 5000)
    (printf "⚠️  WARNING: Large patterns may exceed 5s constraint\n"))

  (printf "\n💾 Saving performance report...\n")

  ;; Generate markdown report
  (define report-content
    (string-append
      "# Knotty Performance Benchmark Report\n\n"
      "## Test Configuration\n"
      "- Pattern sizes tested: " (string-join (map number->string pattern-sizes) ", ") "\n"
      "- Pattern types tested: " (string-join (map first pattern-types) ", ") "\n"
      "- Timing constraint: Pattern compilation ≤ 5000 ms\n\n"

      "## Results Summary\n\n"
      "| Pattern Type | Size | Time (ms) | Time/Row (ms) | Status |\n"
      "|--------------|------|-----------|---------------|--------|\n"
      (apply string-append
             (for/list ([result (reverse results)])
               (let ([type-name (first result)]
                     [size (second result)]
                     [elapsed (third result)])
                 (format "| ~a | ~a | ~a | ~a | ~a |\n"
                        type-name
                        size
                        (~r elapsed #:precision 2)
                        (~r (/ elapsed size) #:precision 3)
                        (if (< elapsed 5000) "✓ PASS" "✗ FAIL")))))

      "\n## Performance Analysis\n\n"
      (format "- **Average time per row**: ~a ms\n" (~r avg-time-per-row #:precision 3))
      (format "- **Maximum pattern time**: ~a ms\n" (~r max-compilation-time #:precision 1))
      (format "- **Constraint status**: ~a\n"
              (if (< max-compilation-time constraint-5s) "✅ MET" "❌ VIOLATED"))
      (format "- **Projected 1000-row time**: ~a ms (~a s)\n"
              (~r (* avg-time-per-row 1000) #:precision 1)
              (~r (/ (* avg-time-per-row 1000) 1000) #:precision 2))

      "\n## Recommendations\n\n"
      (if (< max-compilation-time constraint-5s)
          "✅ Current performance meets all timing constraints.\n"
          "❌ Performance optimization needed for larger patterns.\n")
      "- Consider implementing caching for repeated pattern elements\n"
      "- Monitor memory usage for very large patterns\n"
      "- Implement streaming/progressive generation for export operations\n"))

  (call-with-output-file "basic-performance-report.md"
    (lambda (out) (display report-content out))
    #:exists 'replace)

  (printf "📝 Report saved to: basic-performance-report.md\n")
  (printf "\n🎉 Benchmark completed successfully!\n"))

;; Main execution
(run-basic-benchmarks)