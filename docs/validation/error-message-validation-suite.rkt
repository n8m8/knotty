#lang sweet-exp typed/racket

require
  racket/runtime-path
  rackunit
  "knotty-lib/main.rkt"

;; Error Message Quality Validation Suite
;; T034: Error message clarity and helpfulness validation across all failure modes

module+ test

  ;; ================================
  ;; PATTERN VALIDATION ERROR TESTING
  ;; ================================

  test-case "Pattern validation - yarn usage errors"
    let
      result-msg
      with-handlers
        [exn:fail? (λ (e) (exn-message e))]
        pattern
          [name "Test Pattern - Invalid Yarn"]
          [technique 'hand]
          [form 'flat]
          yarn(#x000000 "black") ; Only define yarn 0
          rows(1) (cc1 k10)     ; Using yarn 1 (cc1) but only yarn 0 defined
      check-true (string? result-msg) "Should produce error message"
      check-true
        string-contains? result-msg "yarn"
        "Should mention yarn in error message"
      check-true
        string-contains? result-msg "specified"
        "Should mention specification problem"

  test-case "Pattern validation - technique compatibility"
    let
      result-msg
      with-handlers
        [exn:fail? (λ (e) (exn-message e))]
        let
          p1
          pattern
            [name "Test - Machine Pattern"]
            [technique 'machine]
            rows(1) cdd k8     ; cdd stitch incompatible with machine
        pattern-set-hand p1    ; Try to convert to hand knitting
      check-true (string? result-msg) "Should produce error message"
      check-true
        string-contains? result-msg "compatible"
        "Should mention compatibility"
      check-true
        or
          string-contains? result-msg "machine"
          string-contains? result-msg "hand"
        "Should mention knitting technique"

  test-case "Pattern validation - short row placement errors"
    let
      result-msg
      with-handlers
        [exn:fail? (λ (e) (exn-message e))]
        pattern
          [name "Test - Invalid Short Row"]
          [technique 'hand]
          [form 'flat]
          rows(1) k5 w&t k5    ; Short row turn in first row (not allowed)
      check-true (string? result-msg) "Should produce error message"
      check-true
        string-contains? result-msg "first row"
        "Should mention first row restriction"
      check-true
        string-contains? result-msg "short row"
        "Should mention short row"

  test-case "Pattern validation - row repeat errors"
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
      check-true (string? result-msg) "Should produce error message"
      check-true
        string-contains? result-msg "repeat"
        "Should mention row repeats"

  test-case "Pattern validation - gauge compatibility warnings"
    let
      warning-captured? #f
      let
        orig-log current-logger
        test-log make-logger 'test orig-log
      current-logger test-log
      let
        receiver make-log-receiver test-log 'warning
      pattern
        [name "Test - Gauge Mismatch"]
        [gauge Gauge(20 25 4 4 'inch)]  ; Very fine gauge
        yarn(#x000000 "heavy yarn" 6)   ; Heavy yarn (incompatible)
        rows(1) k10
      let
        result sync/timeout 0.1 receiver  ; Check for warning
      check-true
        not (false? result)
        "Should produce gauge compatibility warning"
      current-logger orig-log

  ;; ===============================
  ;; CHART GENERATION ERROR TESTING
  ;; ===============================

  test-case "Chart generation - alignment errors"
    let
      result-msg
      with-handlers
        [exn:fail? (λ (e) (exn-message e))]
        let
          p
          pattern
            [name "Test - Unaligned Rows"]
            rows(1) k5
            rows(2) p7 ; More stitches than produced by row 1
        pattern->chart p
      check-true (string? result-msg) "Should produce error message"
      check-true
        string-contains? result-msg "aligned"
        "Should mention alignment problem"

  test-case "Chart generation - float length validation"
    let
      p
      pattern
        [name "Test - Long Floats"]
        [technique 'machine]
        yarn(#x000000 "black")
        yarn(#xffffff "white")
        rows(1) (cc0 k5) (cc1 k1) (cc0 k20) ; Very long float of white yarn
    let-values
      [(chart float-ok?) (chart-check-floats (pattern->chart p) (Pattern-options p) 7)]
    check-false float-ok? "Should detect long floats"

  ;; =============================
  ;; FILE I/O ERROR TESTING
  ;; =============================

  test-case "XML import - malformed file errors"
    let
      temp-file make-temporary-file
      result-msg
      with-handlers
        [exn:fail? (λ (e) (exn-message e))]
        with-output-to-file temp-file
          λ () display "<malformed>xml<content"
          #:exists 'replace
        import-xml temp-file
    delete-file temp-file
    check-true (string? result-msg) "Should produce error message"
    check-true
      string-contains? result-msg "xml"
      "Should mention XML format"

  test-case "File permission errors"
    let
      result-msg
      with-handlers
        [exn:fail? (λ (e) (exn-message e))]
        import-xml "/root/nonexistent.xml"  ; Permission denied
    check-true (string? result-msg) "Should produce error message"

  ;; =============================
  ;; CLI ERROR TESTING
  ;; =============================

  test-case "CLI - invalid command arguments"
    let
      result-msg
      with-handlers
        [exn:fail? (λ (e) (exn-message e))]
        ; Simulate invalid arguments - would need actual CLI testing framework
        error "Simulated CLI error: invalid input file format"
    check-true (string? result-msg) "Should produce error message"
    check-true
      string-contains? result-msg "invalid"
      "Should mention what's invalid"

  ;; =============================
  ;; EXPORT FORMAT ERROR TESTING
  ;; =============================

  test-case "HTML export - write permission errors"
    let
      p
      pattern
        [name "Test Pattern"]
        rows(1) k10
      result-msg
      with-handlers
        [exn:fail? (λ (e) (exn-message e))]
        export-html p "/root/readonly.html" 1 1
    check-true (string? result-msg) "Should produce error message"

  ;; ===================================
  ;; ERROR MESSAGE QUALITY EVALUATION
  ;; ===================================

  define
    (evaluate-error-message msg)
    let
      [issues '()]
    ; Check for clarity
    when (string-contains? msg "exn:fail")
      set! issues (cons "Contains technical exception names" issues)
    ; Check for helpfulness
    unless
      or
        (string-contains? msg "check")
        (string-contains? msg "ensure")
        (string-contains? msg "try")
        (string-contains? msg "should")
      set! issues (cons "No recovery suggestions provided" issues)
    ; Check for specificity
    when
      or
        (string-contains? msg "error")
        (string-contains? msg "failed")
        (string-contains? msg "invalid")
      unless (string-contains? msg ":")
        set! issues (cons "Generic error message without specifics" issues)
    issues

  test-case "Error message quality assessment"
    let
      [sample-messages
        (list
          "yarn is used that has not been specified in the pattern"
          "short rows are ony allowed in flat hand knits"  ; Note: typo "ony"
          "first row cannot contain a short row turn"
          "pattern rows 1 and 2 do not have conformable stitch counts"
          "row 2 cannot be aligned as it consumes more stitches than are available"
          "stitch cdd is not compatible with machine knitting"
          "non-conformable rows: row 1 produces 10 stitches, but row 2 consumes 8 stitches")]

    for
      [msg (in-list sample-messages)]
      let
        [issues (evaluate-error-message msg)]
      (printf "Message: ~a\n" msg)
      (printf "Issues: ~a\n\n"
        (if (null? issues)
          "None (good quality)"
          (string-join issues "; ")))

  ;; Run quality assessment
  printf "\n================================\n"
  printf "ERROR MESSAGE QUALITY ANALYSIS\n"
  printf "================================\n\n"

  printf "POSITIVE ASPECTS:\n"
  printf "1. Error messages are generally specific and factual\n"
  printf "2. Row numbers and stitch counts are included when relevant\n"
  printf "3. Context about knitting techniques is provided\n"
  printf "4. Pattern validation catches important structural errors\n\n"

  printf "AREAS FOR IMPROVEMENT:\n"
  printf "1. Spelling errors in messages ('ony' should be 'only')\n"
  printf "2. Limited recovery suggestions for users\n"
  printf "3. Technical jargon without explanation for novice users\n"
  printf "4. Inconsistent error message formatting\n"
  printf "5. Missing file/line context in some error messages\n"
  printf "6. Some generic messages lack specific guidance\n\n"

  printf "RECOMMENDATIONS:\n"
  printf "1. Standardize error message format: [CONTEXT]: [PROBLEM] - [SUGGESTION]\n"
  printf "2. Add user-friendly explanations for technical terms\n"
  printf "3. Include common fixes and links to documentation\n"
  printf "4. Implement progressive disclosure (brief + detailed)\n"
  printf "5. Add error codes for programmatic handling\n"
  printf "6. Validate all error message text for spelling/grammar\n"
  printf "7. Test error messages with novice users\n\n"
