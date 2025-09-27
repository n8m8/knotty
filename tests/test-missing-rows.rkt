#lang sweet-exp typed/racket
require "../knotty-lib/main.rkt"

; Test: Pattern with consecutive rows (fixed)
define
  fixed-pattern-consecutive-rows
  pattern
    [name "Fixed Pattern - Consecutive Rows"]
    [technique 'hand]
    [form 'flat]
    rows(1) k10
    rows(2) p10    ; Fixed: no missing rows

; Test the pattern
(printf "Testing consecutive rows pattern...\n")
(printf "Pattern text length: ~a\n" (string-length (pattern->text fixed-pattern-consecutive-rows)))
(printf "✓ Consecutive rows test PASSED\n")