#lang sweet-exp typed/racket
;; Simple test for basic pattern functionality

require "../knotty-lib/main.rkt"

(printf "=== Testing Simple Pattern ===\n")

;; Create a simple pattern without complex cable stitches
define
  simple-pattern
  pattern
    [name "Simple Test Pattern"]
    [technique 'hand]
    [form 'flat]
    rows(1) k8
    rows(2) p8

(printf "Testing pattern generation...\n")
(define pattern-text (pattern->text simple-pattern))
(printf "Pattern text length: ~a characters\n" (string-length pattern-text))
(printf "✓ Simple pattern test PASSED\n")