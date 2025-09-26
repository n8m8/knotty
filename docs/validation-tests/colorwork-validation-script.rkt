#lang typed/racket

;; Colorwork Pattern Validation Script
;; T027: Execute quickstart Example 2 (Colorwork Pattern) and validate color accuracy

(require "knotty-lib/main.rkt")
(require racket/file)
(require racket/string)

;; Test color definitions (hex values as specified in quickstart)
(define red-color-hex "#FF0000")
(define blue-color-hex "#0000FF")

;; Create yarns with the exact colors from quickstart
(define red-yarn (yarn #xFF0000 "Red"))
(define blue-yarn (yarn #x0000FF "Blue"))

;; Create the exact colorwork pattern from quickstart
(define simple-stripes
  (pattern
    ((row 1) (k 8))      ; Row 1: knit 8 in red
    ((row 2) (p 8))      ; Row 2: purl 8 in red
    ((row 3) (cc1 (k 8))) ; Row 3: knit 8 in blue
    ((row 4) (cc1 (p 8))) ; Row 4: purl 8 in blue
    red-yarn    ; MC (main color)
    blue-yarn   ; CC1 (contrast color 1)
    ))

;; Validation Functions

(: validate-pattern-structure (Pattern -> Boolean))
(define (validate-pattern-structure p)
  "Validate that the pattern was created correctly"
  (and (Pattern? p)
       (= 4 (Pattern-nrows p))
       (= 2 (vector-length (Pattern-yarns p)))))

(: validate-yarn-colors (Pattern -> Boolean))
(define (validate-yarn-colors p)
  "Validate that yarn colors are preserved correctly"
  (let ([yarns (Pattern-yarns p)])
    (and (= #xFF0000 (Yarn-color (vector-ref yarns 0)))  ; MC should be red
         (= #x0000FF (Yarn-color (vector-ref yarns 1)))  ; CC1 should be blue
         (equal? "Red" (Yarn-name (vector-ref yarns 0)))
         (equal? "Blue" (Yarn-name (vector-ref yarns 1))))))

(: validate-html-color-accuracy (String -> Boolean))
(define (validate-html-color-accuracy html-content)
  "Validate color accuracy in HTML output"
  (let ([red-count (length (regexp-match* #rx"#FF0000" html-content))]
        [blue-count (length (regexp-match* #rx"#0000FF" html-content))])
    (and (> red-count 0)   ; Red color appears in HTML
         (> blue-count 0)  ; Blue color appears in HTML
         (string-contains? html-content "Red")   ; Red yarn name appears
         (string-contains? html-content "Blue") ; Blue yarn name appears
         (string-contains? html-content "MC")   ; Main color abbreviation
         (string-contains? html-content "CC1")))) ; Contrast color abbreviation

(: validate-chart-elements (String -> Boolean))
(define (validate-chart-elements html-content)
  "Validate chart-specific elements in HTML"
  (and (string-contains? html-content "bgcolor=\"#FF0000\"")  ; Red background colors
       (string-contains? html-content "bgcolor=\"#0000FF\"")  ; Blue background colors
       (string-contains? html-content "Yarn: MC")             ; Yarn tooltips
       (string-contains? html-content "Yarn: CC1")            ; Yarn tooltips
       (string-contains? html-content "title=\"Yarn:")))      ; Yarn information in tooltips

(: validate-color-legend (String -> Boolean))
(define (validate-color-legend html-content)
  "Validate color legend in HTML"
  (and (string-contains? html-content "yarn_panel")           ; Yarn panel exists
       (string-contains? html-content "background-color: #FF0000") ; Red color block
       (string-contains? html-content "background-color: #0000FF") ; Blue color block
       (string-contains? html-content "main color")           ; MC description
       (string-contains? html-content "contrast color 1")))   ; CC1 description

(: run-comprehensive-validation (-> Void))
(define (run-comprehensive-validation)
  "Run comprehensive validation of colorwork functionality"

  (printf "=== KNOTTY COLORWORK VALIDATION TEST (T027) ===\n\n")

  ;; 1. Validate Pattern Creation
  (printf "1. Pattern Structure Validation:\n")
  (let ([structure-valid? (validate-pattern-structure simple-stripes)])
    (printf "   - Pattern created: ~a\n" (if structure-valid? "✓ PASS" "✗ FAIL"))
    (printf "   - Row count: ~a (expected: 4)\n" (Pattern-nrows simple-stripes))
    (printf "   - Yarn count: ~a (expected: 2)\n" (vector-length (Pattern-yarns simple-stripes))))

  ;; 2. Validate Yarn Color Definitions
  (printf "\n2. Yarn Color Validation:\n")
  (let* ([yarns (Pattern-yarns simple-stripes)]
         [red-yarn-actual (vector-ref yarns 0)]
         [blue-yarn-actual (vector-ref yarns 1)]
         [colors-valid? (validate-yarn-colors simple-stripes)])
    (printf "   - Color preservation: ~a\n" (if colors-valid? "✓ PASS" "✗ FAIL"))
    (printf "   - MC color: #~a (expected: #FF0000)\n" (string-upcase (number->string (Yarn-color red-yarn-actual) 16)))
    (printf "   - CC1 color: #~a (expected: #0000FF)\n" (string-upcase (number->string (Yarn-color blue-yarn-actual) 16)))
    (printf "   - MC name: ~a (expected: Red)\n" (Yarn-name red-yarn-actual))
    (printf "   - CC1 name: ~a (expected: Blue)\n" (Yarn-name blue-yarn-actual)))

  ;; 3. Generate Chart and Validate
  (printf "\n3. Chart Generation:\n")
  (let ([chart (pattern->chart simple-stripes)])
    (printf "   - Chart created: ~a\n" (if (Chart? chart) "✓ PASS" "✗ FAIL"))
    (printf "   - Chart width: ~a stitches\n" (Chart-width chart))
    (printf "   - Chart height: ~a rows\n" (Chart-height chart))
    (printf "   - Chart yarns: ~a\n" (vector-length (Chart-yarns chart))))

  ;; 4. Export HTML and Validate Color Accuracy
  (printf "\n4. HTML Export Validation:\n")
  (export-html simple-stripes "validation-output.html")
  (let ([html-content (file->string "validation-output.html")])
    (printf "   - HTML file created: ~a\n"
            (if (file-exists? "validation-output.html") "✓ PASS" "✗ FAIL"))
    (printf "   - File size: ~a bytes\n" (file-size "validation-output.html"))

    ;; 5. Validate HTML Color Accuracy
    (printf "\n5. HTML Color Accuracy:\n")
    (let ([color-accuracy? (validate-html-color-accuracy html-content)])
      (printf "   - Color hex values preserved: ~a\n" (if color-accuracy? "✓ PASS" "✗ FAIL"))
      (printf "   - Red (#FF0000) occurrences: ~a\n"
              (length (regexp-match* #rx"#FF0000" html-content)))
      (printf "   - Blue (#0000FF) occurrences: ~a\n"
              (length (regexp-match* #rx"#0000FF" html-content))))

    ;; 6. Validate Chart Elements
    (printf "\n6. Chart Visual Elements:\n")
    (let ([chart-elements? (validate-chart-elements html-content)])
      (printf "   - Chart color backgrounds: ~a\n" (if chart-elements? "✓ PASS" "✗ FAIL"))
      (printf "   - Yarn tooltips present: ~a\n"
              (if (string-contains? html-content "Yarn: MC") "✓ PASS" "✗ FAIL"))
      (printf "   - Stitch information: ~a\n"
              (if (string-contains? html-content "Knit") "✓ PASS" "✗ FAIL")))

    ;; 7. Validate Color Legend
    (printf "\n7. Color Legend Validation:\n")
    (let ([legend-valid? (validate-color-legend html-content)])
      (printf "   - Color legend present: ~a\n" (if legend-valid? "✓ PASS" "✗ FAIL"))
      (printf "   - Color blocks in legend: ~a\n"
              (if (string-contains? html-content "colorblock") "✓ PASS" "✗ FAIL"))
      (printf "   - Yarn abbreviations: ~a\n"
              (if (and (string-contains? html-content "MC")
                       (string-contains? html-content "CC1")) "✓ PASS" "✗ FAIL"))))

  ;; 8. Generate Text Instructions
  (printf "\n8. Text Instructions:\n")
  (let ([text-output (pattern->text simple-stripes)])
    (printf "   - Text generation: ~a\n" (if (string? text-output) "✓ PASS" "✗ FAIL"))
    (printf "   - Contains row information: ~a\n"
            (if (string-contains? text-output "Row") "✓ PASS" "✗ FAIL"))
    (printf "   - Contains yarn references: ~a\n"
            (if (string-contains? text-output "MC") "✓ PASS" "✗ FAIL")))

  ;; Summary
  (printf "\n=== VALIDATION SUMMARY ===\n")
  (let ([all-validations (list
                          (validate-pattern-structure simple-stripes)
                          (validate-yarn-colors simple-stripes)
                          (Chart? (pattern->chart simple-stripes))
                          (file-exists? "validation-output.html")
                          (validate-html-color-accuracy (file->string "validation-output.html"))
                          (validate-chart-elements (file->string "validation-output.html"))
                          (validate-color-legend (file->string "validation-output.html")))])
    (let ([pass-count (length (filter identity all-validations))]
          [total-count (length all-validations)])
      (printf "Tests passed: ~a/~a\n" pass-count total-count)
      (printf "Success rate: ~a%%\n" (* 100.0 (/ pass-count total-count)))
      (printf "Overall result: ~a\n"
              (if (= pass-count total-count) "✓ ALL TESTS PASSED" "✗ SOME TESTS FAILED"))))

  (printf "\n=== QUICKSTART EXAMPLE 2 VALIDATION COMPLETE ===\n"))

;; Run the validation
(run-comprehensive-validation)