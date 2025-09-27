#lang typed/racket
(require "../knotty-lib/main.rkt")

; Simple test with require
(printf "=== Simple Require Test ===\n")
(printf "Working directory: ~a\n" (current-directory))
(printf "✓ Successfully required and running\n")