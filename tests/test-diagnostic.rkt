#lang typed/racket

; Diagnostic test to check environment and imports
(printf "=== Diagnostic Test ===\n")
(printf "Racket version: ~a\n" (version))
(printf "Current directory: ~a\n" (current-directory))

; Test if we can find the parent directory
(define parent-dir (build-path (current-directory) ".."))
(printf "Parent directory: ~a\n" parent-dir)
(printf "Parent directory exists: ~a\n" (directory-exists? parent-dir))

; Test if knotty-lib exists
(define knotty-lib-path (build-path parent-dir "knotty-lib"))
(printf "Knotty-lib path: ~a\n" knotty-lib-path)
(printf "Knotty-lib exists: ~a\n" (directory-exists? knotty-lib-path))

; Test if main.rkt exists
(define main-rkt-path (build-path knotty-lib-path "main.rkt"))
(printf "Main.rkt path: ~a\n" main-rkt-path)
(printf "Main.rkt exists: ~a\n" (file-exists? main-rkt-path))

; Check if we can resolve the import path
(printf "Checking import resolution...\n")
(define import-path "../knotty-lib/main.rkt")
(printf "Import path: ~a\n" import-path)
(define resolved-path (resolve-path import-path))
(printf "Resolved path: ~a\n" resolved-path)
(printf "Resolved path exists: ~a\n" (file-exists? resolved-path))

(printf "✓ Diagnostic test completed\n")