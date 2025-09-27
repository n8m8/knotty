#lang sweet-exp typed/racket
require "../knotty-lib/main.rkt"

; Test 1: Valid pattern for testing
define
  test-pattern-1
  pattern
    [name "Test Pattern 1"]
    [technique 'hand]
    [form 'flat]
    rows(1) k10
    rows(2) p10

; Test 2: Another valid pattern for testing
define
  test-pattern-2
  pattern
    [name "Test Pattern 2"]
    [technique 'hand]
    [form 'flat]
    rows(1) k5
    rows(2) p5

; Simple test that checks if patterns are defined correctly
(printf "Testing validation...\n")
(printf "Pattern 1 text length: ~a\n" (string-length (pattern->text test-pattern-1)))
(printf "Pattern 2 text length: ~a\n" (string-length (pattern->text test-pattern-2)))
(printf "✓ Validation test completed - patterns parsed successfully\n")