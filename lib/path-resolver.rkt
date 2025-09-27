#lang racket

;; Cross-Platform Path Resolver for Knotty DSL
;; Handles path resolution, resource location, and cross-platform compatibility

(require racket/path
         racket/file
         racket/system
         racket/string
         racket/format
         racket/contract
         racket/logging
         racket/match)

;; Platform detection
(define current-platform
  (case (system-type 'os)
    [(windows) 'windows]
    [(macosx) 'macos]
    [else 'unix]))

(define platform-info
  (hash 'platform current-platform
        'path-separator (case current-platform
                         [(windows) ";"]
                         [else ":"])
        'directory-separator (case current-platform
                              [(windows) "\\"]
                              [else "/"])
        'executable-extension (case current-platform
                               [(windows) ".exe"]
                               [else ""])
        'library-extension (case current-platform
                            [(windows) ".dll"]
                            [(macos) ".dylib"]
                            [else ".so"])))

;; Base paths and resource locations
(define project-root
  (let ([current (current-directory)])
    ;; Look for project root indicators
    (let loop ([dir current])
      (cond
        [(or (file-exists? (build-path dir "info.rkt"))
             (file-exists? (build-path dir "Makefile"))
             (file-exists? (build-path dir ".git")))
         dir]
        [(equal? dir (path-only dir)) ; reached filesystem root
         current] ; fallback to current directory
        [else
         (loop (path-only dir))]))))

(define resource-paths
  (hash
   'root project-root
   'lib (build-path project-root "lib")
   'resources (build-path project-root "resources")
   'fonts (build-path project-root "resources" "fonts")
   'symbols (build-path project-root "resources" "symbols")
   'templates (build-path project-root "resources" "templates")
   'cache (build-path project-root "cache")
   'temp (or (getenv "TMPDIR")
             (getenv "TEMP")
             (getenv "TMP")
             (case current-platform
               [(windows) "C:\\temp"]
               [else "/tmp"]))
   'config (case current-platform
            [(windows) (build-path (getenv "APPDATA") "Knotty")]
            [(macos) (build-path (getenv "HOME") "Library" "Application Support" "Knotty")]
            [else (build-path (getenv "HOME") ".config" "knotty")])
   'logs (case current-platform
          [(windows) (build-path (getenv "APPDATA") "Knotty" "logs")]
          [(macos) (build-path (getenv "HOME") "Library" "Logs" "Knotty")]
          [else (build-path (getenv "HOME") ".local" "share" "knotty" "logs")])))

