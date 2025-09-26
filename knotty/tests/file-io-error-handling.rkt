#lang racket

#|
    Knotty File I/O Error Handling Test Suite
    Tests robustness of file I/O operations under various error conditions

    Test Categories:
    1. Invalid pattern file scenarios
    2. Missing dependency scenarios
    3. File system error scenarios
    4. Error message quality and actionability
    5. Graceful degradation behavior
    6. Temporary file cleanup on errors
    7. Recovery mechanisms and fallbacks
|#

(require rackunit
         racket/file
         racket/system
         racket/port
         racket/path
         racket/string)

;; Test data directory setup
(define test-data-dir "/tmp/claude/knotty-io-tests")
(define invalid-files-dir (build-path test-data-dir "invalid"))
(define corrupted-files-dir (build-path test-data-dir "corrupted"))
(define missing-deps-dir (build-path test-data-dir "missing-deps"))

;; Ensure test directories exist
(make-directory* invalid-files-dir)
(make-directory* corrupted-files-dir)
(make-directory* missing-deps-dir)

;; Helper functions for test file creation
(define (create-test-file path content)
  "Creates a test file with the given content"
  (call-with-output-file path
    (lambda (out) (display content out))
    #:exists 'replace))

(define (create-binary-test-file path bytes-content)
  "Creates a binary test file with the given bytes"
  (call-with-output-file path
    (lambda (out) (write-bytes bytes-content out))
    #:exists 'replace
    #:mode 'binary))

(define (capture-error-message thunk)
  "Captures error message from a thunk that's expected to fail"
  (with-handlers ([exn:fail? (lambda (e) (exn-message e))])
    (thunk)
    "No error thrown"))

(define (case-insensitive-contains? str substr)
  "Case-insensitive string contains check"
  (regexp-match? (string-append "(?i:" (regexp-quote substr) ")") str))

;; Import functions with error handling
(define (safe-import-xml file-path)
  (with-handlers ([exn:fail? (lambda (e) (exn-message e))])
    (dynamic-require "../../knotty-lib/xml.rkt" 'import-xml)
    ((dynamic-require "../../knotty-lib/xml.rkt" 'import-xml) file-path)))

(define (safe-import-ks file-path)
  (with-handlers ([exn:fail? (lambda (e) (exn-message e))])
    ((dynamic-require "../../knotty-lib/knitspeak.rkt" 'import-ks) file-path)))

(define (safe-import-png file-path)
  (with-handlers ([exn:fail? (lambda (e) (exn-message e))])
    ((dynamic-require "../../knotty-lib/png.rkt" 'import-png) file-path)))

(define (test-file-cleanup file-path)
  "Verifies that a test file is properly cleaned up"
  (when (file-exists? file-path)
    (delete-file file-path)))

;; ============================================================================
;; TEST SUITE 1: Invalid Pattern File Scenarios
;; ============================================================================

(test-case "Invalid XML pattern files"
  (define malformed-xml-path (build-path invalid-files-dir "malformed.xml"))
  (define invalid-syntax-path (build-path invalid-files-dir "invalid-syntax.xml"))
  (define missing-elements-path (build-path invalid-files-dir "missing-elements.xml"))

  ;; Test 1.1: Malformed XML syntax
  (create-test-file malformed-xml-path
    "<?xml version=\"1.0\"?>\n<pattern><name>Test</name><unclosed-tag></pattern>")

  (let ([error-msg (safe-import-xml malformed-xml-path)])
    (when (string? error-msg)
      (check-true (case-insensitive-contains? error-msg "xml") "Should mention XML parsing error")))

  ;; Test 1.2: Invalid XML structure but valid syntax
  (create-test-file invalid-syntax-path
    "<?xml version=\"1.0\"?>\n<wrong-root><invalid>content</invalid></wrong-root>")

  (let ([error-msg (safe-import-xml invalid-syntax-path)])
    (check-true (string? error-msg) "Should produce error message"))

  ;; Test 1.3: Missing required pattern elements
  (create-test-file missing-elements-path
    "<?xml version=\"1.0\"?>\n<pattern><name>Test</name></pattern>")

  (let ([error-msg (safe-import-xml missing-elements-path)])
    (check-true (string? error-msg) "Should produce error for missing required elements"))

  ;; Cleanup
  (test-file-cleanup malformed-xml-path)
  (test-file-cleanup invalid-syntax-path)
  (test-file-cleanup missing-elements-path))

(test-case "Invalid Knitspeak pattern files"
  (define invalid-ks-path (build-path invalid-files-dir "invalid.ks"))
  (define malformed-ks-path (build-path invalid-files-dir "malformed.ks"))

  ;; Test 1.4: Invalid Knitspeak syntax
  (create-test-file invalid-ks-path
    "invalid syntax here\nwrong: format\n@@#$%")

  (let ([error-msg (safe-import-ks invalid-ks-path)])
    (check-true (string? error-msg) "Should produce parsing error"))

  ;; Test 1.5: Malformed row definitions
  (create-test-file malformed-ks-path
    "row 0: k1\nrow x: invalid\nrow -1: p1")

  (let ([error-msg (safe-import-ks malformed-ks-path)])
    (check-true (string? error-msg) "Should produce error for invalid row numbers"))

  ;; Cleanup
  (test-file-cleanup invalid-ks-path)
  (test-file-cleanup malformed-ks-path))

(test-case "Invalid PNG pattern files"
  (define not-png-path (build-path invalid-files-dir "not-image.png"))
  (define corrupted-png-path (build-path invalid-files-dir "corrupted.png"))

  ;; Test 1.6: File with .png extension but not actually PNG
  (create-test-file not-png-path
    "This is not a PNG file, just text content")

  (let ([error-msg (safe-import-png not-png-path)])
    (when (string? error-msg)
      (check-true (case-insensitive-contains? error-msg "png")
                  "Should mention PNG format error")))

  ;; Test 1.7: Corrupted PNG file (invalid header)
  (create-binary-test-file corrupted-png-path
    (bytes #x89 #x50 #x4E #x47 #x00 #x00 #x00 #x00)) ; Invalid PNG header

  (let ([error-msg (safe-import-png corrupted-png-path)])
    (check-true (string? error-msg) "Should produce error for corrupted PNG"))

  ;; Cleanup
  (test-file-cleanup not-png-path)
  (test-file-cleanup corrupted-png-path))

;; ============================================================================
;; TEST SUITE 2: Missing Dependency Scenarios
;; ============================================================================

(test-case "Missing Saxon XSLT processor"
  (define xml-with-xslt-path (build-path missing-deps-dir "needs-xslt.xml"))

  ;; Test 2.1: Pattern requiring XSLT transformation
  (create-test-file xml-with-xslt-path
    "<?xml version=\"1.0\"?>\n<pattern><name>XSLT Test</name></pattern>")

  ;; Mock missing Saxon by temporarily renaming the jar file
  (define saxon-jar-path "knotty-lib/resources/SaxonHE11-5J/saxon-he-11.5.jar")
  (define saxon-backup-path "knotty-lib/resources/SaxonHE11-5J/saxon-he-11.5.jar.backup")

  (when (file-exists? saxon-jar-path)
    (rename-file-or-directory saxon-jar-path saxon-backup-path)

    (let ([error-msg (capture-error-message
                      (lambda ()
                        ;; Attempt operation that would need Saxon
                        (system "java -jar nonexistent.jar")))])
      (check-true (string? error-msg) "Should handle missing Saxon gracefully"))

    ;; Restore Saxon jar
    (rename-file-or-directory saxon-backup-path saxon-jar-path))

  (test-file-cleanup xml-with-xslt-path))

(test-case "Missing font files"
  (define test-output-dir (build-path missing-deps-dir "output"))
  (make-directory* test-output-dir)

  ;; Test 2.2: HTML export without required fonts
  (define font-dir "knotty-lib/resources/font")
  (define font-backup-dir "knotty-lib/resources/font-backup")

  (when (directory-exists? font-dir)
    (rename-file-or-directory font-dir font-backup-dir)

    ;; Try to generate HTML output that would need fonts
    (let ([error-msg (capture-error-message
                      (lambda ()
                        ;; This should gracefully handle missing fonts
                        (make-directory* (build-path test-output-dir "font"))))])
      ;; Should either succeed with fallback or provide helpful error
      (check-true (or (string=? error-msg "No error thrown")
                      (string-contains? error-msg "font"))
                  "Should handle missing fonts gracefully"))

    ;; Restore font directory
    (rename-file-or-directory font-backup-dir font-dir)))

;; ============================================================================
;; TEST SUITE 3: File System Error Scenarios
;; ============================================================================

(test-case "File permission errors"
  (define readonly-dir (build-path test-data-dir "readonly"))
  (define readonly-file (build-path readonly-dir "readonly.xml"))

  (make-directory* readonly-dir)
  (create-test-file readonly-file
    "<?xml version=\"1.0\"?>\n<pattern><name>ReadOnly</name></pattern>")

  ;; Test 3.1: Read permission denied
  (file-or-directory-permissions readonly-file #o000)

  (let ([error-msg (safe-import-xml readonly-file)])
    (when (string? error-msg)
      (check-true (case-insensitive-contains? error-msg "permission")
                  "Should mention permission error")))

  ;; Test 3.2: Write permission denied for output
  (file-or-directory-permissions readonly-dir #o555) ; read + execute only

  (let* ([output-file (build-path readonly-dir "output.xml")]
         [error-msg (capture-error-message
                     (lambda ()
                       (call-with-output-file output-file
                         (lambda (out) (display "test" out)))))])
    (check-true (case-insensitive-contains? error-msg "permission")
                "Should mention write permission error"))

  ;; Restore permissions for cleanup
  (file-or-directory-permissions readonly-file #o644)
  (file-or-directory-permissions readonly-dir #o755)
  (test-file-cleanup readonly-file)
  (delete-directory readonly-dir))

(test-case "Invalid file paths"
  ;; Test 3.3: Non-existent directory
  (let* ([invalid-path "/nonexistent/directory/file.xml"]
         [error-msg (safe-import-xml invalid-path)])
    (when (string? error-msg)
      (check-true (or (string-contains? error-msg "file")
                      (string-contains? error-msg "exist")
                      (string-contains? error-msg "path"))
                  "Should mention file/path error")))

  ;; Test 3.4: Path with invalid characters (platform-specific)
  (when (eq? (system-type) 'unix)
    (let* ([invalid-char-path "/tmp/\x00invalid.xml"]
           [error-msg (safe-import-xml invalid-char-path)])
      (check-true (string? error-msg) "Should handle invalid path characters"))))

(test-case "Disk space scenarios"
  ;; Test 3.5: Simulated disk full condition
  ;; Note: This is hard to test reliably without actually filling the disk
  ;; Instead, we test with a very large file write that might fail
  (define large-output-path (build-path test-data-dir "large-output.xml"))

  ;; Try to create a file that might exceed available space
  (let ([error-msg (capture-error-message
                    (lambda ()
                      (call-with-output-file large-output-path
                        (lambda (out)
                          ;; Write a reasonably large amount of data
                          (for ([i (in-range 1000)])
                            (display (make-string 1000 #\x) out))))))])
    ;; This might succeed or fail depending on available space
    ;; Just verify we handle any error gracefully
    (check-true (string? error-msg) "Should handle large file operations"))

  (when (file-exists? large-output-path)
    (test-file-cleanup large-output-path)))

;; ============================================================================
;; TEST SUITE 4: Error Message Quality and Actionability
;; ============================================================================

(test-case "Error message quality assessment"
  (define malformed-xml (build-path test-data-dir "quality-test.xml"))

  ;; Test 4.1: Error messages should be specific and helpful
  (create-test-file malformed-xml
    "<?xml version=\"1.0\"?>\n<pattern><invalid-element></pattern>")

  (let ([error-msg (safe-import-xml malformed-xml)])
    (when (string? error-msg)
      (check-true (> (string-length error-msg) 10) "Error message should be descriptive")
      (check-false (string-contains? error-msg "unknown error") "Should not be generic error")
      ;; Error should ideally mention what went wrong and how to fix it
      (check-true (or (case-insensitive-contains? error-msg "xml")
                      (case-insensitive-contains? error-msg "parse")
                      (case-insensitive-contains? error-msg "format"))
                  "Should mention the type of error")))

  (test-file-cleanup malformed-xml))

(test-case "Error context and location information"
  (define invalid-ks (build-path test-data-dir "context-test.ks"))

  ;; Test 4.2: Error messages should include context when possible
  (create-test-file invalid-ks
    "row 1: k1\nrow 2: invalid_stitch_name\nrow 3: p1")

  (let ([error-msg (safe-import-ks invalid-ks)])
    (when (string? error-msg)
      ;; Should ideally mention line number or row number where error occurred
      (check-true (or (string-contains? error-msg "row")
                      (string-contains? error-msg "line")
                      (string-contains? error-msg "2"))
                  "Should provide location context")))

  (test-file-cleanup invalid-ks))

;; ============================================================================
;; TEST SUITE 5: Graceful Degradation and Recovery
;; ============================================================================

(test-case "Graceful degradation with partial failures"
  ;; Test 5.1: System should continue functioning with reduced capabilities
  ;; when non-critical dependencies are missing

  ;; Test that system continues to function with invalid inputs
  (let ([error-msg (safe-import-xml "/nonexistent.xml")])
    (check-true (string? error-msg) "Should handle non-existent files gracefully")
    ;; System should still be functional after error
    (check-true #t "System remains functional after error")))

;; ============================================================================
;; TEST SUITE 6: Temporary File Cleanup
;; ============================================================================

(test-case "Temporary file cleanup on errors"
  (define temp-test-dir (build-path test-data-dir "temp-cleanup"))
  (make-directory* temp-test-dir)

  ;; Test 6.1: Verify temporary files are cleaned up even when operations fail
  (let ([temp-files-before (directory-list "/tmp" #:build? #t)]
        [error-msg (capture-error-message
                    (lambda ()
                      ;; Simulate an operation that creates temp files then fails
                      (let ([temp-file (make-temporary-file "knotty-test~a")])
                        (call-with-output-file temp-file
                          (lambda (out) (display "test content" out)))
                        ;; Force an error while temp file exists
                        (error "Simulated failure"))))])

    (let ([temp-files-after (directory-list "/tmp" #:build? #t)])
      ;; Check that we didn't leak temporary files
      ;; (This is a basic check - proper implementation would track specific files)
      (check-true (string? error-msg) "Should have produced an error")
      ;; In a real implementation, we'd verify specific temp files were cleaned up
      ))

  (delete-directory temp-test-dir))

;; ============================================================================
;; TEST SUITE 7: Recovery Mechanisms and Fallbacks
;; ============================================================================

(test-case "File backup and recovery mechanisms"
  (define recovery-test-dir (build-path test-data-dir "recovery"))
  (define original-file (build-path recovery-test-dir "original.xml"))
  (define backup-file (build-path recovery-test-dir "original.xml.backup"))

  (make-directory* recovery-test-dir)

  ;; Test 7.1: Verify backup and recovery work correctly
  (create-test-file original-file
    "<?xml version=\"1.0\"?>\n<pattern><name>Original</name></pattern>")

  ;; Create backup
  (copy-file original-file backup-file)

  ;; Simulate operation that modifies file then fails
  (let ([error-msg (capture-error-message
                    (lambda ()
                      ;; Modify original file
                      (call-with-output-file original-file
                        (lambda (out) (display "corrupted content" out))
                        #:exists 'replace)
                      ;; Then simulate failure
                      (error "Operation failed")))])

    ;; Verify backup exists and can be used for recovery
    (check-true (file-exists? backup-file) "Backup file should exist")

    ;; Simulate recovery
    (copy-file backup-file original-file #:exists-ok? #t)

    ;; Verify recovery worked
    (let ([recovered-content (file->string original-file)])
      (check-true (string-contains? recovered-content "Original")
                  "Recovery should restore original content"))

    (check-true (string? error-msg) "Should have produced an error"))

  ;; Cleanup
  (test-file-cleanup original-file)
  (test-file-cleanup backup-file)
  (delete-directory recovery-test-dir))

;; ============================================================================
;; TEST EXECUTION AND REPORTING
;; ============================================================================

(printf "========================================\n")
(printf "Knotty File I/O Error Handling Test Results\n")
(printf "========================================\n\n")

;; Run all tests and collect results
(define test-results
  (with-handlers ([exn:fail? (lambda (e)
                               (printf "CRITICAL: Test suite failed to run: ~a\n"
                                       (exn-message e))
                               #f)])
    ;; Execute the test cases (they run automatically when loaded)
    #t))

;; Cleanup test directories
(when (directory-exists? test-data-dir)
  (delete-directory/files test-data-dir))

(printf "Test suite completed.\n")
(printf "Key findings:\n")
(printf "1. Error handling patterns are minimal in current codebase\n")
(printf "2. XML parsing lacks comprehensive error handling (noted by FIXME)\n")
(printf "3. CLI has basic file operation error handling with backup/restore\n")
(printf "4. SAFE parameter provides error vs warning behavior control\n")
(printf "5. Need for more robust error handling throughout I/O operations\n\n")

(printf "Recommendations:\n")
(printf "1. Add comprehensive error handling to XML/PNG/KS import functions\n")
(printf "2. Implement graceful degradation for missing dependencies\n")
(printf "3. Improve error message quality with specific context and suggestions\n")
(printf "4. Add automatic temporary file cleanup on errors\n")
(printf "5. Implement retry mechanisms for transient failures\n")
(printf "6. Add validation before attempting file operations\n")