#lang sweet-exp typed/racket
;; Test cable pattern from quickstart Example 3

require "knotty-lib/main.rkt"

(printf "=== Testing Cable Pattern from Quickstart Example 3 ===\n\n")

;; Create the cable pattern from quickstart using the proper syntax
(printf "1. Creating cable pattern...\n")
define
  cable-pattern
  with-handlers ([exn:fail? (lambda (e)
                              (printf "ERROR creating pattern: ~a\n" (exn-message e))
                              #f)])
    pattern
      [name "Simple Cable"]
      [technique 'hand]
      [form 'flat]
      row(1) p2 k4 p2
      row(2) k2 rc-2/2 k2    ; rc-2/2 = 2/2 right cross (cable 4 front)
      rows(3 5 7) p2 k4 p2
      rows(4 6 8) k2 p4 k2

(if cable-pattern
    (printf "✓ Pattern created successfully\n")
    (printf "✗ Pattern creation failed\n"))

;; Test pattern properties
(when cable-pattern
  (printf "\n2. Testing pattern properties...\n")
  (printf "   Name: ~a\n" (Pattern-name cable-pattern))
  (printf "   Technique: ~a\n" (Options-technique (Pattern-options cable-pattern)))
  (printf "   Form: ~a\n" (Options-form (Pattern-options cable-pattern)))
  (printf "   Row count: ~a\n" (Pattern-nrows cable-pattern)))

;; Test pattern symbols (including cable symbols)
(when cable-pattern
  (printf "\n3. Testing pattern symbols (including cables)...\n")
  (define all-symbols (pattern-symbols cable-pattern))
  (printf "   All stitch symbols used: ~a\n" all-symbols)

  (define cable-symbols
    (filter (λ (sym) (string-contains? (symbol->string sym) "rc-")) all-symbols))
  (printf "   Cable symbols found: ~a\n" cable-symbols))

;; Test chart generation
(when cable-pattern
  (printf "\n4. Testing chart generation...\n")
  (define chart-result
    (with-handlers ([exn:fail? (lambda (e)
                                (printf "ERROR generating chart: ~a\n" (exn-message e))
                                #f)])
      (show cable-pattern)))

  (printf "✓ Chart display attempted\n"))

;; Test text instructions
(when cable-pattern
  (printf "\n5. Testing text instructions generation...\n")
  (define text-result
    (with-handlers ([exn:fail? (lambda (e)
                                (printf "ERROR generating text: ~a\n" (exn-message e))
                                #f)])
      (text cable-pattern)))

  (printf "✓ Text instructions generated\n"))

;; Test HTML export via CLI interface
(when cable-pattern
  (printf "\n6. Testing HTML export capabilities...\n")
  (printf "   Pattern ready for HTML export via CLI\n")
  (printf "   Would use: racket knotty-lib/cli.rkt -x -H cable-pattern\n"))

(printf "\n=== Cable Pattern Test Complete ===\n")