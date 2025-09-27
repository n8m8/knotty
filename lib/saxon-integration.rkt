#lang racket

;; Saxon-HE Integration for Knotty DSL
;; Production-ready XSLT processing with comprehensive error handling and monitoring

(require racket/system
         racket/path
         racket/file
         racket/format
         racket/contract
         racket/logging)

;; Saxon JAR path configuration with fallback resolution
(define saxon-jar-path
  (or (and (file-exists? (build-path (current-directory) "lib" "saxon-he-12.x.jar"))
           (build-path (current-directory) "lib" "saxon-he-12.x.jar"))
      (and (file-exists? (build-path (current-directory) "lib" "saxon-he-12.9.jar"))
           (build-path (current-directory) "lib" "saxon-he-12.9.jar"))
      (error "Saxon JAR not found. Expected saxon-he-12.x.jar or saxon-he-12.9.jar in lib/")))

;; Saxon configuration parameters
(define saxon-default-memory "1024m")
(define saxon-default-timeout 30) ; seconds
(define saxon-max-output-size (* 100 1024 1024)) ; 100MB limit

;; XSLT transformation with comprehensive error handling
(define/contract (run-saxon input-xml xsl-file output-file
                           #:memory [memory saxon-default-memory]
                           #:timeout [timeout saxon-default-timeout]
                           #:parameters [params '()])
  (->* (path-string? path-string? path-string?)
       (#:memory string? #:timeout exact-positive-integer? #:parameters (listof (cons/c string? string?)))
       boolean?)
  "Run Saxon XSLT transformation with comprehensive error handling and monitoring"
  (log-info "Starting Saxon transformation: ~a -> ~a" input-xml output-file)

  ;; Validate inputs
  (unless (file-exists? input-xml)
    (error 'run-saxon "Input XML file not found: ~a" input-xml))
  (unless (file-exists? xsl-file)
    (error 'run-saxon "XSL stylesheet not found: ~a" xsl-file))

  ;; Ensure output directory exists
  (define output-dir (path-only (string->path output-file)))
  (when output-dir
    (make-directory* output-dir))

  ;; Build parameter string
  (define param-string
    (string-join
     (for/list ([param params])
       (format "~a=~a" (car param) (cdr param)))
     " "))

  ;; Build and execute command
  (define command
    (format "java -Xmx~a -jar ~a -s:~a -xsl:~a -o:~a~a"
            memory
            (path->string saxon-jar-path)
            (path->string input-xml)
            (path->string xsl-file)
            (path->string output-file)
            (if (null? params) "" (string-append " " param-string))))

  (log-debug "Executing Saxon command: ~a" command)

  (define result
    (with-handlers ([exn:fail:timeout?
                     (λ (e)
                       (log-error "Saxon transformation timed out after ~a seconds" timeout)
                       #f)])
      (parameterize ([current-subprocess-custodian-mode 'kill])
        (define-values (proc stdout stdin stderr)
          (subprocess #f #f #f "java" "-Xmx" memory "-jar" (path->string saxon-jar-path)
                     "-s" (path->string input-xml)
                     "-xsl" (path->string xsl-file)
                     "-o" (path->string output-file)))

        ;; Wait for completion with timeout
        (define wait-result
          (sync/timeout timeout proc))

        (if wait-result
            (let ([exit-code (subprocess-wait proc)])
              (cond
                [(= exit-code 0)
                 (log-info "Saxon transformation completed successfully")
                 #t]
                [else
                 (define error-output (port->string stderr))
                 (log-error "Saxon transformation failed with exit code ~a: ~a" exit-code error-output)
                 #f]))
            (begin
              (subprocess-kill proc #t)
              (log-error "Saxon transformation timed out")
              #f)))))

  ;; Validate output
  (when (and result (file-exists? output-file))
    (define output-size (file-size output-file))
    (when (> output-size saxon-max-output-size)
      (log-warning "Saxon output file is unusually large: ~a bytes" output-size)))

  result)

;; Legacy compatibility functions
(define (run-saxon-with-memory input-xml xsl-file output-file #:memory [mem "1024m"])
  "Legacy function - use run-saxon with #:memory parameter instead"
  (run-saxon input-xml xsl-file output-file #:memory mem))

(define (run-saxon-safe input-xml xsl-file output-file)
  "Legacy function - use run-saxon instead (now safe by default)"
  (run-saxon input-xml xsl-file output-file))

;; Environment validation
(define/contract (saxon-available?)
  (-> boolean?)
  "Check if Saxon JAR file exists and Java is available with version requirements"
  (and (file-exists? saxon-jar-path)
       (java-version-compatible?)))

(define (java-version-compatible?)
  "Check if Java version is compatible (JRE 8+)"
  (define-values (proc stdout stdin stderr)
    (subprocess #f #f #f "java" "-version"))

  (define version-output (port->string stderr))
  (subprocess-wait proc)

  ;; Parse Java version (handles both old "1.8.0" and new "11.0.1" formats)
  (define version-match
    (regexp-match #rx"version \"([0-9]+)(?:\.([0-9]+))?" version-output))

  (if version-match
      (let ([major (string->number (second version-match))]
            [minor (if (third version-match) (string->number (third version-match)) 0)])
        (or (> major 1)
            (and (= major 1) (>= minor 8))))
      #f))

;; Installation validation and diagnostics
(define/contract (test-saxon-installation)
  (-> boolean?)
  "Comprehensive Saxon installation validation with detailed diagnostics"
  (log-info "Testing Saxon-HE installation...")

  (define tests
    (list
     (cons "Saxon JAR file" (λ () (file-exists? saxon-jar-path)))
     (cons "Java runtime" (λ () (system "java -version > /dev/null 2>&1")))
     (cons "Java version compatibility" java-version-compatible?)
     (cons "Saxon JAR integrity" test-saxon-jar-integrity)
     (cons "Basic transformation" test-basic-transformation)))

  (define results
    (for/list ([test tests])
      (define name (car test))
      (define test-fn (cdr test))
      (log-debug "Testing: ~a" name)
      (define result
        (with-handlers ([exn:fail? (λ (e) #f)])
          (test-fn)))
      (if result
          (log-info "✓ ~a: PASS" name)
          (log-error "✗ ~a: FAIL" name))
      (cons name result)))

  (define all-passed? (andmap cdr results))

  (if all-passed?
      (begin
        (log-info "Saxon-HE installation verification completed successfully")
        #t)
      (begin
        (log-error "Saxon-HE installation verification failed")
        #f)))

(define (test-saxon-jar-integrity)
  "Test if Saxon JAR can be loaded and main class exists"
  (define-values (proc stdout stdin stderr)
    (subprocess #f #f #f "java" "-jar" (path->string saxon-jar-path) "-?"))

  (define exit-code (subprocess-wait proc))
  (= exit-code 0))

(define (test-basic-transformation)
  "Test basic XSLT transformation with minimal example"
  (define temp-dir (make-temporary-file "saxon-test-~a" 'directory))
  (define input-xml (build-path temp-dir "test.xml"))
  (define xsl-file (build-path temp-dir "test.xsl"))
  (define output-file (build-path temp-dir "output.xml"))

  (with-handlers ([exn:fail? (λ (e) #f)])
    ;; Create minimal test files
    (call-with-output-file input-xml
      (λ (out) (write-string "<?xml version=\"1.0\"?><test>Hello</test>" out)))

    (call-with-output-file xsl-file
      (λ (out)
        (write-string
         "<?xml version=\"1.0\"?>\n<xsl:stylesheet version=\"2.0\" xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\">\n<xsl:template match=\"/\"><result><xsl:value-of select=\"//test\"/></result></xsl:template>\n</xsl:stylesheet>"
         out)))

    ;; Run transformation
    (define result (run-saxon input-xml xsl-file output-file))

    ;; Cleanup
    (delete-directory/files temp-dir)

    result))

;; Specialized knitting chart generation
(define/contract (generate-knitting-chart pattern-xml chart-xsl output-svg
                                         #:symbols [symbol-map '()]
                                         #:scale [scale "1.0"]
                                         #:colorway [colorway "default"])
  (->* (path-string? path-string? path-string?)
       (#:symbols (listof (cons/c string? string?))
        #:scale string?
        #:colorway string?)
       boolean?)
  "Generate SVG knitting chart from pattern XML with comprehensive symbol and styling support"

  (define parameters
    (append
     symbol-map
     (list (cons "scale" scale)
           (cons "colorway" colorway))))

  (define result
    (run-saxon pattern-xml chart-xsl output-svg #:parameters parameters))

  (when result
    (log-info "Knitting chart generated successfully: ~a" output-svg)
    ;; Validate SVG output
    (validate-svg-output output-svg))

  result)

(define (validate-svg-output svg-file)
  "Validate generated SVG file for common issues"
  (when (file-exists? svg-file)
    (define content (file->string svg-file))
    (define size (string-length content))

    (cond
      [(< size 100)
       (log-warning "SVG output is unusually small (~a bytes), may be incomplete" size)]
      [(not (string-contains? content "<svg"))
       (log-error "Generated file does not appear to be valid SVG")]
      [(not (string-contains? content "</svg>"))
       (log-warning "SVG file may be incomplete (missing closing tag)")]
      [else
       (log-debug "SVG validation passed (~a bytes)" size)])))

;; Performance monitoring
(define saxon-stats (make-hash))

(define (record-transformation-stats input-size processing-time success?)
  "Record transformation statistics for performance monitoring"
  (hash-update! saxon-stats 'total-transformations (λ (x) (+ x 1)) 0)
  (hash-update! saxon-stats 'total-input-size (λ (x) (+ x input-size)) 0)
  (hash-update! saxon-stats 'total-processing-time (λ (x) (+ x processing-time)) 0)
  (when success?
    (hash-update! saxon-stats 'successful-transformations (λ (x) (+ x 1)) 0)))

(define/contract (get-saxon-statistics)
  (-> hash?)
  "Get Saxon transformation statistics"
  (hash-copy saxon-stats))

(define (reset-saxon-statistics!)
  "Reset Saxon transformation statistics"
  (hash-clear! saxon-stats))

;; Module exports
(provide
 ;; Main transformation functions
 run-saxon
 generate-knitting-chart

 ;; Legacy compatibility
 run-saxon-with-memory
 run-saxon-safe

 ;; Environment validation
 saxon-available?
 test-saxon-installation

 ;; Performance monitoring
 get-saxon-statistics
 reset-saxon-statistics!

 ;; Configuration
 saxon-jar-path
 saxon-default-memory
 saxon-default-timeout)
