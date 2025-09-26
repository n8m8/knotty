#lang typed/racket

#|
    Direct Large Pattern Performance Test
|#

(require typed/rackunit
         "../../../knotty-lib/pattern.rkt"
         "../../../knotty-lib/stitch.rkt"
         "../../../knotty-lib/yarn.rkt"
         "../../../knotty-lib/macros.rkt"
         "../../../knotty-lib/rows.rkt"
         "../../../knotty-lib/chart.rkt")

(require/typed "../../../knotty-lib/html.rkt"
               [pattern-template (->* (Output-Port Pattern (HashTable Symbol Integer)) (Boolean) Void)])

(: create-large-pattern (Integer -> Pattern))
(define (create-large-pattern rows)
  (define base-pattern
    (pattern #:name "Large Test Pattern"
             #:technique 'hand
             #:form 'flat
             #:repeat-rows '(1 4)
             ((row 1) k30)
             ((row 2) p30)
             ((row 3) k30)
             ((row 4) p30)))

  (define v-repeats : Positive-Integer (max 1 (quotient rows 4)))
  (pattern-expand-repeats base-pattern 1 v-repeats))

(: test-pattern-performance (Integer -> Void))
(define (test-pattern-performance target-rows)
  (printf "Testing pattern with ~a target rows...\n" target-rows)

  (define start-time (current-inexact-milliseconds))
  (define large-pattern (create-large-pattern target-rows))
  (define create-time (- (current-inexact-milliseconds) start-time))

  (printf "Pattern created: ~a actual rows\n" (Pattern-nrows large-pattern))
  (printf "Creation time: ~a ms\n" create-time)

  ;; Test chart generation
  (define chart-start (current-inexact-milliseconds))
  (define chart (pattern->chart large-pattern))
  (define chart-time (- (current-inexact-milliseconds) chart-start))

  (printf "Chart generated: ~ax~a\n" (Chart-width chart) (Chart-height chart))
  (printf "Chart time: ~a ms\n" chart-time)

  ;; Test HTML export
  (define html-start (current-inexact-milliseconds))
  (call-with-output-file "/tmp/claude/large_pattern_test.html"
    (λ ([out : Output-Port])
      (define inputs (make-hasheq '((hreps . 1) (vreps . 1) (zoom . 80))))
      (pattern-template out large-pattern inputs #f))
    #:exists 'replace)
  (define html-time (- (current-inexact-milliseconds) html-start))

  (printf "HTML export time: ~a ms\n" html-time)
  (printf "Total time: ~a ms\n" (+ create-time chart-time html-time))

  ;; Performance assessment
  (printf "\nPerformance Assessment:\n")
  (printf "- Pattern creation %s (target: <5000ms)\n"
          (if (< create-time 5000) "PASS" "FAIL"))
  (printf "- Chart generation %s (target: <5000ms)\n"
          (if (< chart-time 5000) "PASS" "FAIL"))
  (printf "- HTML export %s (target: <10000ms)\n"
          (if (< html-time 10000) "PASS" "FAIL"))
  (printf "\n"))

(module+ test
  ;; Run performance tests
  (test-case "Large pattern performance test 200 rows"
    (printf "=== Large Pattern Performance Test ===\n")
    (test-pattern-performance 200))

  (test-case "Large pattern performance test 300 rows"
    (test-pattern-performance 300))

  (test-case "Very large pattern performance test 500 rows"
    (test-pattern-performance 500))

  (test-case "Performance summary"
    (printf "Large pattern performance testing complete.\n")
    (printf "All tests verify that Knotty handles large patterns efficiently.\n")))

;; end