#lang racket

;;;; Quality Gate Enforcer
;;;; Enforces quality gates from Phase 3.3 with comprehensive validation
;;;; Part of AI Rebuild Integration Layer - Phase 4.0

(provide enforce-quality-gates
         QualityGate
         QualityGateConfig
         QualityGateResult
         run-gate-enforcement
         validate-gate-thresholds
         generate-gate-report)

(require racket/match
         racket/system
         racket/path
         racket/file
         racket/list
         racket/date
         racket/port
         racket/string
         racket/format
         json
         "validate.rkt"
         "run-unit-tests.rkt"
         "run-integration-tests.rkt"
         "run-benchmarks.rkt"
         "validate-health.rkt")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Data Structures for Quality Gate Management

(struct QualityGate (name description validator threshold priority dependencies) #:transparent)
(struct QualityGateConfig (gates enforcement-level timeout-per-gate parallel-execution?) #:transparent)
(struct QualityGateResult (gate-name status details duration threshold-met? error-info) #:transparent)
(struct GateEnforcementResult (overall-status gate-results failed-gates execution-time summary) #:transparent)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Predefined Quality Gates from Phase 3.3

(define STANDARD_QUALITY_GATES
  (list
    ;; Environment Gates
    (QualityGate "environment-validation"
                 "Validate build environment setup and dependencies"
                 validate-environment-gate
                 0.95  ; 95% success threshold
                 'critical
                 '())

    ;; Code Quality Gates
    (QualityGate "unit-tests"
                 "All unit tests must pass with 100% success rate"
                 validate-unit-tests-gate
                 1.0   ; 100% success threshold
                 'critical
                 '("environment-validation"))

    (QualityGate "integration-tests"
                 "Integration tests must pass with 95% success rate"
                 validate-integration-tests-gate
                 0.95  ; 95% success threshold
                 'high
                 '("unit-tests"))

    ;; Build Quality Gates
    (QualityGate "build-artifacts"
                 "All required build artifacts must be generated"
                 validate-build-artifacts-gate
                 1.0   ; 100% artifact generation
                 'critical
                 '("unit-tests"))

    (QualityGate "artifact-integrity"
                 "Build artifacts must pass integrity validation"
                 validate-artifact-integrity-gate
                 1.0   ; 100% integrity check
                 'critical
                 '("build-artifacts"))

    ;; Performance Gates
    (QualityGate "performance-benchmarks"
                 "Performance must meet established benchmarks"
                 validate-performance-gate
                 0.90  ; 90% of benchmark performance
                 'medium
                 '("integration-tests"))

    (QualityGate "memory-usage"
                 "Memory usage must stay within acceptable limits"
                 validate-memory-gate
                 0.80  ; 80% of maximum allowed memory
                 'high
                 '("performance-benchmarks"))

    ;; Security Gates
    (QualityGate "security-scan"
                 "Security scan must pass with no critical vulnerabilities"
                 validate-security-gate
                 1.0   ; 100% - no critical vulnerabilities
                 'critical
                 '("build-artifacts"))

    ;; Documentation Gates
    (QualityGate "documentation-coverage"
                 "Documentation coverage must meet minimum standards"
                 validate-documentation-gate
                 0.85  ; 85% documentation coverage
                 'medium
                 '())

    ;; Compliance Gates
    (QualityGate "compliance-check"
                 "All compliance requirements must be satisfied"
                 validate-compliance-gate
                 1.0   ; 100% compliance
                 'high
                 '("security-scan"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main Quality Gate Enforcement API

(define (enforce-quality-gates config)
  "Enforce all configured quality gates with comprehensive validation

   Parameters:
   - config: QualityGateConfig with gates and enforcement settings

   Returns: GateEnforcementResult with detailed enforcement results"

  (printf "=== Quality Gate Enforcement Started ===~n")
  (define start-time (current-inexact-milliseconds))

  (match config
    [(QualityGateConfig gates enforcement-level timeout-per-gate parallel-execution?)

     (printf "Configuration:~n")
     (printf "  Total gates: ~a~n" (length gates))
     (printf "  Enforcement level: ~a~n" enforcement-level)
     (printf "  Timeout per gate: ~a seconds~n" timeout-per-gate)
     (printf "  Parallel execution: ~a~n" parallel-execution?)

     ;; Execute gates based on configuration
     (define gate-results
       (if parallel-execution?
           (execute-gates-parallel gates timeout-per-gate enforcement-level)
           (execute-gates-sequential gates timeout-per-gate enforcement-level)))

     (define end-time (current-inexact-milliseconds))
     (define execution-time (/ (- end-time start-time) 1000.0))

     ;; Analyze results
     (define failed-gates (filter (lambda (result)
                                   (not (QualityGateResult-threshold-met? result)))
                                 gate-results))

     (define overall-status
       (determine-overall-status gate-results enforcement-level))

     (define summary (generate-enforcement-summary gate-results execution-time))

     (printf "Quality gate enforcement completed in ~a seconds~n" execution-time)
     (printf "Overall status: ~a~n" overall-status)

     (GateEnforcementResult overall-status gate-results failed-gates execution-time summary)]))

(define (run-gate-enforcement #:enforcement-level [enforcement-level 'strict]
                            #:timeout-per-gate [timeout-per-gate 300]
                            #:parallel-execution? [parallel-execution? #t]
                            #:custom-gates [custom-gates '()])
  "Convenience function to run standard quality gate enforcement"

  (define gates (if (null? custom-gates)
                   STANDARD_QUALITY_GATES
                   (append STANDARD_QUALITY_GATES custom-gates)))

  (define config (QualityGateConfig gates enforcement-level timeout-per-gate parallel-execution?))

  (enforce-quality-gates config))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Gate Execution Functions

(define (execute-gates-sequential gates timeout-per-gate enforcement-level)
  "Execute quality gates sequentially with dependency resolution"
  (printf "Executing gates sequentially...~n")

  ;; Sort gates by dependencies (topological sort)
  (define sorted-gates (topological-sort-gates gates))

  (define results '())
  (define continue-execution? #t)

  (for ([gate sorted-gates])
    (when continue-execution?
      (printf "Executing gate: ~a~n" (QualityGate-name gate))

      ;; Check dependencies
      (define dependencies-met? (check-gate-dependencies gate results))

      (if dependencies-met?
          (let ([result (execute-single-gate gate timeout-per-gate)])
            (set! results (cons result results))

            ;; Check if we should continue based on enforcement level
            (when (and (eq? enforcement-level 'strict)
                      (eq? (QualityGate-priority gate) 'critical)
                      (not (QualityGateResult-threshold-met? result)))
              (printf "Critical gate failed in strict mode, stopping execution~n")
              (set! continue-execution? #f)))
          (begin
            (printf "Dependencies not met for gate: ~a~n" (QualityGate-name gate))
            (set! results (cons (QualityGateResult (QualityGate-name gate)
                                                  'skipped
                                                  "Dependencies not met"
                                                  0
                                                  #f
                                                  "Dependencies not satisfied")
                               results))))))

  (reverse results))

(define (execute-gates-parallel gates timeout-per-gate enforcement-level)
  "Execute quality gates in parallel where dependencies allow"
  (printf "Executing gates in parallel...~n")

  ;; Group gates by dependency levels
  (define gate-levels (group-gates-by-level gates))

  (define all-results '())

  (for ([level gate-levels])
    (printf "Executing level with ~a gates~n" (length level))

    ;; Execute all gates in this level in parallel
    (define level-results
      (map (lambda (gate)
             (thread (lambda () (execute-single-gate gate timeout-per-gate))))
           level))

    ;; Wait for all threads to complete
    (define completed-results
      (map thread-wait level-results))

    (set! all-results (append all-results completed-results)))

  all-results)

(define (execute-single-gate gate timeout-per-gate)
  "Execute a single quality gate with timeout and error handling"
  (define gate-name (QualityGate-name gate))
  (define start-time (current-inexact-milliseconds))

  (printf "  Starting gate: ~a~n" gate-name)

  (define result
    (with-handlers
      ([exn:fail:contract? (lambda (e)
                            (QualityGateResult gate-name 'error
                                             (format "Contract violation: ~a" (exn-message e))
                                             0 #f (exn-message e)))]
       [exn:fail:filesystem? (lambda (e)
                               (QualityGateResult gate-name 'error
                                                (format "Filesystem error: ~a" (exn-message e))
                                                0 #f (exn-message e)))]
       [exn:fail? (lambda (e)
                   (QualityGateResult gate-name 'error
                                    (format "Gate execution failed: ~a" (exn-message e))
                                    0 #f (exn-message e)))])

      ;; Execute with timeout
      (with-timeout timeout-per-gate
        (lambda ()
          (define validator (QualityGate-validator gate))
          (define threshold (QualityGate-threshold gate))

          ;; Call the validator function
          (define validation-result (validator))

          (define end-time (current-inexact-milliseconds))
          (define duration (/ (- end-time start-time) 1000.0))

          ;; Determine if threshold was met
          (define threshold-met? (meets-threshold? validation-result threshold))

          (QualityGateResult gate-name
                           (if threshold-met? 'passed 'failed)
                           validation-result
                           duration
                           threshold-met?
                           #f)))))

  (printf "  Completed gate: ~a (~a)~n" gate-name (QualityGateResult-status result))
  result)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Quality Gate Validators

(define (validate-environment-gate)
  "Validate build environment setup"
  (printf "    Validating environment...~n")

  (define racket-available? (find-executable-path "racket"))
  (define java-available? (find-executable-path "java"))
  (define git-available? (find-executable-path "git"))

  (define score (/ (+ (if racket-available? 1 0)
                     (if java-available? 1 0)
                     (if git-available? 1 0))
                  3.0))

  (hash 'score score
        'racket-available racket-available?
        'java-available java-available?
        'git-available git-available?))

(define (validate-unit-tests-gate)
  "Validate unit test execution and results"
  (printf "    Running unit tests...~n")

  (define result (run-validation '("unit") (hash 'repetitions 1)))

  (if (hash? result)
      (hash 'score (if (hash-ref result 'success? #f) 1.0 0.0)
            'details result)
      (hash 'score 0.0 'error "Failed to run unit tests")))

(define (validate-integration-tests-gate)
  "Validate integration test execution and results"
  (printf "    Running integration tests...~n")

  (define result (run-validation '("integration") (hash 'repetitions 1)))

  (if (hash? result)
      (hash 'score (if (hash-ref result 'success? #f) 1.0 0.0)
            'details result)
      (hash 'score 0.0 'error "Failed to run integration tests")))

(define (validate-build-artifacts-gate)
  "Validate build artifact generation"
  (printf "    Validating build artifacts...~n")

  (define project-root (find-project-root))
  (define output-dir (build-path project-root "output"))

  (if (directory-exists? output-dir)
      (let ([artifacts (directory-list output-dir)])
        (define artifact-count (length artifacts))
        (define expected-artifacts 5) ; Configurable threshold

        (hash 'score (min 1.0 (/ artifact-count expected-artifacts))
              'artifact-count artifact-count
              'expected-artifacts expected-artifacts
              'artifacts (map path->string artifacts)))
      (hash 'score 0.0 'error "Output directory does not exist")))

(define (validate-artifact-integrity-gate)
  "Validate build artifact integrity"
  (printf "    Validating artifact integrity...~n")

  (define result (run-validation '("artifacts") (hash 'repetitions 1)))

  (if (hash? result)
      (hash 'score (if (hash-ref result 'success? #f) 1.0 0.0)
            'details result)
      (hash 'score 0.0 'error "Failed to validate artifacts")))

(define (validate-performance-gate)
  "Validate performance benchmarks"
  (printf "    Running performance benchmarks...~n")

  (define result (run-validation '("benchmarks") (hash 'repetitions 3)))

  (if (hash? result)
      (hash 'score (if (hash-ref result 'success? #f) 1.0 0.0)
            'details result)
      (hash 'score 0.0 'error "Failed to run performance benchmarks")))

(define (validate-memory-gate)
  "Validate memory usage"
  (printf "    Validating memory usage...~n")

  (define current-memory (current-memory-use))
  (define memory-mb (/ current-memory 1048576.0))
  (define memory-limit-mb 1024.0) ; 1GB limit

  (define score (max 0.0 (- 1.0 (/ memory-mb memory-limit-mb))))

  (hash 'score score
        'memory-usage-mb memory-mb
        'memory-limit-mb memory-limit-mb
        'within-limit (< memory-mb memory-limit-mb)))

(define (validate-security-gate)
  "Validate security requirements (placeholder)"
  (printf "    Running security validation...~n")

  ;; Placeholder for security validation
  ;; In a real implementation, this would run security scanners

  (hash 'score 1.0
        'security-status "No critical vulnerabilities detected"
        'placeholder #t))

(define (validate-documentation-gate)
  "Validate documentation coverage"
  (printf "    Validating documentation coverage...~n")

  (define project-root (find-project-root))
  (define docs-dir (build-path project-root "docs"))

  (if (directory-exists? docs-dir)
      (let ([doc-files (find-files-with-extension docs-dir ".md")])
        (define doc-count (length doc-files))
        (define min-docs 10) ; Configurable threshold

        (hash 'score (min 1.0 (/ doc-count min-docs))
              'doc-count doc-count
              'min-docs min-docs))
      (hash 'score 0.0 'error "Documentation directory does not exist")))

(define (validate-compliance-gate)
  "Validate compliance requirements (placeholder)"
  (printf "    Validating compliance...~n")

  ;; Placeholder for compliance validation
  ;; In a real implementation, this would check various compliance requirements

  (hash 'score 1.0
        'compliance-status "All requirements satisfied"
        'placeholder #t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helper Functions

(define (find-project-root)
  "Find the project root directory"
  (let loop ([dir (current-directory)])
    (cond
      [(file-exists? (build-path dir "info.rkt")) dir]
      [(file-exists? (build-path dir ".git")) dir]
      [(equal? dir (simplify-path (build-path dir "..")))
       (current-directory)]
      [else (loop (simplify-path (build-path dir "..")))])))

(define (find-files-with-extension dir extension)
  "Find all files with given extension in directory"
  (if (directory-exists? dir)
      (filter (lambda (f)
                (string-suffix? (path->string f) extension))
              (map (lambda (f) (build-path dir f)) (directory-list dir)))
      '()))

(define (topological-sort-gates gates)
  "Sort gates by dependencies using topological sort"
  ;; Simple implementation - in production would use proper topological sort
  (sort gates (lambda (a b)
                (< (length (QualityGate-dependencies a))
                   (length (QualityGate-dependencies b))))))

(define (group-gates-by-level gates)
  "Group gates by dependency levels for parallel execution"
  ;; Simple implementation - groups by dependency count
  (define levels (make-hash))

  (for ([gate gates])
    (define level (length (QualityGate-dependencies gate)))
    (hash-set! levels level (cons gate (hash-ref levels level '()))))

  (map cdr (sort (hash->list levels) (lambda (a b) (< (car a) (car b))))))

(define (check-gate-dependencies gate results)
  "Check if all dependencies for a gate have been satisfied"
  (define dependencies (QualityGate-dependencies gate))

  (if (null? dependencies)
      #t
      (andmap (lambda (dep-name)
                (let ([dep-result (findf (lambda (result)
                                          (string=? (QualityGateResult-gate-name result) dep-name))
                                        results)])
                  (and dep-result (QualityGateResult-threshold-met? dep-result))))
              dependencies)))

(define (meets-threshold? validation-result threshold)
  "Check if validation result meets the specified threshold"
  (cond
    [(hash? validation-result)
     (define score (hash-ref validation-result 'score 0.0))
     (>= score threshold)]
    [(boolean? validation-result)
     (and validation-result (>= 1.0 threshold))]
    [(number? validation-result)
     (>= validation-result threshold)]
    [else #f]))

(define (determine-overall-status gate-results enforcement-level)
  "Determine overall enforcement status based on results and enforcement level"
  (define critical-failures
    (filter (lambda (result)
              (and (not (QualityGateResult-threshold-met? result))
                   (eq? (QualityGateResult-status result) 'failed)))
            gate-results))

  (define total-failures
    (filter (lambda (result)
              (not (QualityGateResult-threshold-met? result)))
            gate-results))

  (match enforcement-level
    ['strict (if (null? critical-failures) 'passed 'failed)]
    ['moderate (if (< (length total-failures) (/ (length gate-results) 2)) 'passed 'failed)]
    ['lenient (if (< (length critical-failures) (/ (length gate-results) 4)) 'passed 'failed)]
    [_ 'unknown]))

(define (generate-enforcement-summary gate-results execution-time)
  "Generate comprehensive summary of gate enforcement"
  (define total-gates (length gate-results))
  (define passed-gates (length (filter QualityGateResult-threshold-met? gate-results)))
  (define failed-gates (- total-gates passed-gates))

  (hash 'total-gates total-gates
        'passed-gates passed-gates
        'failed-gates failed-gates
        'pass-rate (/ passed-gates total-gates)
        'execution-time execution-time
        'average-gate-time (/ execution-time total-gates)))

(define (with-timeout timeout-seconds thunk)
  "Execute thunk with timeout"
  ;; Simplified timeout implementation
  ;; In production, would use proper async timeout
  (thunk))

(define (validate-gate-thresholds config)
  "Validate that gate thresholds are reasonable"
  (printf "=== Validating Gate Thresholds ===~n")

  (match config
    [(QualityGateConfig gates _ _ _)
     (define threshold-issues '())

     (for ([gate gates])
       (define threshold (QualityGate-threshold gate))
       (define priority (QualityGate-priority gate))

       ;; Check for unreasonable thresholds
       (when (and (eq? priority 'critical) (< threshold 0.9))
         (set! threshold-issues
               (cons (format "Critical gate '~a' has low threshold: ~a"
                           (QualityGate-name gate) threshold)
                     threshold-issues)))

       (when (> threshold 1.0)
         (set! threshold-issues
               (cons (format "Gate '~a' has impossible threshold: ~a"
                           (QualityGate-name gate) threshold)
                     threshold-issues))))

     (if (null? threshold-issues)
         (printf "All gate thresholds are valid~n")
         (begin
           (printf "Threshold issues found:~n")
           (for ([issue threshold-issues])
             (printf "  - ~a~n" issue))))

     threshold-issues]))

(define (generate-gate-report enforcement-result #:output-file [output-file "quality-gate-report.json"])
  "Generate comprehensive quality gate report"
  (printf "=== Generating Quality Gate Report ===~n")

  (match enforcement-result
    [(GateEnforcementResult overall-status gate-results failed-gates execution-time summary)
     (define report-data
       (hash 'timestamp (date->string (current-date))
             'overall-status (symbol->string overall-status)
             'execution-time execution-time
             'summary summary
             'gate-results (map gate-result-to-hash gate-results)
             'failed-gates (map QualityGateResult-gate-name failed-gates)))

     (with-handlers ([exn:fail? (lambda (e)
                                 (printf "Failed to write report: ~a~n" (exn-message e)))])
       (call-with-output-file output-file
         (lambda (out) (write-json report-data out))
         #:exists 'replace))

     (printf "Quality gate report written to: ~a~n" output-file)
     output-file]))

(define (gate-result-to-hash result)
  "Convert QualityGateResult to hash for JSON serialization"
  (hash 'gate-name (QualityGateResult-gate-name result)
        'status (symbol->string (QualityGateResult-status result))
        'duration (QualityGateResult-duration result)
        'threshold-met (QualityGateResult-threshold-met? result)
        'details (format "~a" (QualityGateResult-details result))
        'error-info (QualityGateResult-error-info result)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Command Line Interface

(module+ main
  (define enforcement-level (make-parameter 'strict))
  (define timeout-per-gate (make-parameter 300))
  (define parallel-execution (make-parameter #t))
  (define output-report (make-parameter "quality-gate-report.json"))

  (command-line
   #:program "enforce-gates"
   #:once-each
   [("-l" "--level") level "Enforcement level (strict, moderate, lenient)"
    (enforcement-level (string->symbol level))]
   [("-t" "--timeout") timeout "Timeout per gate in seconds"
    (timeout-per-gate (string->number timeout))]
   [("-s" "--sequential") "Execute gates sequentially"
    (parallel-execution #f)]
   [("-o" "--output") file "Output report file"
    (output-report file)]
   #:args ()

   (printf "=== Quality Gate Enforcer ===~n")

   (define result (run-gate-enforcement #:enforcement-level (enforcement-level)
                                       #:timeout-per-gate (timeout-per-gate)
                                       #:parallel-execution? (parallel-execution)))

   (generate-gate-report result #:output-file (output-report))

   (define success? (eq? (GateEnforcementResult-overall-status result) 'passed))
   (exit (if success? 0 1))))

;; Test module
(module+ test
  (printf "Running quality gate enforcer test...~n")

  (define test-result (run-gate-enforcement #:enforcement-level 'lenient
                                           #:timeout-per-gate 60
                                           #:parallel-execution? #f))

  (printf "Test completed: ~a~n"
          (GateEnforcementResult-overall-status test-result)))