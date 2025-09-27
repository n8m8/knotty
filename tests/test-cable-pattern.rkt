#lang sweet-exp typed/racket
;; Test for pattern with multiple rows

require "../knotty-lib/main.rkt"

(printf "=== Testing Multi-Row Pattern ===\n")

;; Create a pattern with multiple rows
define
  multi-row-pattern
  pattern
    [name "Multi-Row Test Pattern"]
    [technique 'hand]
    [form 'flat]
    rows(1) k6 p2 k6
    rows(2) p6 k2 p6
    rows(3) k6 p2 k6
    rows(4) p6 k2 p6

(printf "Testing multi-row pattern generation...\n")
(define pattern-text (pattern->text multi-row-pattern))
(printf "Pattern text length: ~a characters\n" (string-length pattern-text))
(printf "✓ Multi-row pattern test PASSED\n")