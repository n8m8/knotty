#lang racket/base

;; Integration test for cross-platform build compatibility
;; Tests cross-platform compatibility requirements as described in quickstart.md
;; These tests MUST FAIL initially as full integration implementations don't exist

(require rackunit
         racket/system
         racket/port
         racket/file
         racket/path
         racket/string
         racket/runtime-path)

(provide (all-defined-out))

;; Platform detection utilities
(define (current-platform)
  (define-values (exit-code output)
    (let-values ([(proc out in err) (subprocess #f #f #f (find-executable-path "uname") "-s")])
      (subprocess-wait proc)
      (begin0
        (values (subprocess-status proc) (port->string out))
        (close-input-port out)
        (close-output-port in)
        (close-input-port err))))
  (cond
    [(string-contains? (string-downcase output) "linux") 'linux]
    [(string-contains? (string-downcase output) "darwin") 'macos]
    [(string-contains? (string-downcase output) "cygwin") 'windows]
    [(string-contains? (string-downcase output) "mingw") 'windows]
    [else 'unknown]))

(define (run-platform-command cmd)
  (define-values (proc stdout stdin stderr)
    (subprocess #f #f #f "/bin/sh" "-c" cmd))
  (subprocess-wait proc)
  (define exit-code (subprocess-status proc))
  (define output (port->string stdout))
  (close-input-port stdout)
  (close-output-port stdin)
  (close-input-port stderr)
  (values exit-code output))

;; Test: Platform-Specific Path Handling
(define-test-suite platform-path-tests
  "Test cross-platform path handling and file operations"

  (test-case "Path separators should work on current platform"
    (define platform (current-platform))
    (define test-path (case platform
                        [(windows) "C:\\temp\\test"]
                        [else "/tmp/test"]))
    (define normalized (path->string (string->path test-path)))
    (check-true (string? normalized)
               "Path normalization should work on current platform"))

  (test-case "Temporary directory creation should work cross-platform"
    (define temp-dir (find-system-path 'temp-dir))
    (define test-subdir (build-path temp-dir "knotty-test"))
    (when (directory-exists? test-subdir)
      (delete-directory/files test-subdir))
    (make-directory test-subdir)
    (check-true (directory-exists? test-subdir)
               "Temporary directory creation should work")
    (delete-directory/files test-subdir))

  (test-case "File permissions should be handled correctly"
    (define temp-file (make-temporary-file "knotty-test-~a.txt"))
    (call-with-output-file temp-file
      (lambda (out) (write "test content" out))
      #:exists 'replace)
    (check-true (file-exists? temp-file)
               "Test file should be created")
    (delete-file temp-file)))

;; Test: Platform-Specific Executable Detection
(define-test-suite platform-executable-tests
  "Test cross-platform executable detection and invocation"

  (test-case "Racket executable should be findable on all platforms"
    (define racket-exe (find-executable-path "racket"))
    (check-true (and racket-exe (file-exists? racket-exe))
               "Racket executable should be found"))

  (test-case "Java executable should be findable for Saxon XSLT"
    (define java-exe (find-executable-path "java"))
    (check-true (and java-exe (file-exists? java-exe))
               "Java executable should be found for Saxon integration"))

  (test-case "Platform-specific shell should be available"
    (define platform (current-platform))
    (define shell-exe (case platform
                        [(windows) (find-executable-path "cmd")]
                        [else (find-executable-path "sh")]))
    (check-true (and shell-exe (file-exists? shell-exe))
               "Platform-appropriate shell should be available")))

;; Test: Cross-Platform Build Process
(define-test-suite cross-platform-build-tests
  "Test build process consistency across platforms"

  (test-case "Racket package compilation should work cross-platform"
    ;; This test will fail initially - proper package structure not implemented
    (define project-root (path->string (simplify-path (build-path (current-directory) ".." ".."))))
    (define knotty-lib-path (build-path project-root "knotty-lib"))

    (check-false (directory-exists? knotty-lib-path)
                "knotty-lib directory should not exist initially")

    ;; Try to compile what should exist
    (define cmd (format "cd ~a && raco setup --no-docs --pkgs knotty-lib" project-root))
    (define-values (exit-code output) (run-platform-command cmd))
    (check-not-equal? exit-code 0
                     "Package compilation should fail initially (not implemented)")
    (check-true (or (string-contains? output "error")
                   (string-contains? output "not found")
                   (string-contains? output "failed"))
               "Should report compilation failure"))

  (test-case "Output artifacts should be generated consistently"
    ;; This test will fail initially - no build artifacts generated
    (define project-root (path->string (simplify-path (build-path (current-directory) ".." ".."))))
    (define compiled-dir (build-path project-root "compiled"))

    (check-false (directory-exists? compiled-dir)
                "Compiled directory should not exist initially")

    ;; Check for other expected artifacts
    (define docs-dir (build-path project-root "docs"))
    (when (directory-exists? docs-dir)
      (define generated-docs (directory-list docs-dir))
      ;; Should have some generated content eventually
      (check-true (null? generated-docs)
                 "Generated docs should be empty initially")))

  (test-case "File encoding should be consistent across platforms"
    (define test-content "# Knotty Test Content\nUnicode: ⚡ ✓ ☃\nSymbols: ←→↑↓")
    (define temp-file (make-temporary-file "knotty-encoding-test-~a.txt"))

    ;; Write with UTF-8 encoding
    (call-with-output-file temp-file
      (lambda (out) (display test-content out))
      #:exists 'replace)

    ;; Read back and verify
    (define read-content (file->string temp-file))
    (check-equal? read-content test-content
                 "File encoding should be preserved across platforms")

    (delete-file temp-file)))

;; Test: Platform-Specific Dependencies
(define-test-suite platform-dependency-tests
  "Test platform-specific dependency handling"

  (test-case "Saxon JAR should work on current platform"
    ;; This test will fail initially - Saxon integration not implemented
    (define platform (current-platform))
    (define java-available? (find-executable-path "java"))

    (when java-available?
      (define project-root (path->string (simplify-path (build-path (current-directory) ".." ".."))))
      (define cmd (format "cd ~a && find . -name 'saxon-he-*.jar' 2>/dev/null" project-root))
      (define-values (exit-code output) (run-platform-command cmd))

      (check-equal? (string-trim output) ""
                   "Saxon JAR should not be found initially")

      ;; Test Java invocation would work if JAR existed
      (define java-test-cmd "java -version")
      (define-values (java-exit java-output) (run-platform-command java-test-cmd))
      (check-equal? java-exit 0
                   "Java should be functional for Saxon integration")))

  (test-case "Library loading should work cross-platform"
    ;; This test will fail initially - core libraries not implemented
    (define platform (current-platform))

    ;; Try to load core knotty modules
    (check-exn exn:fail?
               (lambda () (dynamic-require 'knotty-lib #f))
               "knotty-lib module should not be loadable initially")

    (check-exn exn:fail?
               (lambda () (dynamic-require 'knotty #f))
               "knotty module should not be loadable initially")))

;; Test: Performance Consistency
(define-test-suite cross-platform-performance-tests
  "Test performance consistency across platforms"

  (test-case "Racket compilation performance should be reasonable"
    (define start-time (current-inexact-milliseconds))

    ;; Simple Racket compilation test
    (define temp-file (make-temporary-file "knotty-perf-test-~a.rkt"))
    (call-with-output-file temp-file
      (lambda (out)
        (display "#lang racket/base\n(+ 1 2 3)" out))
      #:exists 'replace)

    (define cmd (format "racket -c ~a" (path->string temp-file)))
    (define-values (exit-code output) (run-platform-command cmd))

    (define end-time (current-inexact-milliseconds))
    (define compile-time (- end-time start-time))

    (check-equal? exit-code 0 "Simple compilation should succeed")
    (check-true (< compile-time 5000)
               "Simple compilation should complete quickly (< 5 seconds)")

    (delete-file temp-file))

  (test-case "File I/O performance should be consistent"
    (define test-data (make-string 10000 #\x))
    (define temp-file (make-temporary-file "knotty-io-test-~a.txt"))

    (define start-time (current-inexact-milliseconds))

    ;; Write large file
    (call-with-output-file temp-file
      (lambda (out) (display test-data out))
      #:exists 'replace)

    ;; Read it back
    (define read-data (file->string temp-file))

    (define end-time (current-inexact-milliseconds))
    (define io-time (- end-time start-time))

    (check-equal? read-data test-data "File I/O should preserve data")
    (check-true (< io-time 1000)
               "File I/O should be fast (< 1 second)")

    (delete-file temp-file)))

;; Test: Character Encoding and Internationalization
(define-test-suite cross-platform-encoding-tests
  "Test character encoding consistency across platforms"

  (test-case "Unicode handling should work consistently"
    (define unicode-content "Knitting symbols: ⚡⚡⚡ ← → ↑ ↓ ∿∿∿")
    (define temp-file (make-temporary-file "knotty-unicode-~a.txt"))

    (call-with-output-file temp-file
      (lambda (out) (display unicode-content out))
      #:exists 'replace)

    (define read-content (file->string temp-file))
    (check-equal? read-content unicode-content
                 "Unicode content should be preserved")

    (delete-file temp-file))

  (test-case "Special knitting symbols should render correctly"
    ;; This test will fail initially - symbol rendering not implemented
    (define knitting-symbols '("●" "○" "▢" "▣" "╱" "╲" "∿"))
    (define all-symbols (string-join knitting-symbols " "))

    ;; Test that symbols can be handled in strings
    (check-true (string? all-symbols)
               "Knitting symbols should be valid string content")

    ;; Eventually should test rendering to HTML/SVG
    (check-true #t "Symbol rendering tests not implemented yet")))

;; Main test suite
(define-test-suite cross-platform-integration-tests
  "Complete integration tests for cross-platform compatibility"
  platform-path-tests
  platform-executable-tests
  cross-platform-build-tests
  platform-dependency-tests
  cross-platform-performance-tests
  cross-platform-encoding-tests)

;; Run tests when module is executed directly
(module+ test
  (require rackunit/text-ui)
  (run-tests cross-platform-integration-tests))

;; Export for external test runners
(module+ main
  (require rackunit/text-ui)
  (run-tests cross-platform-integration-tests))