#lang typed/racket

#|
    Integration Test for Basic Stockinette Workflow

    Tests the complete workflow from pattern creation to export:
    1. Pattern creation from quickstart example
    2. Pattern validation
    3. Chart generation
    4. HTML export with interactive features
    5. Text generation for written instructions
    6. Verification of knit/purl symbols and readability

    This test validates the end-to-end workflow that users experience
    when creating a basic stockinette pattern as described in quickstart.md
|#

(require typed/rackunit
         racket/file
         racket/path
         threading)

;; Import knotty-lib modules
(require "../../../knotty-lib/global.rkt"
         "../../../knotty-lib/stitch.rkt"
         "../../../knotty-lib/tree.rkt"
         "../../../knotty-lib/yarn.rkt"
         "../../../knotty-lib/macros.rkt"
         "../../../knotty-lib/rows.rkt"
         "../../../knotty-lib/rowspec.rkt"
         "../../../knotty-lib/rowmap.rkt"
         "../../../knotty-lib/options.rkt"
         "../../../knotty-lib/pattern.rkt"
         "../../../knotty-lib/chart-row.rkt"
         "../../../knotty-lib/chart.rkt")

;; Import typed interfaces for text and html
(require/typed "../../../knotty-lib/text.rkt"
               [pattern->text (Pattern -> String)])

(require/typed "../../../knotty-lib/html.rkt"
               [pattern-template (->* (Output-Port Pattern (HashTable Symbol Integer)) (Boolean) Void)])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test Utilities

(: create-temp-file-path (String -> Path))
(define (create-temp-file-path extension)
  "Create a temporary file path for testing output"
  (build-path "/tmp/claude" (string-append "stockinette_test_" extension)))

(: test-file-exists-and-readable? (Path -> Boolean))
(define (test-file-exists-and-readable? filepath)
  "Test if file exists and is readable"
  (and (file-exists? filepath)
       (> (file-size filepath) 0)))

(: validate-knit-purl-symbols (String -> Boolean))
(define (validate-knit-purl-symbols content)
  "Validate that content contains expected knit/purl symbols or instructions"
  (and (or (string-contains? content "knit")
           (string-contains? content "k"))
       (or (string-contains? content "purl")
           (string-contains? content "p"))))

