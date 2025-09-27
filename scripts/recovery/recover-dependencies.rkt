#lang racket

;;;; Dependency Recovery Script
;;;; Specialized recovery for dependency resolution failures
;;;; Part of AI Rebuild Integration Layer - Phase 4.0

(provide recover-dependencies
         diagnose-dependencies
         DependencyDiagnostic)

(require racket/system
         racket/path
         racket/file
         racket/string
         racket/format)

(struct DependencyDiagnostic (catalog-accessible? packages-installed? saxon-available? details) #:transparent)

(define (diagnose-dependencies)
  "Comprehensive dependency diagnosis"
  (printf "=== Dependency Diagnosis ===~n")

  (define catalog-ok? (check-catalog-access))
  (define packages-ok? (check-installed-packages))
  (define saxon-ok? (check-saxon-availability))

  (printf "Catalog Access: ~a~n" (if catalog-ok? "OK" "FAILED"))
  (printf "Packages: ~a~n" (if packages-ok? "OK" "ISSUES"))
  (printf "Saxon JAR: ~a~n" (if saxon-ok? "OK" "MISSING"))

  (DependencyDiagnostic catalog-ok? packages-ok? saxon-ok?
                       (hash 'installed-packages (get-installed-packages)
                             'missing-packages (get-missing-packages))))

(define (recover-dependencies)
  "Attempt to recover dependency resolution"
  (printf "=== Dependency Recovery ===~n")

  (define diagnosis (diagnose-dependencies))

  ;; Fix catalog access if needed
  (unless (DependencyDiagnostic-catalog-accessible? diagnosis)
    (printf "Fixing catalog access...~n")
    (fix-catalog-access))

  ;; Reinstall packages if needed
  (unless (DependencyDiagnostic-packages-installed? diagnosis)
    (printf "Reinstalling packages...~n")
    (reinstall-packages))

  ;; Fix Saxon if needed
  (unless (DependencyDiagnostic-saxon-available? diagnosis)
    (printf "Installing Saxon...~n")
    (install-saxon))

  (printf "Dependency recovery completed~n"))

(define (check-catalog-access)
  "Check if package catalog is accessible"
  (with-handlers ([exn:fail? (lambda (e) #f)])
    (system "raco pkg catalog")
    #t))

(define (check-installed-packages)
  "Check if required packages are installed"
  (with-handlers ([exn:fail? (lambda (e) #f)])
    (define required-packages '("base" "typed-racket-lib"))
    (define installed-packages (get-installed-packages))
    (andmap (lambda (pkg) (member pkg installed-packages)) required-packages)))

(define (check-saxon-availability)
  "Check if Saxon JAR is available"
  (or (file-exists? "lib/saxon-he-12.x.jar")
      (file-exists? "dependencies/saxon-he-12.x.jar")
      (find-saxon-jar)))

(define (get-installed-packages)
  "Get list of installed packages"
  (with-handlers ([exn:fail? (lambda (e) '())])
    (define output (process "raco pkg show --all"))
    (if output
        (string-split output "\n")
        '())))

(define (get-missing-packages)
  "Get list of missing required packages"
  (define required '("base" "typed-racket-lib"))
  (define installed (get-installed-packages))
  (filter (lambda (pkg) (not (member pkg installed))) required))

(define (fix-catalog-access)
  "Fix package catalog access"
  (printf "  Updating package catalog...~n")
  (system "raco pkg catalog"))

(define (reinstall-packages)
  "Reinstall required packages"
  (printf "  Installing required packages...~n")
  (system "raco pkg install --deps search-auto base typed-racket-lib"))

(define (install-saxon)
  "Install Saxon JAR"
  (printf "  Installing Saxon JAR...~n")
  (make-directory* "lib")
  ;; In production, would download from official source
  (printf "  Note: Saxon JAR must be manually downloaded to lib/saxon-he-12.x.jar~n"))

(define (find-saxon-jar)
  "Find Saxon JAR in common locations"
  (ormap file-exists?
         '("lib/saxon-he-12.x.jar"
           "dependencies/saxon-he-12.x.jar"
           "../lib/saxon-he-12.x.jar")))

(module+ main
  (recover-dependencies))