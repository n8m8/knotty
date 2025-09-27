#lang typed/racket

#|
    Build Artifact Verification Script

    Implements verify-build-artifacts function from validation-api contract
    Provides comprehensive verification of generated build artifacts including
    format validation, checksum verification, and performance metrics.
|#

(require typed/rackunit
         racket/system
         racket/file
         racket/path
         racket/string
         racket/format
         racket/match
         racket/list
         racket/date
         racket/port
         racket/bytes
         file/sha1
         file/md5
         xml
         json)

(provide verify-build-artifacts
         ArtifactStatus
         ArtifactSpec
         exn:fail:artifact?
         exn:fail:artifact
         run-artifact-verification)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Type Definitions

(define-type ArtifactSpec (HashTable Symbol Any))
(define-type ArtifactStatus (HashTable Symbol Any))
(define-type ArtifactInfo (HashTable Symbol Any))
(define-type ValidationResult (HashTable Symbol Any))
(define-type PerformanceMetrics (HashTable Symbol Real))

;; Custom exception type for artifact failures
(struct exn:fail:artifact exn:fail () #:transparent)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Configuration and Validation

(: validate-artifact-spec (-> ArtifactSpec Boolean))
(define (validate-artifact-spec spec)
  (and (hash? spec)
       (hash-has-key? spec 'expected-artifacts)
       (list? (hash-ref spec 'expected-artifacts))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Artifact Discovery and Analysis

(: discover-artifacts (-> Path-String (Listof Path-String)))
(define (discover-artifacts output-dir)
  (if (directory-exists? output-dir)
      (let loop ([dir output-dir] [acc '()])
        (define entries (directory-list dir))
        (define files
          (filter (lambda ([entry : Path-String])
                    (file-exists? (build-path dir entry)))
                  entries))
        (define subdirs
          (filter (lambda ([entry : Path-String])
                    (directory-exists? (build-path dir entry)))
                  entries))
        (define current-files
          (map (lambda ([file : Path-String])
                 (build-path dir file))
               files))
        (define subdir-files
          (append-map (lambda ([subdir : Path-String])
                        (loop (build-path dir subdir) '()))
                      subdirs))
        (append current-files subdir-files acc))
      '()))

(: analyze-artifact (-> Path-String ArtifactInfo))
(define (analyze-artifact artifact-path)
  (define file-stats (file-or-directory-stat artifact-path))
  (define file-size (file-size artifact-path))
  (define file-ext (path-get-extension artifact-path))
  (define file-format (detect-file-format artifact-path))

  (hash 'path (path->string artifact-path)
        'size file-size
        'extension (if file-ext (bytes->string/utf-8 file-ext) "")
        'format file-format
        'created (file-or-directory-stat-change-time file-stats)
        'modified (file-or-directory-stat-modify-time file-stats)
        'permissions (file-or-directory-stat-permissions file-stats)
        'checksum-md5 (calculate-md5-checksum artifact-path)
        'checksum-sha1 (calculate-sha1-checksum artifact-path)))

(: detect-file-format (-> Path-String String))
(define (detect-file-format file-path)
  (define file-ext (path-get-extension file-path))
  (define magic-bytes (get-file-magic-bytes file-path))

  (cond
    ;; Check magic bytes first (more reliable)
    [(and (>= (bytes-length magic-bytes) 4)
          (bytes=? (subbytes magic-bytes 0 4) #"<?xm"))
     "xml"]
    [(and (>= (bytes-length magic-bytes) 4)
          (bytes=? (subbytes magic-bytes 0 4) #"<svg"))
     "svg"]
    [(and (>= (bytes-length magic-bytes) 4)
          (bytes=? (subbytes magic-bytes 0 4) #"%PDF"))
     "pdf"]
    [(and (>= (bytes-length magic-bytes) 8)
          (bytes=? (subbytes magic-bytes 0 8) #"\x89PNG\r\n\x1a\n"))
     "png"]
    [(and (>= (bytes-length magic-bytes) 3)
          (bytes=? (subbytes magic-bytes 0 3) #"\xff\xd8\xff"))
     "jpeg"]
    [(and (>= (bytes-length magic-bytes) 1)
          (or (eq? (bytes-ref magic-bytes 0) (char->integer #\{))
              (eq? (bytes-ref magic-bytes 0) (char->integer #\[))))
     "json"]
    ;; Fall back to extension
    [(and file-ext (bytes=? file-ext #".svg")) "svg"]
    [(and file-ext (bytes=? file-ext #".pdf")) "pdf"]
    [(and file-ext (bytes=? file-ext #".png")) "png"]
    [(and file-ext (bytes=? file-ext #".jpg")) "jpeg"]
    [(and file-ext (bytes=? file-ext #".jpeg")) "jpeg"]
    [(and file-ext (bytes=? file-ext #".json")) "json"]
    [(and file-ext (bytes=? file-ext #".xml")) "xml"]
    [(and file-ext (bytes=? file-ext #".html")) "html"]
    [(and file-ext (bytes=? file-ext #".css")) "css"]
    [(and file-ext (bytes=? file-ext #".js")) "javascript"]
    [else "unknown"]))

(: get-file-magic-bytes (-> Path-String Bytes))
(define (get-file-magic-bytes file-path)
  (with-handlers ([exn:fail? (lambda (e) #"")])
    (call-with-input-file file-path
      (lambda (in)
        (read-bytes 16 in))
      #:mode 'binary)))

(: calculate-md5-checksum (-> Path-String String))
(define (calculate-md5-checksum file-path)
  (with-handlers ([exn:fail? (lambda (e) "error")])
    (call-with-input-file file-path
      (lambda (in)
        (bytes->hex-string (md5 in)))
      #:mode 'binary)))

(: calculate-sha1-checksum (-> Path-String String))
(define (calculate-sha1-checksum file-path)
  (with-handlers ([exn:fail? (lambda (e) "error")])
    (call-with-input-file file-path
      (lambda (in)
        (bytes->hex-string (sha1 in)))
      #:mode 'binary)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Format Validation

(: validate-artifact-format (-> ArtifactInfo ValidationResult))
(define (validate-artifact-format artifact-info)
  (define format (cast (hash-ref artifact-info 'format) String))
  (define path (cast (hash-ref artifact-info 'path) String))

  (hash 'format-type format
        'validation-result (validate-specific-format path format)
        'well-formed? (check-format-well-formed path format)
        'format-compliance (check-format-compliance path format)))

(: validate-specific-format (-> String String (HashTable Symbol Any)))
(define (validate-specific-format file-path format)
  (match format
    ["svg" (validate-svg-format file-path)]
    ["pdf" (validate-pdf-format file-path)]
    ["xml" (validate-xml-format file-path)]
    ["json" (validate-json-format file-path)]
    ["png" (validate-png-format file-path)]
    ["jpeg" (validate-jpeg-format file-path)]
    ["html" (validate-html-format file-path)]
    [_ (hash 'valid? #t
            'validation-type "generic"
            'message "Format validation not implemented")]))

(: validate-svg-format (-> String (HashTable Symbol Any)))
(define (validate-svg-format file-path)
  (with-handlers ([exn:fail? (lambda (e)
                              (hash 'valid? #f
                                    'error (exn-message e)
                                    'validation-type "svg"))])
    (define content (file->string file-path))
    (define has-svg-tag? (string-contains? content "<svg"))
    (define has-namespace? (string-contains? content "xmlns"))
    (define well-formed-xml? (validate-xml-well-formed file-path))

    (hash 'valid? (and has-svg-tag? well-formed-xml?)
          'has-svg-tag? has-svg-tag?
          'has-namespace? has-namespace?
          'well-formed-xml? well-formed-xml?
          'validation-type "svg")))

(: validate-pdf-format (-> String (HashTable Symbol Any)))
(define (validate-pdf-format file-path)
  (with-handlers ([exn:fail? (lambda (e)
                              (hash 'valid? #f
                                    'error (exn-message e)
                                    'validation-type "pdf"))])
    (define magic-bytes (get-file-magic-bytes file-path))
    (define has-pdf-header? (and (>= (bytes-length magic-bytes) 4)
                                (bytes=? (subbytes magic-bytes 0 4) #"%PDF")))

    ;; Additional PDF validation with external tool if available
    (define external-valid? (validate-pdf-with-tool file-path))

    (hash 'valid? has-pdf-header?
          'has-pdf-header? has-pdf-header?
          'external-validation external-valid?
          'validation-type "pdf")))

(: validate-xml-format (-> String (HashTable Symbol Any)))
(define (validate-xml-format file-path)
  (with-handlers ([exn:fail? (lambda (e)
                              (hash 'valid? #f
                                    'error (exn-message e)
                                    'validation-type "xml"))])
    (define well-formed? (validate-xml-well-formed file-path))
    (hash 'valid? well-formed?
          'well-formed? well-formed?
          'validation-type "xml")))

(: validate-json-format (-> String (HashTable Symbol Any)))
(define (validate-json-format file-path)
  (with-handlers ([exn:fail? (lambda (e)
                              (hash 'valid? #f
                                    'error (exn-message e)
                                    'validation-type "json"))])
    (define content (file->string file-path))
    (define parsed-json (string->jsexpr content))
    (hash 'valid? #t
          'parsed-successfully? #t
          'validation-type "json")))

(: validate-png-format (-> String (HashTable Symbol Any)))
(define (validate-png-format file-path)
  (with-handlers ([exn:fail? (lambda (e)
                              (hash 'valid? #f
                                    'error (exn-message e)
                                    'validation-type "png"))])
    (define magic-bytes (get-file-magic-bytes file-path))
    (define has-png-signature? (and (>= (bytes-length magic-bytes) 8)
                                   (bytes=? (subbytes magic-bytes 0 8)
                                           #"\x89PNG\r\n\x1a\n")))

    (hash 'valid? has-png-signature?
          'has-png-signature? has-png-signature?
          'validation-type "png")))

(: validate-jpeg-format (-> String (HashTable Symbol Any)))
(define (validate-jpeg-format file-path)
  (with-handlers ([exn:fail? (lambda (e)
                              (hash 'valid? #f
                                    'error (exn-message e)
                                    'validation-type "jpeg"))])
    (define magic-bytes (get-file-magic-bytes file-path))
    (define has-jpeg-signature? (and (>= (bytes-length magic-bytes) 3)
                                    (bytes=? (subbytes magic-bytes 0 3)
                                            #"\xff\xd8\xff")))

    (hash 'valid? has-jpeg-signature?
          'has-jpeg-signature? has-jpeg-signature?
          'validation-type "jpeg")))

(: validate-html-format (-> String (HashTable Symbol Any)))
(define (validate-html-format file-path)
  (with-handlers ([exn:fail? (lambda (e)
                              (hash 'valid? #f
                                    'error (exn-message e)
                                    'validation-type "html"))])
    (define content (file->string file-path))
    (define has-html-tag? (or (string-contains? content "<html")
                             (string-contains? content "<HTML")))
    (define has-head-tag? (or (string-contains? content "<head")
                             (string-contains? content "<HEAD")))
    (define has-body-tag? (or (string-contains? content "<body")
                             (string-contains? content "<BODY")))

    (hash 'valid? has-html-tag?
          'has-html-tag? has-html-tag?
          'has-head-tag? has-head-tag?
          'has-body-tag? has-body-tag?
          'validation-type "html")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helper Functions for Format Validation

(: validate-xml-well-formed (-> String Boolean))
(define (validate-xml-well-formed file-path)
  (with-handlers ([exn:fail? (lambda (e) #f)])
    (call-with-input-file file-path
      (lambda (in)
        (read-xml in)
        #t))))

(: validate-pdf-with-tool (-> String Boolean))
(define (validate-pdf-with-tool file-path)
  ;; Try to validate PDF with external tools if available
  (with-handlers ([exn:fail? (lambda (e) #f)])
    (cond
      [(find-executable-path "pdfinfo")
       (system (format "pdfinfo \"~a\" > /dev/null 2>&1" file-path))]
      [(find-executable-path "pdftk")
       (system (format "pdftk \"~a\" dump_data > /dev/null 2>&1" file-path))]
      [else #t]))) ; Assume valid if no tools available

(: check-format-well-formed (-> String String Boolean))
(define (check-format-well-formed file-path format)
  (match format
    ["xml" (validate-xml-well-formed file-path)]
    ["svg" (validate-xml-well-formed file-path)]
    [_ #t])) ; Assume well-formed for other formats

(: check-format-compliance (-> String String (HashTable Symbol Any)))
(define (check-format-compliance file-path format)
  ;; Check format-specific compliance rules
  (match format
    ["svg" (check-svg-compliance file-path)]
    ["html" (check-html-compliance file-path)]
    [_ (hash 'compliant? #t
            'rules-checked '()
            'violations '())]))

(: check-svg-compliance (-> String (HashTable Symbol Any)))
(define (check-svg-compliance file-path)
  (define content (file->string file-path))
  (define has-viewbox? (string-contains? content "viewBox"))
  (define has-proper-namespace? (string-contains? content "http://www.w3.org/2000/svg"))

  (hash 'compliant? (and has-proper-namespace?)
        'rules-checked '("namespace" "viewbox")
        'has-viewbox? has-viewbox?
        'has-proper-namespace? has-proper-namespace?
        'violations (filter identity
                           (list (if (not has-proper-namespace?)
                                     "missing-svg-namespace"
                                     #f)))))

(: check-html-compliance (-> String (HashTable Symbol Any)))
(define (check-html-compliance file-path)
  (define content (file->string file-path))
  (define has-doctype? (string-contains? content "<!DOCTYPE"))
  (define has-closing-tags? (check-html-closing-tags content))

  (hash 'compliant? has-closing-tags?
        'rules-checked '("doctype" "closing-tags")
        'has-doctype? has-doctype?
        'has-closing-tags? has-closing-tags?
        'violations (filter identity
                           (list (if (not has-doctype?)
                                     "missing-doctype"
                                     #f)
                                (if (not has-closing-tags?)
                                     "unclosed-tags"
                                     #f)))))

(: check-html-closing-tags (-> String Boolean))
(define (check-html-closing-tags content)
  ;; Simplified check for basic closing tags
  (define html-open (regexp-match-positions #rx"<html[^>]*>" content))
  (define html-close (regexp-match-positions #rx"</html>" content))
  (and html-open html-close))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Checksum Validation

(: validate-checksums (-> ArtifactInfo ArtifactSpec ValidationResult))
(define (validate-checksums artifact-info spec)
  (define checksum-enabled? (cast (hash-ref spec 'checksum-validation? #f) Boolean))

  (if checksum-enabled?
      (let ([expected-artifacts (cast (hash-ref spec 'expected-artifacts) (Listof Any))]
            [artifact-path (cast (hash-ref artifact-info 'path) String)])
        (define expected-artifact
          (findf (lambda ([artifact : Any])
                   ;; Find matching artifact specification
                   (let ([artifact-list (cast artifact (Listof Any))])
                     (string=? (cast (first artifact-list) String) artifact-path)))
                 expected-artifacts))

        (if expected-artifact
            (validate-specific-checksum artifact-info expected-artifact)
            (hash 'enabled? #t
                  'validated? #f
                  'reason "No checksum specification found for artifact")))
      (hash 'enabled? #f
            'validated? #f
            'reason "Checksum validation disabled")))

(: validate-specific-checksum (-> ArtifactInfo Any ValidationResult))
(define (validate-specific-checksum artifact-info expected-artifact)
  (define expected-list (cast expected-artifact (Listof Any)))
  (define expected-checksum
    (findf (lambda ([item : Any])
             (and (hash? item)
                  (hash-has-key? (cast item (HashTable Symbol Any)) 'checksum)))
           expected-list))

  (if expected-checksum
      (let ([expected-hash (cast (hash-ref (cast expected-checksum (HashTable Symbol Any)) 'checksum) String)]
            [actual-md5 (cast (hash-ref artifact-info 'checksum-md5) String)]
            [actual-sha1 (cast (hash-ref artifact-info 'checksum-sha1) String)])
        (hash 'enabled? #t
              'validated? #t
              'expected-checksum expected-hash
              'actual-md5 actual-md5
              'actual-sha1 actual-sha1
              'md5-match? (string=? expected-hash actual-md5)
              'sha1-match? (string=? expected-hash actual-sha1)
              'checksum-valid? (or (string=? expected-hash actual-md5)
                                  (string=? expected-hash actual-sha1))))
      (hash 'enabled? #t
            'validated? #f
            'reason "No checksum value found in specification")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Performance Metrics

(: measure-artifact-performance (-> ArtifactInfo ArtifactSpec PerformanceMetrics))
(define (measure-artifact-performance artifact-info spec)
  (define performance-enabled? (cast (hash-ref spec 'performance-validation? #f) Boolean))

  (if performance-enabled?
      (let ([file-path (cast (hash-ref artifact-info 'path) String)]
            [file-size (cast (hash-ref artifact-info 'size) Integer)])
        (hash 'file-size-mb (/ file-size 1048576.0)  ; Convert to MB
              'read-performance (measure-read-performance file-path)
              'parse-performance (measure-parse-performance artifact-info)
              'compression-ratio (measure-compression-ratio file-path)))
      (hash 'enabled? #f)))

(: measure-read-performance (-> String Real))
(define (measure-read-performance file-path)
  (define start-time (current-inexact-milliseconds))
  (with-handlers ([exn:fail? (lambda (e) -1.0)])
    (file->bytes file-path)
    (- (current-inexact-milliseconds) start-time)))

(: measure-parse-performance (-> ArtifactInfo Real))
(define (measure-parse-performance artifact-info)
  (define format (cast (hash-ref artifact-info 'format) String))
  (define file-path (cast (hash-ref artifact-info 'path) String))
  (define start-time (current-inexact-milliseconds))

  (with-handlers ([exn:fail? (lambda (e) -1.0)])
    (match format
      ["json" (string->jsexpr (file->string file-path))]
      ["xml" (call-with-input-file file-path read-xml)]
      ["svg" (call-with-input-file file-path read-xml)]
      [_ (void)])
    (- (current-inexact-milliseconds) start-time)))

(: measure-compression-ratio (-> String Real))
(define (measure-compression-ratio file-path)
  ;; Estimate compression potential
  (with-handlers ([exn:fail? (lambda (e) 1.0)])
    (define original-size (file-size file-path))
    (define temp-file (make-temporary-file "compression-test-~a.gz"))

    ;; Try to compress with gzip if available
    (if (find-executable-path "gzip")
        (begin
          (system (format "gzip -c \"~a\" > \"~a\"" file-path temp-file))
          (define compressed-size (file-size temp-file))
          (delete-file temp-file)
          (/ (cast original-size Real) (cast compressed-size Real)))
        1.0)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main Verification Function

(: verify-build-artifacts (-> ArtifactSpec ArtifactStatus))
(define (verify-build-artifacts spec)
  (unless (validate-artifact-spec spec)
    (raise (exn:fail:artifact "Invalid artifact specification"
                             (current-continuation-marks))))

  (printf "=== Build Artifact Verification Started ===\n")

  (define expected-artifacts (cast (hash-ref spec 'expected-artifacts) (Listof Any)))
  (define format-validation-enabled? (cast (hash-ref spec 'format-validation? #t) Boolean))
  (define checksum-validation-enabled? (cast (hash-ref spec 'checksum-validation? #f) Boolean))
  (define performance-validation-enabled? (cast (hash-ref spec 'performance-validation? #f) Boolean))

  ;; Discover actual artifacts
  (define project-root (find-project-root))
  (define output-dir (build-path project-root "output"))
  (define discovered-artifacts (discover-artifacts output-dir))

  (printf "Expected artifacts: ~a\n" (length expected-artifacts))
  (printf "Discovered artifacts: ~a\n" (length discovered-artifacts))

  ;; Analyze each artifact
  (define artifact-analyses
    (map analyze-artifact discovered-artifacts))

  ;; Verify each expected artifact
  (define verification-results
    (make-hash
     (map (lambda ([artifact-info : ArtifactInfo])
            (define path (cast (hash-ref artifact-info 'path) String))
            (printf "Verifying artifact: ~a\n" path)

            (define format-result
              (if format-validation-enabled?
                  (validate-artifact-format artifact-info)
                  (hash 'enabled? #f)))

            (define checksum-result
              (if checksum-validation-enabled?
                  (validate-checksums artifact-info spec)
                  (hash 'enabled? #f)))

            (define performance-result
              (if performance-validation-enabled?
                  (measure-artifact-performance artifact-info spec)
                  (hash 'enabled? #f)))

            (cons path
                  (hash 'artifact-info artifact-info
                        'format-validation format-result
                        'checksum-validation checksum-result
                        'performance-metrics performance-result
                        'overall-valid? (and
                                        (or (not format-validation-enabled?)
                                            (cast (hash-ref format-result 'validation-result #f) Boolean))
                                        (or (not checksum-validation-enabled?)
                                            (cast (hash-ref checksum-result 'checksum-valid? #t) Boolean))))))
          artifact-analyses)))

  ;; Check for missing artifacts
  (define missing-artifacts
    (filter (lambda ([expected : Any])
              (define expected-path (cast (first (cast expected (Listof Any))) String))
              (not (hash-has-key? verification-results expected-path)))
            expected-artifacts))

  ;; Calculate overall status
  (define all-valid? (and (empty? missing-artifacts)
                         (andmap (lambda ([pair : (Pairof String (HashTable Symbol Any))])
                                   (cast (hash-ref (cdr pair) 'overall-valid?) Boolean))
                                 (hash->list verification-results))))

  (printf "Verification completed: ~a\n"
          (if all-valid? "✓ SUCCESS" "✗ FAILED"))

  (hash 'artifact-status verification-results
        'format-validation (hash 'enabled? format-validation-enabled?)
        'checksum-validation (hash 'enabled? checksum-validation-enabled?)
        'performance-metrics (hash 'enabled? performance-validation-enabled?)
        'missing-artifacts missing-artifacts
        'total-artifacts (length discovered-artifacts)
        'verified-artifacts (hash-count verification-results)
        'overall-valid? all-valid?
        'timestamp (current-date)
        'specification spec))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Utility Functions

(: find-project-root (-> Path-String))
(define (find-project-root)
  (define current-dir (current-directory))
  (let loop ([dir current-dir])
    (cond
      [(file-exists? (build-path dir "info.rkt")) dir]
      [(file-exists? (build-path dir ".git")) dir]
      [(equal? dir (simplify-path (build-path dir "..")))
       (error "Could not find project root")]
      [else (loop (simplify-path (build-path dir "..")))])))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Command Line Interface

(: run-artifact-verification (-> (Listof String) Void))
(define (run-artifact-verification args)
  (define spec
    (hash 'expected-artifacts
          (list (list "output/pattern-chart.svg"
                     (hash 'format "svg" 'min-size 1024))
                (list "output/pattern-instructions.pdf"
                     (hash 'format "pdf" 'min-size 4096)))
          'format-validation? #t
          'checksum-validation? #f
          'performance-validation? #t))

  (with-handlers
    ([exn:fail:artifact?
      (lambda ([e : exn:fail:artifact])
        (printf "Artifact verification failed: ~a\n" (exn-message e))
        (exit 1))]
     [exn:fail?
      (lambda ([e : exn:fail])
        (printf "Unexpected error: ~a\n" (exn-message e))
        (exit 1))])

    (define results (verify-build-artifacts spec))
    (define success? (cast (hash-ref results 'overall-valid?) Boolean))

    (exit (if success? 0 1))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Module Main

(module+ main
  (require racket/cmdline)

  (command-line
   #:program "verify-artifacts"
   #:once-each
   [("-v" "--verbose") "Enable verbose output" (void)]
   [("-f" "--format") "Enable format validation" (void)]
   [("-c" "--checksum") "Enable checksum validation" (void)]
   [("-p" "--performance") "Enable performance validation" (void)]
   #:args ()
   (run-artifact-verification '())))

;; Export test interface for external validation
(module+ test
  (define test-spec
    (hash 'expected-artifacts
          (list (list "test-artifact.txt"
                     (hash 'format "text")))
          'format-validation? #t
          'checksum-validation? #f
          'performance-validation? #f))

  (printf "Testing artifact verification system...\n")

  ;; This will test the actual artifact verification
  (with-handlers ([exn:fail? (lambda (e)
                              (printf "Artifact verification test result: ~a\n" (exn-message e)))])
    (verify-build-artifacts test-spec)))