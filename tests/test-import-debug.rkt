#lang typed/racket

(require "../knotty-lib/main.rkt")

; Import debugging test
(printf "=== Import Debug Test ===\n")
(printf "Working directory: ~a\n" (current-directory))

; Check if knotty-lib exists
(printf "Checking knotty-lib...\n")
(printf "knotty-lib exists: ~a\n" (directory-exists? "knotty-lib"))
(printf "knotty-lib/main.rkt exists: ~a\n" (file-exists? "knotty-lib/main.rkt"))

; Try to resolve the path
(define resolved (resolve-path "knotty-lib/main.rkt"))
(printf "Resolved path: ~a\n" resolved)
(printf "Resolved path exists: ~a\n" (file-exists? resolved))

(printf "✓ Import debug test completed\n")