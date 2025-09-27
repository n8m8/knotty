#!/usr/bin/env racket
#lang racket

#|
Test suite for the Knotty validation CLI
Verifies all command-line flags and cross-platform analysis
|#

(require racket/system
         racket/path
         racket/file
         rackunit)

;; Test the validation suite CLI
(define validation-script (build-path (current-directory) "run-validation-suite"))

;; Ensure the validation script is executable
(define (make-executable path)
  (file-or-directory-permissions path #o755))

;; Test basic execution
(define (test-basic-execution)
  (test-case "Basic validation suite execution"
    (define result (system/exit-code (format "~a --help" validation-script)))
    (check-equal? result 0 "Help command should succeed")))

;; Test cross-platform analysis flag
(define (test-cross-platform-flag)
  (test-case "Cross-platform analysis flag"
    (define result (system/exit-code (format "~a --cross-platform-analysis --verbose" validation-script)))
    (check-equal? result 0 "Cross-platform analysis should execute successfully")))

;; Test verbose flag
(define (test-verbose-flag)
  (test-case "Verbose flag"
    (define result (system/exit-code (format "~a --verbose" validation-script)))
    (check-equal? result 0 "Verbose mode should work")))

;; Test output format flags
(define (test-output-formats)
  (test-case "Output format flags"
    (for ([format '("text" "json" "xml")])
      (define result (system/exit-code
                      (format "~a --cross-platform-analysis --output-format ~a"
                              validation-script format)))
      (check-equal? result 0 (format "Output format ~a should work" format)))))

;; Test invalid flags (should fail gracefully)
(define (test-invalid-flags)
  (test-case "Invalid flags handling"
    (define result (system/exit-code (format "~a --invalid-flag" validation-script)))
    (check-not-equal? result 0 "Invalid flags should cause non-zero exit")))

;; Main test suite
(define (run-tests)
  (displayln "Running validation suite CLI tests...")

  ;; Make script executable
  (when (file-exists? validation-script)
    (make-executable validation-script))

  ;; Run tests
  (test-basic-execution)
  (test-cross-platform-flag)
  (test-verbose-flag)
  (test-output-formats)
  (test-invalid-flags)

  (displayln "All CLI tests completed!"))

;; Entry point
(module* main racket
  (run-tests))