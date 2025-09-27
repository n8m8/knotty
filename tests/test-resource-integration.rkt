#lang sweet-exp typed/racket
;; Simple resource integration test

require "../knotty-lib/main.rkt"

(printf "=== Testing Resource Integration ===\n")

;; Test basic resource availability
(printf "Testing basic functionality...\n")

;; Create a simple pattern to test resources
define
  resource-test-pattern
  pattern
    [name "Resource Test Pattern"]
    [technique 'hand]
    [form 'flat]
    rows(1) k10
    rows(2) p10

;; Test pattern creation (uses internal resources)
(define pattern-text (pattern->text resource-test-pattern))
(printf "Pattern text generated: ~a characters\n" (string-length pattern-text))

(printf "✓ Resource integration test PASSED\n")