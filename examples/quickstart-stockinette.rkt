#lang sweet-exp typed/racket
require "knotty-lib/main.rkt"

;; Basic Stockinette Pattern Example
;; Simple knit/purl alternating rows

define
  basic-stockinette
  pattern
    [name "Basic Stockinette"]
    [technique 'hand]
    [form 'flat]
    rows(1 3 5) k10    ; Knit rows
    rows(2 4 6) p10    ; Purl rows

;; Generate and display chart (note: show opens web browser)
;show basic-stockinette

;; Generate written instructions
(text basic-stockinette)