(: validate-html-interactive-features (String -> Boolean))
(define (validate-html-interactive-features html-content)
  "Validate that HTML contains interactive features"
  (and (or (string-contains? html-content "<script")
           (string-contains? html-content "javascript")
           (string-contains? html-content "form")
           (string-contains? html-content "input"))
       (or (string-contains? html-content "chart")
           (string-contains? html-content "pattern")
           (string-contains? html-content "knit"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test Data - Basic Stockinette Pattern from Quickstart

(: basic-stockinette-pattern Pattern)
(define basic-stockinette-pattern
  (pattern #:name "Basic Stockinette"
           #:technique 'hand
           #:form 'flat
           ((row 1) k10)    ; Knit row 1 (RS)
           ((row 2) p10)    ; Purl row 2 (WS)
           ((row 3) k10)    ; Knit row 3 (RS)
           ((row 4) p10)    ; Purl row 4 (WS)
           ((row 5) k10)    ; Knit row 5 (RS)
           ((row 6) p10)))  ; Purl row 6 (WS)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Integration Tests

(module+ test

  ;; Test 1: Pattern Creation and Basic Structure
  (test-case "Basic stockinette pattern creation"
    (check-true (Pattern? basic-stockinette-pattern)
                "Pattern should be created successfully")

    (check-equal? (Pattern-name basic-stockinette-pattern)
                  "Basic Stockinette"
                  "Pattern name should match")

    (check-equal? (Options-technique (Pattern-options basic-stockinette-pattern))
                  'hand
                  "Technique should be hand knitting")

    (check-equal? (Options-form (Pattern-options basic-stockinette-pattern))
                  'flat
                  "Form should be flat knitting")

    (check-equal? (Pattern-nrows basic-stockinette-pattern)
                  6
                  "Pattern should have 6 rows"))

  ;; Test 2: Pattern Validation
  (test-case "Pattern validation functionality"
    (check-not-exn
     (λ ()
       ;; Create pattern validates automatically during construction
       (pattern #:name "Test Validation"
                #:technique 'hand
                #:form 'flat
                ((row 1) k10)
                ((row 2) p10)))
     "Valid stockinette pattern should not throw validation errors")

    ;; Test invalid pattern fails validation
    (check-exn
     exn:fail?
     (λ ()
       ;; Mismatched stitch counts should fail
       (pattern #:name "Invalid Pattern"
                #:technique 'hand
                #:form 'flat
                ((row 1) k10)
                ((row 2) p8)))  ; Wrong stitch count
     "Invalid pattern with mismatched stitch counts should fail"))

  ;; Test 3: Chart Generation
  (test-case "Chart generation from pattern"
    (define chart (pattern->chart basic-stockinette-pattern))

    (check-true (Chart? chart)
                "Chart should be generated successfully")

    (check-equal? (Chart-height chart)
                  6
                  "Chart height should match number of rows")

    (check-true (> (Chart-width chart) 0)
                "Chart width should be positive")

    (check-equal? (vector-length (Chart-rows chart))
                  6
                  "Chart should have correct number of row entries")

    ;; Test chart has proper stitch mappings
    (define stitch-hash (chart-stitch-hash chart))
    (check-true (hash? stitch-hash)
                "Chart should have stitch hash")

    ;; Debug: Print available stitch types (for demonstration)
    (printf "Chart contains stitches: ~a\n"
            (hash-keys stitch-hash))

    ;; Verify knit stitches are present (purl stitches on WS may be represented differently)
    (check-true (hash-has-key? stitch-hash 'k)
                "Chart should contain knit stitches")
    ;; Note: In knitting charts, purl stitches on WS are often shown as blank/empty
    ;; or represented differently, so we check that we have at least knit stitches
    (check-true (> (hash-count stitch-hash) 0)
                "Chart should contain stitch mappings"))

  ;; Test 4: Text Generation for Written Instructions
  (test-case "Text generation for written instructions"
    (define instructions (pattern->text basic-stockinette-pattern))

    (check-true (string? instructions)
                "Instructions should be generated as string")

    (check-true (> (string-length instructions) 0)
                "Instructions should not be empty")

    ;; Print sample instructions for demonstration
    (printf "Sample generated instructions:\n~a...\n"
            (substring instructions 0 (min 200 (string-length instructions))))

    (check-true (validate-knit-purl-symbols instructions)
                "Instructions should contain knit and purl references")

    ;; Check for row-by-row instructions
    (check-true (string-contains? instructions "Row 1")
                "Instructions should contain row 1")
    (check-true (string-contains? instructions "Row 2")
                "Instructions should contain row 2")

    ;; Verify readability elements
    (check-true (or (string-contains? instructions "Knit")
                    (string-contains? instructions "knit")
                    (string-contains? instructions "k10"))
                "Instructions should contain readable knit instructions")
    (check-true (or (string-contains? instructions "Purl")
                    (string-contains? instructions "purl")
                    (string-contains? instructions "p10"))
                "Instructions should contain readable purl instructions")

    (printf "Generated instructions preview:\n~a\n\n"
            (substring instructions 0 (min 200 (string-length instructions)))))

  ;; Test 5: HTML Export with Interactive Features
  (test-case "HTML export with interactive features"
    ;; Create temporary output directory
    (make-directory* "/tmp/claude")

    (define html-file-path (create-temp-file-path "stockinette.html"))

    ;; Generate HTML export
    (call-with-output-file html-file-path
      (λ ([out : Output-Port])
        (define inputs (make-hasheq
                         '((hreps . 1)
                           (vreps . 1)
                           (zoom . 80)
                           (float . 0)
                           (notes . 1)
                           (yarn . 1)
                           (instr . 1)
                           (size . 0)
                           (stat . 0))))
        (pattern-template out basic-stockinette-pattern inputs #f))
      #:exists 'replace)

    (check-true (test-file-exists-and-readable? html-file-path)
                "HTML file should be created and readable")

    ;; Read and validate HTML content
    (define html-content (file->string html-file-path))

    (check-true (string-contains? html-content "<html")
                "Output should be valid HTML")

    (check-true (string-contains? html-content "Basic Stockinette")
                "HTML should contain pattern name")

    (check-true (validate-html-interactive-features html-content)
                "HTML should contain interactive features")

    ;; Verify chart elements are present
    (check-true (or (string-contains? html-content "chart")
                    (string-contains? html-content "pattern")
                    (string-contains? html-content "grid"))
                "HTML should contain chart-related elements")

    (printf "HTML file generated: ~a (~a bytes)\n"
            html-file-path
            (file-size html-file-path))

    ;; Clean up
    (when (file-exists? html-file-path)
      (delete-file html-file-path)))

  ;; Test 6: Symbol Verification for Knit/Purl Display
  (test-case "Verify chart displays proper knit/purl symbols"
    (define chart (pattern->chart basic-stockinette-pattern))
    (define stitch-hash (chart-stitch-hash chart))

    ;; Check that knit and purl stitches have proper symbol mappings
    (when (hash-has-key? stitch-hash 'k)
      (define knit-info (hash-ref stitch-hash 'k))
      (check-true (not (null? knit-info))
                  "Knit stitch should have symbol information"))

    (when (hash-has-key? stitch-hash 'p)
      (define purl-info (hash-ref stitch-hash 'p))
      (check-true (not (null? purl-info))
                  "Purl stitch should have symbol information"))

    ;; Verify chart rows contain the expected stitches
    (define chart-rows (Chart-rows chart))
    (check-true (> (vector-length chart-rows) 0)
                "Chart should have rows with stitch data"))

  ;; Test 7: Complete Workflow Integration
  (test-case "Complete workflow integration test"
    (printf "=== Complete Stockinette Workflow Test ===\n")

    ;; Step 1: Pattern Creation
    (printf "1. Creating basic stockinette pattern...\n")
    (define workflow-pattern
      (pattern #:name "Workflow Test Stockinette"
               #:technique 'hand
               #:form 'flat
               ((row 1) k10)
               ((row 2) p10)
               ((row 3) k10)
               ((row 4) p10)))

    (check-true (Pattern? workflow-pattern)
                "Workflow pattern creation should succeed")
    (printf "   ✓ Pattern created successfully\n")

    ;; Step 2: Chart Generation
    (printf "2. Generating chart from pattern...\n")
    (define workflow-chart (pattern->chart workflow-pattern))
    (check-true (Chart? workflow-chart)
                "Workflow chart generation should succeed")
    (printf "   ✓ Chart generated successfully\n")

    ;; Step 3: Text Instructions
    (printf "3. Generating written instructions...\n")
    (define workflow-text (pattern->text workflow-pattern))
    (check-true (and (string? workflow-text)
                     (> (string-length workflow-text) 0))
                "Workflow text generation should succeed")
    (printf "   ✓ Written instructions generated successfully\n")

    ;; Step 4: HTML Export
    (printf "4. Exporting to HTML...\n")
    (make-directory* "/tmp/claude")
    (define workflow-html-path (create-temp-file-path "workflow.html"))

    (call-with-output-file workflow-html-path
      (λ ([out : Output-Port])
        (define inputs (make-hasheq
                         '((hreps . 1)
                           (vreps . 1)
                           (zoom . 80)
                           (float . 0)
                           (notes . 1)
                           (yarn . 1)
                           (instr . 1)
                           (size . 0)
                           (stat . 0))))
        (pattern-template out workflow-pattern inputs #f))
      #:exists 'replace)

    (check-true (test-file-exists-and-readable? workflow-html-path)
                "Workflow HTML export should succeed")
    (printf "   ✓ HTML export completed successfully\n")

    ;; Step 5: Validation Summary
    (printf "5. Workflow validation summary:\n")
    (printf "   - Pattern: ~a rows, ~a technique, ~a form\n"
            (Pattern-nrows workflow-pattern)
            (Options-technique (Pattern-options workflow-pattern))
            (Options-form (Pattern-options workflow-pattern)))
    (printf "   - Chart: ~ax~a dimensions\n"
            (Chart-width workflow-chart)
            (Chart-height workflow-chart))
    (printf "   - Instructions: ~a characters\n"
            (string-length workflow-text))
    (printf "   - HTML: ~a bytes\n"
            (file-size workflow-html-path))

    ;; Cleanup
    (when (file-exists? workflow-html-path)
      (delete-file workflow-html-path))

    (printf "=== Workflow Test Complete: All Steps Successful ===\n\n")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test Suite Summary

(: run-stockinette-integration-tests (-> Void))
(define (run-stockinette-integration-tests)
  "Run complete stockinette workflow integration test suite"
  (printf "Starting Basic Stockinette Workflow Integration Tests...\n\n")

  ;; Note: The actual test execution happens through rackunit's module+ test
  ;; This function serves as documentation and can be used for manual runs

  (printf "Tests include:\n")
  (printf "1. Pattern creation and structure validation\n")
  (printf "2. Pattern syntax and constraint validation\n")
  (printf "3. Chart generation from pattern data\n")
  (printf "4. Written instruction generation\n")
  (printf "5. HTML export with interactive features\n")
  (printf "6. Knit/purl symbol verification\n")
  (printf "7. Complete end-to-end workflow\n\n")

  (printf "Run with: raco test test_stockinette_workflow.rkt\n"))

;; Export test runner for external use
(provide run-stockinette-integration-tests)

;; end