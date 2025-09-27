#lang sweet-exp typed/racket
require "../knotty-lib/main.rkt"

; Test 1: Pattern with inconsistent stitch counts
define
  broken-pattern-1
  pattern
    [name "Broken Pattern - Inconsistent Stitches"]
    [technique 'hand]
    [form 'flat]
    rows(1) k10    ; Starts with 10 stitches
    rows(2) p8     ; Only 8 stitches - should cause error

; Test 2: Pattern with missing rows
define
  broken-pattern-2
  pattern
    [name "Broken Pattern - Missing Rows"]
    [technique 'hand]
    [form 'flat]
    rows(1) k10
    rows(3) p10    ; Missing row 2 - should cause error

; Try to execute the second broken pattern (missing rows)
(text broken-pattern-2)