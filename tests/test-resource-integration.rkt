#lang racket

;; Integration tests for the Knotty DSL resource management system
;; Tests Saxon integration, font management, and path resolution

(require rackunit
         "../lib/saxon-integration.rkt"
         "../lib/font-manager.rkt"
         "../lib/path-resolver.rkt")

;; Test Saxon integration
(define saxon-tests
  (test-suite
   "Saxon XSLT Integration Tests"

   (test-case "Saxon availability check"
     (check-true (or (saxon-available?)
                     (file-exists? saxon-jar-path))
                 "Saxon should be available or JAR should exist"))

   (test-case "Saxon JAR path resolution"
     (check-true (path? saxon-jar-path)
                 "Saxon JAR path should be a valid path"))

   (test-case "Java compatibility check"
     (define java-info (validate-java-installation))
     (check-true (hash-ref java-info 'java-found)
                 "Java executable should be found")
     (when (hash-ref java-info 'java-found)
       (check-true (hash-ref java-info 'compatible #f)
                   "Java version should be compatible (8+)")))

   (test-case "Saxon statistics initialization"
     (reset-saxon-statistics!)
     (define stats (get-saxon-statistics))
     (check-true (hash? stats)
                 "Statistics should be a hash table"))))

;; Test font and symbol management
(define font-tests
  (test-suite
   "Font and Symbol Management Tests"

   (test-case "Knitting symbols availability"
     (check-true (hash? knitting-symbols)
                 "Knitting symbols should be defined as hash")
     (check-true (> (hash-count knitting-symbols) 0)
                 "Should have at least some knitting symbols defined"))

   (test-case "Basic symbol lookup"
     (check-not-false (hash-ref knitting-symbols "k" #f)
                      "Basic knit symbol should be defined")
     (check-not-false (hash-ref knitting-symbols "p" #f)
                      "Basic purl symbol should be defined"))

   (test-case "Unicode symbol retrieval"
     (check-string? (get-unicode-symbol "k")
                    "Should return Unicode string for knit")
     (check-string? (get-unicode-symbol "p")
                    "Should return Unicode string for purl")
     (check-false (get-unicode-symbol "nonexistent")
                  "Should return #f for unknown symbol"))

   (test-case "Symbol description retrieval"
     (check-string? (get-symbol-description "k")
                    "Should return description for knit")
     (check-false (get-symbol-description "nonexistent")
                  "Should return #f for unknown symbol"))

   (test-case "Symbol rendering modes"
     (set-rendering-mode! 'unicode)
     (check-eq? (current-rendering-mode) 'unicode
                "Should set rendering mode to unicode")
     (set-rendering-mode! 'svg)
     (check-eq? (current-rendering-mode) 'svg
                "Should set rendering mode to svg"))

   (test-case "Symbol rendering"
     (set-rendering-mode! 'unicode)
     (check-string? (render-symbol "k")
                    "Should render knit symbol as string")
     (check-string? (render-symbol "nonexistent")
                    "Should return fallback for unknown symbol"))

   (test-case "Custom symbol registration"
     (register-custom-symbol "test-symbol" "T" "test.svg" "Test symbol")
     (check-not-false (hash-ref knitting-symbols "test-symbol" #f)
                      "Custom symbol should be registered")
     (check-string? (get-unicode-symbol "test-symbol")
                    "Custom symbol should have Unicode representation"))))

;; Test path resolution
(define path-tests
  (test-suite
   "Cross-Platform Path Resolution Tests"

   (test-case "Platform detection"
     (check-true (symbol? current-platform)
                 "Current platform should be detected as symbol")
     (check-true (memq current-platform '(windows macos unix))
                 "Platform should be one of the supported types"))

   (test-case "Platform information"
     (check-true (hash? platform-info)
                 "Platform info should be a hash")
     (check-string? (hash-ref platform-info 'path-separator)
                    "Path separator should be defined")
     (check-string? (hash-ref platform-info 'directory-separator)
                    "Directory separator should be defined"))

   (test-case "Project root detection"
     (check-true (path? project-root)
                 "Project root should be a valid path")
     (check-true (directory-exists? project-root)
                 "Project root should exist"))

   (test-case "Resource path resolution"
     (check-true (path? (resolve-resource-path 'lib))
                 "Should resolve lib path")
     (check-true (path? (resolve-resource-path 'cache))
                 "Should resolve cache path")
     (check-true (path? (resolve-resource-path 'resources))
                 "Should resolve resources path"))

   (test-case "Safe path building"
     (define test-path (safe-build-path "test" "subdir" "file.txt"))
     (check-true (path? test-path)
                 "Should build valid path")
     (check-true (string-contains? (path->string test-path) "test")
                 "Should contain path components"))

   (test-case "Path normalization"
     (define test-path "test/path\\mixed/separators")
     (define normalized (normalize-path test-path))
     (check-true (path? normalized)
                 "Should normalize to valid path"))

   (test-case "Java executable detection"
     (define java-exe (find-java-executable))
     (when java-exe
       (check-true (file-exists? java-exe)
                   "Java executable should exist if found")))

   (test-case "Resource information"
     (define info (get-resource-info))
     (check-true (hash? info)
                 "Should return resource information hash")
     (check-true (hash-has-key? info 'platform)
                 "Should include platform information")
     (check-true (hash-has-key? info 'paths)
                 "Should include path information"))

   (test-case "Portable path handling"
     (define test-path (build-path project-root "test" "file.txt"))
     (define portable (create-portable-path test-path))
     (define resolved (resolve-portable-path portable))
     (check-string? portable
                    "Should create portable path string")
     (check-true (path? resolved)
                 "Should resolve portable path back to path object"))))

;; Integration test for complete workflow
(define integration-tests
  (test-suite
   "Complete Resource Management Integration Tests"

   (test-case "Resource directory creation"
     (define test-cache-dir (ensure-resource-directory 'cache "test"))
     (check-true (directory-exists? test-cache-dir)
                 "Should create cache subdirectory"))

   (test-case "Symbol library validation"
     (check-true (validate-symbol-library)
                 "Symbol library should validate successfully"))

   (test-case "Complete environment validation"
     ;; This test checks that all major components work together
     (with-handlers ([exn:fail? (λ (e)
                                  (printf "Environment validation failed: ~a~n"
                                          (exn-message e))
                                  #f)])
       ;; Test path resolution
       (define lib-path (resolve-resource-path 'lib))
       (check-true (directory-exists? lib-path) "Lib directory should exist")

       ;; Test Saxon if available
       (when (file-exists? saxon-jar-path)
         (check-true (test-saxon-installation) "Saxon should be properly installed"))

       ;; Test symbol rendering
       (check-string? (render-symbol "k") "Should render basic symbols")

       ;; Test Java detection
       (define java-info (validate-java-installation))
       (when (hash-ref java-info 'java-found)
         (check-true (hash-ref java-info 'compatible #f) "Java should be compatible"))

       #t))))

;; Helper function to run all tests
(define (run-resource-management-tests)
  "Run all resource management integration tests"
  (displayln "Running Knotty DSL Resource Management Tests...")
  (displayln "============================================")

  (displayln "\n1. Testing Saxon XSLT Integration...")
  (run-tests saxon-tests)

  (displayln "\n2. Testing Font and Symbol Management...")
  (run-tests font-tests)

  (displayln "\n3. Testing Cross-Platform Path Resolution...")
  (run-tests path-tests)

  (displayln "\n4. Testing Complete Integration...")
  (run-tests integration-tests)

  (displayln "\n============================================")
  (displayln "Resource Management Tests Complete"))

;; Export the test runner for external use
(provide run-resource-management-tests
         saxon-tests
         font-tests
         path-tests
         integration-tests)

;; Run tests if this file is executed directly
(module+ main
  (run-resource-management-tests))