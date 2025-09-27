#lang racket

;;;; Build Recovery Script
;;;; Specialized recovery for build execution failures
;;;; Part of AI Rebuild Integration Layer - Phase 4.0

(provide recover-build
         diagnose-build
         BuildDiagnostic)

(require racket/system
         racket/path
         racket/file
         racket/string
         racket/format)

(struct BuildDiagnostic (sources-ok? compiled-clean? output-writable? memory-ok? details) #:transparent)

(define (diagnose-build)
  "Comprehensive build diagnosis"
  (printf "=== Build Diagnosis ===~n")

  (define sources-ok? (check-source-files))
  (define compiled-clean? (check-compiled-directories))
  (define output-ok? (check-output-directory))
  (define memory-ok? (check-memory-usage))

  (printf "Source Files: ~a~n" (if sources-ok? "OK" "ISSUES"))
  (printf "Compiled Dirs: ~a~n" (if compiled-clean? "CLEAN" "STALE"))
  (printf "Output Directory: ~a~n" (if output-ok? "WRITABLE" "ISSUES"))
  (printf "Memory Usage: ~a~n" (if memory-ok? "OK" "HIGH"))

  (BuildDiagnostic sources-ok? compiled-clean? output-ok? memory-ok?
                  (hash 'source-count (count-source-files)
                        'memory-mb (/ (current-memory-use) 1048576.0))))

(define (recover-build)
  "Attempt to recover build execution"
  (printf "=== Build Recovery ===~n")

  (define diagnosis (diagnose-build))

  ;; Clean compiled files if needed
  (unless (BuildDiagnostic-compiled-clean? diagnosis)
    (printf "Cleaning compiled files...~n")
    (clean-compiled-files))

  ;; Fix output directory if needed
  (unless (BuildDiagnostic-output-writable? diagnosis)
    (printf "Fixing output directory...~n")
    (fix-output-directory))

  ;; Handle memory issues if needed
  (unless (BuildDiagnostic-memory-ok? diagnosis)
    (printf "Addressing memory issues...~n")
    (address-memory-issues))

  ;; Attempt incremental build
  (printf "Attempting incremental build...~n")
  (attempt-incremental-build)

  (printf "Build recovery completed~n"))

(define (check-source-files)
  "Check if source files are accessible"
  (with-handlers ([exn:fail? (lambda (e) #f)])
    (> (count-source-files) 0)))

(define (check-compiled-directories)
  "Check if compiled directories are clean"
  (not (or (directory-exists? "compiled")
           (find-compiled-directories "."))))

(define (check-output-directory)
  "Check if output directory is writable"
  (with-handlers ([exn:fail? (lambda (e) #f)])
    (make-directory* "output")
    (define test-file (build-path "output" "test-write.tmp"))
    (call-with-output-file test-file (lambda (out) (display "test" out)))
    (delete-file test-file)
    #t))

(define (check-memory-usage)
  "Check if memory usage is reasonable"
  (< (/ (current-memory-use) 1048576.0) 512)) ; Less than 512MB

(define (count-source-files)
  "Count Racket source files"
  (length (find-racket-files ".")))

(define (find-racket-files dir)
  "Find all .rkt files in directory tree"
  (if (directory-exists? dir)
      (apply append
             (map (lambda (item)
                    (define path (build-path dir item))
                    (cond
                      [(directory-exists? path)
                       (find-racket-files path)]
                      [(string-suffix? (path->string item) ".rkt")
                       (list path)]
                      [else '()]))
                  (directory-list dir)))
      '()))

(define (find-compiled-directories dir)
  "Find compiled directories"
  (if (directory-exists? dir)
      (filter (lambda (item)
                (and (directory-exists? (build-path dir item))
                     (string=? (path->string item) "compiled")))
              (directory-list dir))
      '()))

(define (clean-compiled-files)
  "Clean all compiled files"
  (printf "  Removing compiled directories...~n")
  (system "find . -name compiled -type d -exec rm -rf {} + 2>/dev/null || true"))

(define (fix-output-directory)
  "Fix output directory permissions and structure"
  (printf "  Creating and fixing output directory...~n")
  (make-directory* "output")
  (system "chmod 755 output"))

(define (address-memory-issues)
  "Address memory usage issues"
  (printf "  Forcing garbage collection...~n")
  (collect-garbage)
  (printf "  Memory after GC: ~a MB~n" (/ (current-memory-use) 1048576.0)))

(define (attempt-incremental-build)
  "Attempt incremental build with reduced parallelism"
  (printf "  Attempting build with reduced parallelism...~n")
  (system "raco make -j 1 ."))

(module+ main
  (recover-build))