;; Path resolution functions
(define/contract (resolve-resource-path resource-type [subpath #f])
  (->* ((or/c symbol? string?)) ((or/c path-string? #f)) path-string?)
  "Resolve a resource path with optional subpath"

  (define base-path
    (cond
      [(symbol? resource-type)
       (hash-ref resource-paths resource-type
                 (λ () (error 'resolve-resource-path
                            "Unknown resource type: ~a" resource-type)))]
      [(string? resource-type)
       (build-path project-root resource-type)]
      [else
       (error 'resolve-resource-path
              "Invalid resource type: ~a" resource-type)]))

  (if subpath
      (apply build-path base-path (string-split (path->string subpath) "/"))
      base-path))

(define/contract (ensure-resource-directory resource-type [subpath #f])
  (->* ((or/c symbol? string?)) ((or/c path-string? #f)) path-string?)
  "Ensure a resource directory exists, creating it if necessary"

  (define path (resolve-resource-path resource-type subpath))
  (make-directory* path)
  (log-debug "Ensured directory exists: ~a" path)
  path)

(define/contract (find-executable name #:paths [search-paths #f])
  (->* (string?) (#:paths (or/c (listof path-string?) #f)) (or/c path-string? #f))
  "Find an executable in the system PATH or specified paths"

  (define exe-name
    (string-append name (hash-ref platform-info 'executable-extension)))

  (define paths-to-search
    (or search-paths
        (string-split (or (getenv "PATH") "") (hash-ref platform-info 'path-separator))))

  (for/or ([path-dir paths-to-search])
    (define full-path (build-path path-dir exe-name))
    (and (file-exists? full-path)
         (file-executable? full-path)
         full-path)))

(define/contract (find-library name #:paths [search-paths #f])
  (->* (string?) (#:paths (or/c (listof path-string?) #f)) (or/c path-string? #f))
  "Find a shared library in system library paths"

  (define lib-extension (hash-ref platform-info 'library-extension))
  (define lib-patterns
    (case current-platform
      [(windows) (list (format "~a~a" name lib-extension))]
      [else (list (format "lib~a~a" name lib-extension)
                  (format "~a~a" name lib-extension))]))

  (define paths-to-search
    (or search-paths
        (case current-platform
          [(windows) '("C:\\Windows\\System32" "C:\\Windows\\SysWOW64")]
          [(macos) '("/usr/lib" "/usr/local/lib" "/opt/homebrew/lib" "/opt/local/lib")]
          [else '("/lib" "/usr/lib" "/usr/local/lib" "/lib64" "/usr/lib64")])))

  (for*/or ([path-dir paths-to-search]
            [pattern lib-patterns])
    (define full-path (build-path path-dir pattern))
    (and (file-exists? full-path) full-path)))

;; Java-specific path resolution
(define/contract (find-java-executable)
  (-> (or/c path-string? #f))
  "Find Java executable with platform-specific logic"

  (or
   ;; Try JAVA_HOME first
   (let ([java-home (getenv "JAVA_HOME")])
     (and java-home
          (let ([java-exe (build-path java-home "bin"
                                     (string-append "java"
                                                   (hash-ref platform-info 'executable-extension)))])
            (and (file-exists? java-exe) java-exe))))

   ;; Try system PATH
   (find-executable "java")

   ;; Platform-specific fallbacks
   (case current-platform
     [(windows)
      (or (find-executable "java" #:paths '("C:\\Program Files\\Java" "C:\\Program Files (x86)\\Java"))
          (find-executable "java" #:paths '("C:\\ProgramData\\Oracle\\Java")))]
     [(macos)
      (or (find-executable "java" #:paths '("/usr/bin" "/usr/local/bin"))
          (and (directory-exists? "/Library/Java/JavaVirtualMachines")
               (let ([jvm-dirs (directory-list "/Library/Java/JavaVirtualMachines")])
                 (for/or ([jvm-dir jvm-dirs])
                   (define java-exe (build-path "/Library/Java/JavaVirtualMachines"
                                               jvm-dir "Contents" "Home" "bin" "java"))
                   (and (file-exists? java-exe) java-exe)))))]
     [else
      (find-executable "java" #:paths '("/usr/bin" "/usr/local/bin" "/opt/java/bin"))])))

(define/contract (validate-java-installation)
  (-> (hash/c symbol? any/c))
  "Validate Java installation and return detailed information"

  (define java-exe (find-java-executable))
  (define result (make-hash))

  (hash-set! result 'java-found (if java-exe #t #f))
  (hash-set! result 'java-path java-exe)

  (when java-exe
    ;; Get Java version
    (define-values (proc stdout stdin stderr)
      (subprocess #f #f #f (path->string java-exe) "-version"))

    (define version-output (port->string stderr))
    (subprocess-wait proc)

    (hash-set! result 'version-output version-output)

    ;; Parse version
    (define version-match
      (regexp-match #rx"version \"([^\"]+)\"" version-output))

    (when version-match
      (hash-set! result 'version (second version-match))

      ;; Determine major version
      (define version-parts (string-split (second version-match) "."))
      (define major-version
        (cond
          [(and (>= (length version-parts) 2)
                (string=? (first version-parts) "1"))
           (string->number (second version-parts))]
          [(>= (length version-parts) 1)
           (string->number (first version-parts))]
          [else #f]))

      (hash-set! result 'major-version major-version)
      (hash-set! result 'compatible (and major-version (>= major-version 8)))))

  result)

;; File and directory utilities
(define/contract (safe-build-path . components)
  (->* () () #:rest (listof path-string?) path-string?)
  "Build a path safely, handling platform differences"

  (define cleaned-components
    (for/list ([component components])
      (cond
        [(path? component) component]
        [(string? component)
         ;; Normalize path separators
         (string-replace component
                        (if (equal? current-platform 'windows) "/" "\\")
                        (hash-ref platform-info 'directory-separator))]
        [else (path->string component)])))

  (apply build-path cleaned-components))

(define/contract (normalize-path path)
  (-> path-string? path-string?)
  "Normalize a path for the current platform"

  (define path-str (path->string path))

  ;; Convert path separators
  (define normalized
    (case current-platform
      [(windows)
       (string-replace path-str "/" "\\")]
      [else
       (string-replace path-str "\\" "/")]))

  ;; Resolve relative components
  (simplify-path normalized))

(define/contract (path-exists-case-insensitive? path)
  (-> path-string? boolean?)
  "Check if path exists with case-insensitive comparison (useful for cross-platform)"

  (cond
    [(file-exists? path) #t]
    [(equal? current-platform 'windows) #f] ; Windows is already case-insensitive
    [else
     ;; Try to find case-insensitive match on Unix systems
     (define parent (path-only path))
     (define filename (file-name-from-path path))

     (and parent
          (directory-exists? parent)
          (for/or ([entry (directory-list parent)])
            (string-ci=? (path->string entry)
                        (path->string filename))))]))

;; Resource management
(define/contract (get-resource-info)
  (-> hash?)
  "Get comprehensive information about resource paths and availability"

  (define info (make-hash))

  ;; Platform information
  (hash-set! info 'platform (hash-copy platform-info))

  ;; Path information
  (hash-set! info 'paths (make-hash))
  (for ([(key path) resource-paths])
    (hash-set! (hash-ref info 'paths) key
               (hash 'path (path->string path)
                     'exists (directory-exists? path)
                     'writable (directory-writable? path))))

  ;; Java information
  (hash-set! info 'java (validate-java-installation))

  ;; System information
  (hash-set! info 'system
             (hash 'home (getenv "HOME")
                   'user (or (getenv "USER") (getenv "USERNAME"))
                   'temp-dir (hash-ref resource-paths 'temp)))

  info)

(define/contract (create-portable-path path)
  (-> path-string? string?)
  "Create a portable path representation that works across platforms"

  (define relative-to-root
    (find-relative-path project-root path))

  (if relative-to-root
      ;; Convert to forward slashes for portability
      (string-replace (path->string relative-to-root) "\\" "/")
      ;; Return absolute path if not relative to project
      (path->string path)))

(define/contract (resolve-portable-path portable-path)
  (-> string? path-string?)
  "Resolve a portable path to an absolute path on the current platform"

  (cond
    [(path-absolute? portable-path)
     (normalize-path portable-path)]
    [else
     (define components (string-split portable-path "/"))
     (apply safe-build-path project-root components)]))

;; Configuration management
(define config-cache (make-hash))

(define/contract (get-config-value key [default #f])
  (->* (string?) (any/c) any/c)
  "Get a configuration value with caching"

  (unless (hash-has-key? config-cache key)
    (define config-file (build-path (hash-ref resource-paths 'config) "config.rkt"))
    (define value
      (if (file-exists? config-file)
          (with-handlers ([exn:fail? (λ (e) default)])
            (define config-data (file->value config-file))
            (hash-ref config-data (string->symbol key) default))
          default))
    (hash-set! config-cache key value))

  (hash-ref config-cache key))

(define/contract (set-config-value! key value)
  (-> string? any/c void?)
  "Set a configuration value and persist to disk"

  (define config-dir (hash-ref resource-paths 'config))
  (make-directory* config-dir)

  (define config-file (build-path config-dir "config.rkt"))
  (define config-data
    (if (file-exists? config-file)
        (with-handlers ([exn:fail? (λ (e) (make-hash))])
          (file->value config-file))
        (make-hash)))

  (hash-set! config-data (string->symbol key) value)
  (hash-set! config-cache key value)

  (call-with-output-file config-file
    (λ (out) (write config-data out))
    #:exists 'replace))

;; Cleanup utilities
(define/contract (cleanup-temp-files #:older-than [max-age (* 24 60 60)]) ; 24 hours default
  (->* () (#:older-than exact-nonnegative-integer?) exact-nonnegative-integer?)
  "Clean up temporary files older than specified age in seconds"

  (define temp-dir (hash-ref resource-paths 'temp))
  (define current-time (current-seconds))
  (define cleaned-count 0)

  (when (directory-exists? temp-dir)
    (for ([file (in-directory temp-dir)])
      (when (and (file-exists? file)
                 (> (- current-time (file-or-directory-modify-seconds file)) max-age)
                 (string-contains? (path->string file) "knotty"))
        (with-handlers ([exn:fail:filesystem? (λ (e) (void))])
          (delete-file file)
          (set! cleaned-count (+ cleaned-count 1))))))

  (log-info "Cleaned up ~a temporary files" cleaned-count)
  cleaned-count)

;; Module exports
(provide
 ;; Platform information
 current-platform
 platform-info

 ;; Path resolution
 resolve-resource-path
 ensure-resource-directory
 project-root
 resource-paths

 ;; Executable and library finding
 find-executable
 find-library
 find-java-executable
 validate-java-installation

 ;; Path utilities
 safe-build-path
 normalize-path
 path-exists-case-insensitive?

 ;; Portable paths
 create-portable-path
 resolve-portable-path

 ;; Resource management
 get-resource-info

 ;; Configuration
 get-config-value
 set-config-value!

 ;; Cleanup
 cleanup-temp-files)