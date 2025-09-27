#lang sweet-exp typed/racket
;; Test for working pattern functionality

require "../knotty-lib/main.rkt"

(printf "=== Testing Working Pattern ===\n")

;; Create a working pattern
define
  working-pattern
  pattern
    [name "Working Test Pattern"]
    [technique 'hand]
    [form 'flat]
    rows(1) k4 p4 k4
    rows(2) p4 k4 p4

(printf "Testing working pattern generation...\n")
(define pattern-text (pattern->text working-pattern))
(printf "Pattern text length: ~a characters\n" (string-length pattern-text))
(printf "✓ Working pattern test PASSED\n")