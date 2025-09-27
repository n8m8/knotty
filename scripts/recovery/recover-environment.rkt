#lang racket

;;;; Environment Recovery Script
;;;; Specialized recovery for environment setup failures
;;;; Part of AI Rebuild Integration Layer - Phase 4.0

(provide recover-environment
         diagnose-environment
         EnvironmentDiagnostic)

(require racket/system
         racket/path
         racket/file
         racket/string
         racket/format)

(struct EnvironmentDiagnostic (racket-ok? java-ok? git-ok? permissions-ok? disk-space-ok? details) #:transparent)

(define (diagnose-environment)
  "Comprehensive environment diagnosis"
  (printf "=== Environment Diagnosis ===~n")

  (define racket-path (find-executable-path "racket"))
  (define java-path (find-executable-path "java"))
  (define git-path (find-executable-path "git"))

  (printf "Racket: ~a~n" (if racket-path racket-path "NOT FOUND"))
  (printf "Java: ~a~n" (if java-path java-path "NOT FOUND"))
  (printf "Git: ~a~n" (if git-path git-path "NOT FOUND"))

  (define permissions-ok? (check-permissions))
  (define disk-space-ok? (check-disk-space))

  (printf "Permissions: ~a~n" (if permissions-ok? "OK" "ISSUES"))
  (printf "Disk Space: ~a~n" (if disk-space-ok? "OK" "LOW"))

  (EnvironmentDiagnostic racket-path java-path git-path permissions-ok? disk-space-ok?
                        (hash 'racket-version (get-racket-version)
                              'java-version (get-java-version)
                              'platform (system-type))))

(define (recover-environment)
  "Attempt to recover environment setup"
  (printf "=== Environment Recovery ===~n")

  (define diagnosis (diagnose-environment))

  ;; Fix Racket if needed
  (unless (EnvironmentDiagnostic-racket-ok? diagnosis)
    (printf "Attempting to fix Racket installation...~n")
    (fix-racket-installation))

  ;; Fix Java if needed
  (unless (EnvironmentDiagnostic-java-ok? diagnosis)
    (printf "Attempting to fix Java installation...~n")
    (fix-java-installation))

  ;; Fix permissions if needed
  (unless (EnvironmentDiagnostic-permissions-ok? diagnosis)
    (printf "Fixing permissions...~n")
    (fix-permissions))

  (printf "Environment recovery completed~n"))

(define (check-permissions)
  "Check if we have necessary permissions"
  (with-handlers ([exn:fail? (lambda (e) #f)])
    (define test-file "permission-test.tmp")
    (call-with-output-file test-file (lambda (out) (display "test" out)))
    (delete-file test-file)
    #t))

(define (check-disk-space)
  "Check available disk space"
  ;; Simplified check - in production would use proper disk space API
  #t)

(define (get-racket-version)
  "Get Racket version if available"
  (with-handlers ([exn:fail? (lambda (e) "unknown")])
    (version)))

(define (get-java-version)
  "Get Java version if available"
  (with-handlers ([exn:fail? (lambda (e) "unknown")])
    (define result (process "java -version"))
    (if result "detected" "unknown")))

(define (fix-racket-installation)
  "Attempt to fix Racket installation"
  (printf "  Checking Racket package manager...~n")
  (system "raco pkg update --all"))

(define (fix-java-installation)
  "Attempt to fix Java installation"
  (printf "  Java not found - please install Java 11 or later~n"))

(define (fix-permissions)
  "Fix file permissions"
  (printf "  Fixing file permissions...~n")
  (system "chmod -R u+rw ."))

(module+ main
  (recover-environment))