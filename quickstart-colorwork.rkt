#lang typed/racket

(require "knotty-lib/main.rkt")

;; Create yarns with colors
(define red-yarn (yarn #xFF0000 "Red"))
(define blue-yarn (yarn #x0000FF "Blue"))

;; Create simple stripes pattern
(define simple-stripes
  (pattern
    ((row 1) (k 8))
    ((row 2) (p 8))
    ((row 3) (cc1 (k 8)))
    ((row 4) (cc1 (p 8)))
    red-yarn   ; yarn for mc
    blue-yarn  ; yarn for cc1
    ))

;; Export to HTML with colors
(export-html simple-stripes "stripes.html")