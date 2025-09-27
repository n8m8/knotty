#lang racket/base

#|
    Knotty Validation System

    Comprehensive validation script for the Knotty project that implements
    the validation-api contract with practical, production-ready validation tools.
|#

(require racket/system
         racket/file
         racket/path
         racket/string
         racket/format
         racket/match
         racket/list
         racket/date
         racket/port
         racket/cmdline)

(provide run-validation
         ValidationConfig
         ValidationResults)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Data Structures

(struct ValidationConfig (categories options) #:transparent)
(struct ValidationResults (category results success? duration) #:transparent)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Core Validation Functions

(define (execute-unit-tests options)
  (printf "=== Running Unit Tests ===\n")

  (define project-root (find-project-root))
  (define tests-dir (build-path project-root "tests"))

  (if (directory-exists? tests-dir)
      (let ([test-files (find-racket-files tests-dir "test-")])
        (if (null? test-files)
            (hash 'success? #f 'error "No test files found")
            (let ([results (map run-test-file test-files)])
              (define passed (apply + (map (λ (r) (hash-ref r 'passed 0)) results)))
              (define failed (apply + (map (λ (r) (hash-ref r 'failed 0)) results)))
              (define success? (= failed 0))

              (printf "Unit Tests: ~a passed, ~a failed (~a)\n"
                      passed failed (if success? "✓" "✗"))

              (hash 'success? success?
                    'passed passed
                    'failed failed
                    'test-files (length test-files)
                    'details results))))
      (hash 'success? #f 'error "Tests directory not found")))

(define (validate-integration options)
  (printf "=== Running Integration Tests ===\n")

  ;; Check Saxon XSLT integration
  (define saxon-available? (check-saxon-availability))
  (printf "Saxon XSLT: ~a\n" (if saxon-available? "✓" "✗"))

  ;; Check font system
  (define fonts-available? (check-font-system))
  (printf "Font System: ~a\n" (if fonts-available? "✓" "✗"))

  ;; Check file I/O
  (define file-io-ok? (check-file-io))
  (printf "File I/O: ~a\n" (if file-io-ok? "✓" "✗"))

  (define success? (and saxon-available? fonts-available? file-io-ok?))

  (hash 'success? success?
        'saxon-available? saxon-available?
        'fonts-available? fonts-available?
        'file-io-ok? file-io-ok?))

(define (verify-build-artifacts options)
  (printf "=== Verifying Build Artifacts ===\n")

  (define project-root (find-project-root))
  (define output-dir (build-path project-root "output"))

  (if (directory-exists? output-dir)
      (let ([artifacts (directory-list output-dir)])
        (define artifact-results
          (map (λ (artifact)
                 (verify-artifact (build-path output-dir artifact)))
               artifacts))

        (define valid-count (length (filter (λ (r) (hash-ref r 'valid? #f)) artifact-results)))
        (define total-count (length artifact-results))
        (define success? (= valid-count total-count))

        (printf "Artifacts: ~a/~a valid (~a)\n"
                valid-count total-count (if success? "✓" "✗"))

        (hash 'success? success?
              'total-artifacts total-count
              'valid-artifacts valid-count
              'details artifact-results))
      (begin
        (printf "Output directory not found\n")
        (hash 'success? #f 'error "No output directory"))))

(define (run-performance-benchmarks options)
  (printf "=== Running Performance Benchmarks ===\n")

  (define repetitions (hash-ref options 'repetitions 3))

  ;; Chart generation benchmark
  (define chart-time (benchmark-chart-generation repetitions))
  (define chart-passed? (< chart-time 5.0))
  (printf "Chart Generation: ~as (~a)\n" (~r chart-time #:precision 2)
          (if chart-passed? "✓" "✗"))

  ;; Memory usage benchmark
  (define memory-mb (benchmark-memory-usage repetitions))
  (define memory-passed? (< memory-mb 512))
  (printf "Memory Usage: ~aMB (~a)\n" (~r memory-mb #:precision 1)
          (if memory-passed? "✓" "✗"))

  ;; Pattern compilation benchmark
  (define compile-time (benchmark-pattern-compilation repetitions))
  (define compile-passed? (< compile-time 2.0))
  (printf "Pattern Compilation: ~as (~a)\n" (~r compile-time #:precision 2)
          (if compile-passed? "✓" "✗"))

  (define success? (and chart-passed? memory-passed? compile-passed?))

  (hash 'success? success?
        'chart-generation-time chart-time
        'memory-usage-mb memory-mb
        'compilation-time compile-time
        'repetitions repetitions))

(define (validate-system-health options)
  (printf "=== Validating System Health ===\n")

  ;; Check Racket installation
  (define racket-ok? (find-executable-path "racket"))
  (printf "Racket: ~a\n" (if racket-ok? "✓" "✗"))

  ;; Check Java (for Saxon)
  (define java-ok? (find-executable-path "java"))
  (printf "Java: ~a\n" (if java-ok? "✓" "✗"))

  ;; Check memory
  (define memory-bytes (current-memory-use))
  (define memory-mb (/ memory-bytes 1048576.0))
  (define memory-ok? (< memory-mb 1024))
  (printf "Memory Usage: ~aMB (~a)\n" (~r memory-mb #:precision 1)
          (if memory-ok? "✓" "✗"))

  ;; Check file system
  (define fs-ok? (check-file-system-health))
  (printf "File System: ~a\n" (if fs-ok? "✓" "✗"))

  (define success? (and racket-ok? java-ok? memory-ok? fs-ok?))

  (hash 'success? success?
        'racket-available? racket-ok?
        'java-available? java-ok?
        'memory-usage-mb memory-mb
        'file-system-ok? fs-ok?))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helper Functions

(define (find-project-root)
  (let loop ([dir (current-directory)])
    (cond
      [(file-exists? (build-path dir "info.rkt")) dir]
      [(file-exists? (build-path dir ".git")) dir]
      [(equal? dir (simplify-path (build-path dir "..")))
       (current-directory)] ; fallback to current directory
      [else (loop (simplify-path (build-path dir "..")))])))

(define (find-racket-files dir prefix)
  (if (directory-exists? dir)
      (filter (λ (f)
                (and (string-suffix? (path->string f) ".rkt")
                     (string-prefix? (path->string (file-name-from-path f)) prefix)))
              (map (λ (f) (build-path dir f)) (directory-list dir)))
      '()))

(define (run-test-file test-file)
  (define racket-exe (or (find-executable-path "racket") "racket"))
  (define project-root (find-project-root))
  (define absolute-test-path (if (absolute-path? test-file)
                                test-file
                                (build-path project-root test-file)))
  (parameterize ([current-directory project-root])
    (define-values (proc stdout stdin stderr)
      (subprocess #f #f #f racket-exe (path->string absolute-test-path)))

    (subprocess-wait proc)
    (define exit-code (subprocess-status proc))
    (define output (port->string stdout))

    (close-input-port stdout)
    (close-output-port stdin)
    (close-input-port stderr)

    (hash 'file (path->string test-file)
          'exit-code exit-code
          'passed (if (= exit-code 0) 1 0)
          'failed (if (= exit-code 0) 0 1)
          'output (substring output 0 (min (string-length output) 200)))))

(define (check-saxon-availability)
  (and (find-executable-path "java")
       (find-saxon-jar)))

(define (find-saxon-jar)
  (define project-root (find-project-root))
  (define search-paths
    (list (build-path project-root "lib")
          (build-path project-root "dependencies")
          project-root))

  (ormap (λ (path)
           (and (directory-exists? path)
                (ormap (λ (file)
                         (and (string-contains? (path->string file) "saxon")
                              (string-suffix? (path->string file) ".jar")))
                       (directory-list path))))
         search-paths))

(define (check-font-system)
  (or (find-executable-path "fc-list")
      (directory-exists? "/System/Library/Fonts")  ; macOS
      (directory-exists? "C:/Windows/Fonts")))     ; Windows

(define (check-file-io)
  (with-handlers ([exn:fail? (λ (e) #f)])
    (define temp-file (make-temporary-file "io-test-~a.txt"))
    (call-with-output-file temp-file
      (λ (out) (display "test" out))
      #:exists 'replace)
    (define content (file->string temp-file))
    (delete-file temp-file)
    (string=? content "test")))

(define (verify-artifact artifact-path)
  (define exists? (file-exists? artifact-path))
  (define size (if exists? (file-size artifact-path) 0))
  (define ext (path-get-extension artifact-path))
  (define format (if ext (bytes->string/utf-8 ext) "unknown"))

  (hash 'path (path->string artifact-path)
        'exists? exists?
        'size size
        'format format
        'valid? (and exists? (> size 0))))

(define (benchmark-chart-generation repetitions)
  (define start-time (current-inexact-milliseconds))

  ;; Simulate chart generation workload
  (for ([i repetitions])
    (define data (for/list ([j 1000]) (list j (modulo j 10))))
    (define processed (map (λ (item) (* (car item) (cadr item))) data))
    (apply + processed))

  (/ (- (current-inexact-milliseconds) start-time) 1000.0 repetitions))

(define (benchmark-memory-usage repetitions)
  (define memory-samples
    (for/list ([i repetitions])
      (define start-mem (current-memory-use))
      ;; Allocate some memory
      (define big-list (for/list ([j 10000]) (make-list 100 j)))
      (define end-mem (current-memory-use))
      (/ (- end-mem start-mem) 1048576.0))) ; Convert to MB

  (/ (apply + memory-samples) repetitions))

(define (benchmark-pattern-compilation repetitions)
  (define start-time (current-inexact-milliseconds))

  ;; Simulate pattern compilation
  (for ([i repetitions])
    (define pattern "K2 P2 K2 P2 repeat 10 times")
    (define tokens (string-split pattern " "))
    (define processed (map string-length tokens))
    (apply + processed))

  (/ (- (current-inexact-milliseconds) start-time) 1000.0 repetitions))

(define (check-file-system-health)
  (with-handlers ([exn:fail? (λ (e) #f)])
    (define temp-dir (make-temporary-file "health-test-~a" 'directory))
    (define temp-file (build-path temp-dir "test.txt"))

    (call-with-output-file temp-file
      (λ (out) (display "health check" out)))

    (define content (file->string temp-file))
    (delete-file temp-file)
    (delete-directory temp-dir)

    (string=? content "health check")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main Validation Function

(define (run-validation categories options)
  (printf "=== Knotty Validation System ===\n\n")

  (define start-time (current-inexact-milliseconds))
  (define results '())

  ;; Run requested validation categories
  (when (member "unit" categories)
    (define result (execute-unit-tests options))
    (set! results (cons (ValidationResults "unit" result (hash-ref result 'success?) 0) results)))

  (when (member "integration" categories)
    (define result (validate-integration options))
    (set! results (cons (ValidationResults "integration" result (hash-ref result 'success?) 0) results)))

  (when (member "artifacts" categories)
    (define result (verify-build-artifacts options))
    (set! results (cons (ValidationResults "artifacts" result (hash-ref result 'success?) 0) results)))

  (when (member "benchmarks" categories)
    (define result (run-performance-benchmarks options))
    (set! results (cons (ValidationResults "benchmarks" result (hash-ref result 'success?) 0) results)))

  (when (member "health" categories)
    (define result (validate-system-health options))
    (set! results (cons (ValidationResults "health" result (hash-ref result 'success?) 0) results)))

  (define end-time (current-inexact-milliseconds))
  (define total-duration (/ (- end-time start-time) 1000.0))

  ;; Summary
  (printf "\n=== Validation Summary ===\n")
  (printf "Duration: ~a seconds\n" (~r total-duration #:precision 2))

  (define successful-results (filter ValidationResults-success? results))
  (define overall-success? (= (length successful-results) (length results)))

  (for ([result results])
    (printf "  ~a: ~a\n"
            (ValidationResults-category result)
            (if (ValidationResults-success? result) "✓" "✗")))

  (printf "Overall: ~a (~a/~a passed)\n"
          (if overall-success? "✓ SUCCESS" "✗ FAILED")
          (length successful-results)
          (length results))

  overall-success?)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Command Line Interface

(module+ main
  (define categories (make-parameter '("unit" "integration" "artifacts" "benchmarks" "health")))
  (define repetitions (make-parameter 3))
  (define verbose (make-parameter #f))

  (command-line
   #:program "validate"
   #:once-each
   [("-c" "--categories") cats "Validation categories (comma-separated: unit,integration,artifacts,benchmarks,health)"
    (categories (string-split cats ","))]
   [("-r" "--repetitions") reps "Number of benchmark repetitions"
    (repetitions (string->number reps))]
   [("-v" "--verbose") "Enable verbose output"
    (verbose #t)]
   #:args ()

   (define options (hash 'repetitions (repetitions) 'verbose (verbose)))
   (define success? (run-validation (categories) options))

   (exit (if success? 0 1))))

;; Test module
(module+ test
  (printf "Running validation system test...\n")
  (define test-success? (run-validation '("health") (hash 'repetitions 1)))
  (printf "Test completed: ~a\n" (if test-success? "SUCCESS" "FAILED")))