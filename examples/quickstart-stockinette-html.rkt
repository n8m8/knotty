#lang sweet-exp typed/racket
require "knotty-lib/main.rkt"

define
  basic-stockinette
  pattern
    [name "Basic Stockinette"]
    [technique 'hand]
    [form 'flat]
    rows(1 3 5) k10    ; Knit rows
    rows(2 4 6) p10    ; Purl rows

;; Generate written instructions
(text basic-stockinette)

;; Export to HTML file
(export-html basic-stockinette "/Users/n8m8/workspace/knotty/basic-stockinette.html")