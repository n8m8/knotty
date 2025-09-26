#lang typed/racket
(require "knotty-lib/main.rkt")

;; Simple script to capture and analyze actual error messages

(printf "=== TESTING PATTERN VALIDATION ERRORS ===\n\n")

;; Test 1: Yarn not specified
(printf "Test 1: Using undefined yarn\n")
(let ([result-msg (with-handlers ([exn:fail? (λ (e) (exn-message e))])
                    (pattern
                     #:name "Test Pattern - Invalid Yarn"
                     #:technique 'hand
                     #:form 'flat
                     (yarn #x000000 "black")    ; Only define yarn 0
                     ((row 1) (cc1 k10))))])    ; Using yarn 1 (cc1) but only yarn 0 defined
  (printf "Error message: ~a\n\n" result-msg))

;; Test 2: Short row in first row
(printf "Test 2: Short row turn in first row\n")
(let ([result-msg (with-handlers ([exn:fail? (λ (e) (exn-message e))])
                    (pattern
                     #:name "Test - Invalid Short Row"
                     #:technique 'hand
                     #:form 'flat
                     ((row 1) k5 w&t k5)))])    ; Short row turn in first row (not allowed)
  (printf "Error message: ~a\n\n" result-msg))

;; Test 3: Non-conformable rows
(printf "Test 3: Non-conformable row stitch counts\n")
(let ([result-msg (with-handlers ([exn:fail? (λ (e) (exn-message e))])
                    (pattern
                     #:name "Test - Non-conformable Rows"
                     #:technique 'hand
                     #:form 'flat
                     ((row 1) k10)    ; Produces 10 stitches
                     ((row 2) p8)))])   ; Consumes only 8 stitches
  (printf "Error message: ~a\n\n" result-msg))

;; Test 4: Row repeat range error
(printf "Test 4: Invalid row repeat range\n")
(let ([result-msg (with-handlers ([exn:fail? (λ (e) (exn-message e))])
                    (pattern
                     #:name "Test - Invalid Row Repeats"
                     #:repeat-rows '(5 3)    ; last < first (invalid)
                     ((row 1) k10)
                     ((row 2) p10)
                     ((row 3) k10)))])
  (printf "Error message: ~a\n\n" result-msg))

(printf "=== ANALYZING ACTUAL ERROR MESSAGES ===\n\n")

;; Test existing validation issues by examining the codebase
(printf "ANALYZING ERROR MESSAGES FROM CODEBASE:\n\n")

;; Sample error messages found in the code
(let ([sample-messages
       (list
        "yarn is used that has not been specified in the pattern"
        "short rows are ony allowed in flat hand knits"  ; Note: typo "ony"
        "first row cannot contain a short row turn"
        "pattern rows 1 and 2 do not have conformable stitch counts"
        "row 2 cannot be aligned as it consumes more stitches than are available"
        "stitch cdd is not compatible with machine knitting"
        "non-conformable rows: row 1 produces 10 stitches, but row 2 consumes 8 stitches"
        "too many yarns specified"
        "error in row repeats"
        "pattern is not repeatable over the range of rows specified")])

  (for ([msg (in-list sample-messages)])
    (printf "Message: ~a\n" msg)
    (printf "Analysis: ")
    (cond
      [(string-contains? msg "ony")
       (printf "Contains spelling error - 'ony' should be 'only'\n")]
      [(string=? msg "error in row repeats")
       (printf "Too generic - doesn't explain what's wrong with repeats\n")]
      [(string-contains? msg "non-conformable")
       (printf "Good - specific with row numbers and stitch counts\n")]
      [(string-contains? msg "not compatible")
       (printf "Good - explains stitch/technique incompatibility\n")]
      [(string-contains? msg "specified")
       (printf "Good - clear about missing specification\n")]
      [else (printf "Standard quality\n")])
    (printf "\n")))

(printf "=== ERROR MESSAGE QUALITY ANALYSIS ===\n\n")

(printf "POSITIVE ASPECTS OBSERVED:\n")
(printf "1. Error messages are generally specific and factual\n")
(printf "2. Row numbers and stitch counts are included when relevant\n")
(printf "3. Context about knitting techniques is provided\n")
(printf "4. Pattern validation catches important structural errors\n")
(printf "5. Technical accuracy is maintained\n\n")

(printf "AREAS FOR IMPROVEMENT IDENTIFIED:\n")
(printf "1. SPELLING ERRORS: 'ony' should be 'only' in short row message\n")
(printf "2. GENERIC MESSAGES: Some errors lack specific details\n")
(printf "3. NO RECOVERY SUGGESTIONS: Messages don't suggest how to fix issues\n")
(printf "4. TECHNICAL JARGON: Terms like 'conformable' may confuse novices\n")
(printf "5. INCONSISTENT FORMAT: No standard error message structure\n")
(printf "6. MISSING CONTEXT: Some messages lack file/line information\n")
(printf "7. NO PROGRESSIVE DISCLOSURE: All details in one message\n\n")

(printf "RECOMMENDATIONS FOR IMPROVEMENT:\n")
(printf "1. FIX SPELLING: Review all error messages for typos\n")
(printf "2. STANDARDIZE FORMAT: Use '[CONTEXT]: [PROBLEM] - [SUGGESTION]' pattern\n")
(printf "3. ADD EXPLANATIONS: Include brief explanations of technical terms\n")
(printf "4. PROVIDE SOLUTIONS: Suggest common fixes or next steps\n")
(printf "5. IMPLEMENT ERROR CODES: Add codes for programmatic handling\n")
(printf "6. VALIDATE READABILITY: Test messages with novice users\n")
(printf "7. ADD HELP LINKS: Reference documentation or examples\n")
(printf "8. IMPROVE ACCESSIBILITY: Ensure messages work with screen readers\n\n")

(printf "SUGGESTED IMPROVED ERROR MESSAGES:\n\n")

(printf "BEFORE: 'yarn is used that has not been specified in the pattern'\n")
(printf "AFTER:  '[Row 1]: Yarn color 'cc1' is not defined - Add yarn definition or use 'mc' for main color'\n\n")

(printf "BEFORE: 'short rows are ony allowed in flat hand knits'\n")
(printf "AFTER:  '[Pattern Setup]: Short rows are only allowed in flat hand knitting - Change technique to 'hand' and form to 'flat', or remove short row turns'\n\n")

(printf "BEFORE: 'error in row repeats'\n")
(printf "AFTER:  '[Row Repeats]: Last repeat row (3) cannot be before first repeat row (5) - Use format #:repeat-rows '(first last)' with first ≤ last'\n\n")

(printf "BEFORE: 'stitch cdd is not compatible with machine knitting'\n")
(printf "AFTER:  '[Row 2]: Stitch 'cdd' (center double decrease) requires hand knitting - Change technique to 'hand' or replace with machine-compatible decreases'\n\n")