#lang sweet-exp typed/racket
require "../knotty-lib/main.rkt"

; Simple working pattern test
define
  simple-pattern
  pattern
    [name "Simple Test Pattern"]
    [technique 'hand]
    [form 'flat]
    rows(1) k10
    rows(2) p10

; Test that the pattern compiles
(printf "Testing simple pattern creation...\n")
(define result (pattern->text simple-pattern))
(printf "Pattern text generated successfully: ~a characters\n" (string-length result))
(printf "✓ Simple pattern test PASSED\n")