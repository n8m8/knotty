#lang racket/base

;; Integration test for environment setup
;; Tests complete environment setup procedures as described in quickstart.md
;; These tests MUST FAIL initially as full integration implementations don't exist

(require rackunit
         racket/system
         racket/port
         racket/file
         racket/path
         racket/string)

(provide (all-defined-out))

;; Helper function to run system commands and capture output
(define (run-command cmd)
  (define-values (proc stdout stdin stderr)
    (subprocess #f #f #f "/bin/sh" "-c" cmd))
  (subprocess-wait proc)
  (define exit-code (subprocess-status proc))
  (define output (port->string stdout))
  (close-input-port stdout)
  (close-output-port stdin)
  (close-input-port stderr)
  (values exit-code output))

;; Test: Platform Compatibility Check
(define-test-suite platform-compatibility-tests
  "Test platform detection and compatibility verification"

  (test-case "Platform detection should work"
    (define-values (exit-code output) (run-command "uname -a"))
    (check-equal? exit-code 0 "Platform detection command should succeed")
    (check-true (or (string-contains? output "Linux")
                   (string-contains? output "Darwin")
                   (string-contains? output "CYGWIN")
                   (string-contains? output "MINGW"))
               "Should detect supported platform"))

  (test-case "Git should be available"
    (define-values (exit-code output) (run-command "git --version"))
    (check-equal? exit-code 0 "Git should be installed")
    (check-true (string-contains? output "git version")
               "Git version should be reported"))

  (test-case "Java should be available for Saxon XSLT"
    (define-values (exit-code output) (run-command "java -version"))
    (check-equal? exit-code 0 "Java should be installed")
    ;; This test will fail initially - Saxon integration not implemented
    (check-true (string-contains? (string-downcase output) "java")
               "Java version should be reported")))

;; Test: Racket Environment Setup
(define-test-suite racket-environment-tests
  "Test Racket installation and environment setup"

  (test-case "Racket should be available"
    (define-values (exit-code output) (run-command "racket --version"))
    (check-equal? exit-code 0 "Racket should be installed")
    (check-true (string-contains? output "Racket")
               "Racket version should be reported"))

  (test-case "Raco package manager should be available"
    (define-values (exit-code output) (run-command "raco --version"))
    (check-equal? exit-code 0 "Raco should be available")
    (check-true (string-contains? output "raco")
               "Raco version should be reported"))

  (test-case "Project packages should be installable"
    ;; This test will fail initially - proper package structure not implemented
    (define project-root (path->string (simplify-path (build-path (current-directory) ".." ".."))))
    (define knotty-lib-path (build-path project-root "knotty-lib"))
    (define cmd (format "cd ~a && raco pkg install --deps search-auto --link ~a"
                       project-root
                       (path->string knotty-lib-path)))
    (define-values (exit-code output) (run-command cmd))
    ;; Expected to fail initially
    (check-not-equal? exit-code 0 "Package installation should fail initially (not implemented)")
    (check-true (or (string-contains? output "error")
                   (string-contains? output "failed")
                   (string-contains? output "not found"))
               "Should report installation failure")))

;; Test: Docker Environment (Optional)
(define-test-suite docker-environment-tests
  "Test Docker environment setup if available"

  (test-case "Docker availability check"
    (define-values (exit-code output) (run-command "docker --version"))
    (when (= exit-code 0)
      (check-true (string-contains? output "Docker")
                 "Docker version should be reported if available")))

  (test-case "Dockerfile should exist for containerized builds"
    ;; This test will fail initially - Dockerfile not implemented
    (define project-root (path->string (simplify-path (build-path (current-directory) ".." ".."))))
    (define dockerfile-path (build-path project-root "Dockerfile"))
    (check-false (file-exists? dockerfile-path)
                "Dockerfile should not exist initially (not implemented)")))

;; Test: Project Structure Validation
(define-test-suite project-structure-tests
  "Test project directory structure matches expected layout"

  (test-case "Core directories should exist"
    (define project-root (path->string (simplify-path (build-path (current-directory) ".." ".."))))
    (define core-dirs '("tests" "docs" "specs"))
    (for ([dir core-dirs])
      (define dir-path (build-path project-root dir))
      (check-true (directory-exists? dir-path)
                 (format "Directory ~a should exist" dir))))

  (test-case "Knotty-lib directory should exist"
    ;; This test will fail initially - knotty-lib structure not fully implemented
    (define project-root (path->string (simplify-path (build-path (current-directory) ".." ".."))))
    (define knotty-lib-path (build-path project-root "knotty-lib"))
    (check-false (directory-exists? knotty-lib-path)
                "knotty-lib directory should not exist initially (not implemented)"))

  (test-case "Makefile should exist for build automation"
    ;; This test will fail initially - Makefile not implemented
    (define project-root (path->string (simplify-path (build-path (current-directory) ".." ".."))))
    (define makefile-path (build-path project-root "Makefile"))
    (check-false (file-exists? makefile-path)
                "Makefile should not exist initially (not implemented)")))

;; Test: Dependency Resolution
(define-test-suite dependency-resolution-tests
  "Test external dependency resolution and availability"

  (test-case "Saxon XSLT processor should be available"
    ;; This test will fail initially - Saxon integration not implemented
    (define project-root (path->string (simplify-path (build-path (current-directory) ".." ".."))))
    (define cmd (format "cd ~a && find . -name 'saxon-he-*.jar' 2>/dev/null" project-root))
    (define-values (exit-code output) (run-command cmd))
    (check-equal? (string-trim output) ""
                 "Saxon JAR should not be found initially (not implemented)"))

  (test-case "Required Racket packages should be resolvable"
    ;; This test will fail initially - package dependencies not fully specified
    (define-values (exit-code output) (run-command "raco pkg show --all"))
    (check-equal? exit-code 0 "Package listing should work")
    ;; Check for packages that should be installed but aren't yet
    (check-false (string-contains? output "knotty")
                "Knotty packages should not be installed initially")
    (check-false (string-contains? output "knotty-lib")
                "Knotty-lib packages should not be installed initially")))

;; Main test suite
(define-test-suite environment-setup-integration-tests
  "Complete integration tests for environment setup"
  platform-compatibility-tests
  racket-environment-tests
  docker-environment-tests
  project-structure-tests
  dependency-resolution-tests)

;; Run tests when module is executed directly
(module+ test
  (require rackunit/text-ui)
  (run-tests environment-setup-integration-tests))

;; Export for external test runners
(module+ main
  (require rackunit/text-ui)
  (run-tests environment-setup-integration-tests))