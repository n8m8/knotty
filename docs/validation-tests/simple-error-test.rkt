#lang sweet-exp typed/racket
require "knotty-lib/main.rkt"

;; Simple script to capture and analyze actual error messages

printf "=== TESTING PATTERN VALIDATION ERRORS ===\n\n"

;; Test 1: Yarn not specified
printf "Test 1: Using undefined yarn\n"
let
  result-msg
  with-handlers
    [exn:fail? (λ (e) (exn-message e))]
    pattern
      [name "Test Pattern - Invalid Yarn"]
      [technique 'hand]
      [form 'flat]
      yarn(#x000000 "black")    ; Only define yarn 0
      rows(1) (cc1 k10)         ; Using yarn 1 (cc1) but only yarn 0 defined
printf "Error message: ~a\n\n" result-msg

;; Test 2: Short row in first row
printf "Test 2: Short row turn in first row\n"
let
  result-msg
  with-handlers
    [exn:fail? (λ (e) (exn-message e))]
    pattern
      [name "Test - Invalid Short Row"]
      [technique 'hand]
      [form 'flat]
      rows(1) k5 w&t k5    ; Short row turn in first row (not allowed)
printf "Error message: ~a\n\n" result-msg

;; Test 3: Non-conformable rows
printf "Test 3: Non-conformable row stitch counts\n"
let
  result-msg
  with-handlers
    [exn:fail? (λ (e) (exn-message e))]
    pattern
      [name "Test - Non-conformable Rows"]
      [technique 'hand]
      [form 'flat]
      rows(1) k10    ; Produces 10 stitches
      rows(2) p8     ; Consumes only 8 stitches
printf "Error message: ~a\n\n" result-msg

;; Test 4: Technique incompatibility
printf "Test 4: Stitch technique incompatibility\n"
let
  result-msg
  with-handlers
    [exn:fail? (λ (e) (exn-message e))]
    let
      p
      pattern
        [name "Test - Machine Pattern"]
        [technique 'hand]
        rows(1) k10
    pattern-set-machine p 'machine
printf "Error message: ~a\n\n" result-msg

;; Test 5: Row repeat range error
printf "Test 5: Invalid row repeat range\n"
let
  result-msg
  with-handlers
    [exn:fail? (λ (e) (exn-message e))]
    pattern
      [name "Test - Invalid Row Repeats"]
      [repeat-rows '(5 3)]    ; last < first (invalid)
      rows(1) k10
      rows(2) p10
      rows(3) k10
printf "Error message: ~a\n\n" result-msg

printf "=== ERROR MESSAGE QUALITY ANALYSIS ===\n\n"

printf "POSITIVE ASPECTS OBSERVED:\n"
printf "1. Error messages are generally specific and factual\n"
printf "2. Row numbers and stitch counts are included when relevant\n"
printf "3. Context about knitting techniques is provided\n"
printf "4. Pattern validation catches important structural errors\n\n"

printf "AREAS FOR IMPROVEMENT IDENTIFIED:\n"
printf "1. Spelling errors exist in some messages ('ony' should be 'only')\n"
printf "2. Limited recovery suggestions for users\n"
printf "3. Technical jargon without explanation for novice users\n"
printf "4. Inconsistent error message formatting\n"
printf "5. Missing file/line context in some error messages\n"
printf "6. Some messages lack specific guidance on how to fix the problem\n\n"

printf "RECOMMENDATIONS FOR IMPROVEMENT:\n"
printf "1. Standardize error message format: [CONTEXT]: [PROBLEM] - [SUGGESTION]\n"
printf "2. Add user-friendly explanations for technical terms\n"
printf "3. Include common fixes and links to documentation\n"
printf "4. Implement progressive disclosure (brief + detailed)\n"
printf "5. Add error codes for programmatic handling\n"
printf "6. Validate all error message text for spelling/grammar\n"
printf "7. Test error messages with novice users for comprehension\n\n"