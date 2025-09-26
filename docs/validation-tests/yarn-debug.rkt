#lang typed/racket

(require "knotty-lib/main.rkt")

;; Test direct yarn creation
(printf "Testing direct yarn creation:\n")
(define test-red (yarn #xFF0000 "Red"))
(define test-blue (yarn #x0000FF "Blue"))

(printf "Red: ~a -> ~a\n" #xFF0000 (Yarn-color test-red))
(printf "Blue: ~a -> ~a\n" #x0000FF (Yarn-color test-blue))

;; Test if it's a parsing issue
(printf "\nTesting literal values:\n")
(printf "Literal #xFF0000 = ~a\n" #xFF0000)
(printf "Literal #x0000FF = ~a\n" #x0000FF)
(printf "Literal 16711680 = ~a\n" 16711680)
(printf "Literal 255 = ~a\n" 255)

;; Create pattern and check yarns
(printf "\nTesting in pattern context:\n")
(define simple-pattern
  (pattern
    ((row 1) (k 8))
    ((row 2) (p 8))
    test-red
    test-blue))

(let ([yarns (Pattern-yarns simple-pattern)])
  (printf "Pattern yarn 0: ~a (expected ~a)\n" (Yarn-color (vector-ref yarns 0)) #xFF0000)
  (printf "Pattern yarn 1: ~a (expected ~a)\n" (Yarn-color (vector-ref yarns 1)) #x0000FF))