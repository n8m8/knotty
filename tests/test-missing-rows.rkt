#lang sweet-exp typed/racket
require "knotty-lib/main.rkt"

; Test: Pattern with missing rows
define
  broken-pattern-missing-rows
  pattern
    [name "Broken Pattern - Missing Rows"]
    [technique 'hand]
    [form 'flat]
    rows(1) k10
    rows(3) p10    ; Missing row 2 - should cause error

; Try to execute the pattern
(text broken-pattern-missing-rows)