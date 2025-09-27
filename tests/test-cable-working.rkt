#lang sweet-exp typed/racket

require "../knotty-lib/main.rkt"

;; Create cable pattern similar to quickstart Example 3
define
  cable-pattern
  pattern
    [name "Simple Cable Test"]
    [technique 'hand]
    [form 'flat]
    row(1) p2 k4 p2
    row(2) k2 rc-2/2 k2    ; 2/2 right cross cable
    rows(3 5 7) p2 k4 p2
    rows(4 6 8) k2 p4 k2

;; Test text output (instructions)
text cable-pattern

;; Test pattern properties
printf "\n=== Cable Pattern Properties ===\n"
printf "Name: ~a\n" (Pattern-name cable-pattern)
printf "Technique: ~a\n" (Options-technique (Pattern-options cable-pattern))
printf "Form: ~a\n" (Options-form (Pattern-options cable-pattern))
printf "Row count: ~a\n" (Pattern-nrows cable-pattern)

;; Test stitch symbols
printf "\nStitch symbols used: ~a\n" (pattern-symbols cable-pattern)

printf "\n=== Cable Pattern Test Complete ===\n"