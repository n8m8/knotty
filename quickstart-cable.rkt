#lang sweet-exp typed/racket

require "knotty-lib/main.rkt"

;; Quickstart Example 3: Cable Pattern Test
;; Uses proper cable stitch rc-2/2 instead of c4f

define
  cable-pattern
  pattern
    [name "Simple Cable"]
    [technique 'hand]
    [form 'flat]
    row(1) p2 k4 p2
    row(2) k2 rc-2/2 k2    ; rc-2/2 = 2/2 right cross (equivalent to c4f)
    rows(3 5 7) p2 k4 p2
    rows(4 6 8) k2 p4 k2

;; Generate text instructions to see the cable
text cable-pattern