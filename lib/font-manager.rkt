#lang racket

;; Font Resource Manager for Knotty DSL
;; Manages knitting symbol fonts, SVG symbols, and Unicode fallbacks

(require racket/path
         racket/file
         racket/hash
         racket/string
         racket/format
         racket/contract
         racket/logging
         xml/xml
         net/url)

;; Font resource configuration
(define font-resources-path
  (build-path (current-directory) "resources" "fonts"))

(define svg-symbols-path
  (build-path (current-directory) "resources" "symbols"))

(define font-cache-path
  (build-path (current-directory) "cache" "fonts"))

;; Knitting symbol mappings
(define knitting-symbols
  (hash
   ;; Basic stitches
   "k" (hash 'unicode "·" 'svg "knit.svg" 'description "knit stitch")
   "p" (hash 'unicode "−" 'svg "purl.svg" 'description "purl stitch")
   "yo" (hash 'unicode "○" 'svg "yarn-over.svg" 'description "yarn over")
   "k2tog" (hash 'unicode "⧸" 'svg "knit-2-together.svg" 'description "knit 2 together")
   "ssk" (hash 'unicode "⧹" 'svg "slip-slip-knit.svg" 'description "slip slip knit")

   ;; Cable stitches
   "c4f" (hash 'unicode "⟋" 'svg "cable-4-front.svg" 'description "cable 4 front")
   "c4b" (hash 'unicode "⟍" 'svg "cable-4-back.svg" 'description "cable 4 back")
   "c6f" (hash 'unicode "⧸⧸" 'svg "cable-6-front.svg" 'description "cable 6 front")
   "c6b" (hash 'unicode "⧹⧹" 'svg "cable-6-back.svg" 'description "cable 6 back")

   ;; Lace stitches
   "k3tog" (hash 'unicode "⧹⧹" 'svg "knit-3-together.svg" 'description "knit 3 together")
   "cdd" (hash 'unicode "∧" 'svg "central-double-decrease.svg" 'description "central double decrease")
   "m1l" (hash 'unicode "◃" 'svg "make-1-left.svg" 'description "make 1 left")
   "m1r" (hash 'unicode "▹" 'svg "make-1-right.svg" 'description "make 1 right")

   ;; Color work
   "mc" (hash 'unicode "■" 'svg "main-color.svg" 'description "main color")
   "cc" (hash 'unicode "□" 'svg "contrast-color.svg" 'description "contrast color")
   "cc2" (hash 'unicode "▣" 'svg "contrast-color-2.svg" 'description "contrast color 2")

   ;; Special symbols
   "no-stitch" (hash 'unicode " " 'svg "no-stitch.svg" 'description "no stitch")
   "marker" (hash 'unicode "|" 'svg "stitch-marker.svg" 'description "stitch marker")
   "repeat-start" (hash 'unicode "⟨" 'svg "repeat-start.svg" 'description "repeat start")
   "repeat-end" (hash 'unicode "⟩" 'svg "repeat-end.svg" 'description "repeat end")))

;; Font availability detection
(define available-fonts (make-hash))

(define/contract (detect-knitting-fonts)
  (-> hash?)
  "Detect available knitting fonts on the system"
  (log-info "Detecting available knitting fonts...")

  (define font-candidates
    '("Knitting Symbols" "ChartSymbols" "Lucida Console" "Consolas" "Monaco" "DejaVu Sans Mono"))

  (define detected (make-hash))

  (for ([font-name font-candidates])
    (when (font-available? font-name)
      (hash-set! detected font-name #t)
      (log-debug "Found font: ~a" font-name)))

  (hash-copy detected))

(define (font-available? font-name)
  "Check if a specific font is available on the system"
  (case (system-type 'os)
    [(windows)
     (system (format "fc-list | grep -i \"~a\" > nul 2>&1" font-name))]
    [(macosx)
     (system (format "system_profiler SPFontsDataType | grep -i \"~a\" > /dev/null 2>&1" font-name))]
    [else ; unix/linux
     (system (format "fc-list | grep -i \"~a\" > /dev/null 2>&1" font-name))]))

;; SVG symbol management
(define/contract (get-symbol-svg symbol-name #:size [size "24"] #:color [color "black"])
  (->* (string?) (#:size string? #:color string?) (or/c string? #f))
  "Get SVG representation of a knitting symbol with optional styling"

  (define symbol-info (hash-ref knitting-symbols symbol-name #f))
  (unless symbol-info
    (log-warning "Unknown symbol: ~a" symbol-name)
    (return #f))

  (define svg-file (hash-ref symbol-info 'svg))
  (define svg-path (build-path svg-symbols-path svg-file))

  (cond
    [(file-exists? svg-path)
     (customize-svg-symbol svg-path size color)]
    [else
     (log-debug "SVG file not found: ~a, generating fallback" svg-path)
     (generate-fallback-svg symbol-name symbol-info size color)]))

(define (customize-svg-symbol svg-path size color)
  "Customize SVG symbol with size and color"
  (define svg-content (file->string svg-path))

  ;; Parse and modify SVG
  (define svg-xml (string->xml svg-content))
  (define modified-svg (modify-svg-attributes svg-xml size color))

  (xml->string modified-svg))

(define (modify-svg-attributes svg-xml size color)
  "Modify SVG attributes for size and color"
  ;; This is a simplified implementation - in practice, you'd want
  ;; more sophisticated SVG manipulation
  (define content (xml->string svg-xml))
  (define sized-content
    (regexp-replace* #rx"(width|height)=\"[^\"]*\""
                     content
                     (format "\\1=\"~a\"" size)))
  (define colored-content
    (regexp-replace* #rx"(fill|stroke)=\"[^\"]*\""
                     sized-content
                     (format "\\1=\"~a\"" color)))

  (string->xml colored-content))

(define (generate-fallback-svg symbol-name symbol-info size color)
  "Generate fallback SVG when symbol file is not available"
  (define unicode-char (hash-ref symbol-info 'unicode "?"))
  (define description (hash-ref symbol-info 'description symbol-name))

  (format
   "<svg width=\"~a\" height=\"~a\" xmlns=\"http://www.w3.org/2000/svg\">
      <text x=\"50%\" y=\"50%\" dominant-baseline=\"middle\" text-anchor=\"middle\"
            font-family=\"monospace\" font-size=\"~a\" fill=\"~a\" title=\"~a\">~a</text>
    </svg>"
   size size size color description unicode-char))

;; Unicode fallback system
(define/contract (get-unicode-symbol symbol-name)
  (-> string? (or/c string? #f))
  "Get Unicode fallback for a knitting symbol"

  (define symbol-info (hash-ref knitting-symbols symbol-name #f))
  (if symbol-info
      (hash-ref symbol-info 'unicode "?")
      #f))

(define/contract (get-symbol-description symbol-name)
  (-> string? (or/c string? #f))
  "Get human-readable description of a knitting symbol"

  (define symbol-info (hash-ref knitting-symbols symbol-name #f))
  (if symbol-info
      (hash-ref symbol-info 'description symbol-name)
      #f))

;; Symbol rendering modes
(define current-rendering-mode (make-parameter 'auto))

(define/contract (set-rendering-mode! mode)
  (-> (or/c 'auto 'svg 'unicode 'font) void?)
  "Set the preferred symbol rendering mode"
  (current-rendering-mode mode)
  (log-info "Symbol rendering mode set to: ~a" mode))

(define/contract (render-symbol symbol-name #:size [size "24"] #:color [color "black"])
  (->* (string?) (#:size string? #:color string?) string?)
  "Render a knitting symbol using the current rendering mode"

  (case (current-rendering-mode)
    [(svg)
     (or (get-symbol-svg symbol-name #:size size #:color color)
         (get-unicode-symbol symbol-name)
         "?")]
    [(unicode)
     (or (get-unicode-symbol symbol-name) "?")]
    [(font)
     (render-with-font symbol-name size color)]
    [else ; auto
     (render-symbol-auto symbol-name size color)]))

(define (render-symbol-auto symbol-name size color)
  "Automatically choose best rendering method for symbol"
  (cond
    ;; Try SVG first for vector graphics
    [(get-symbol-svg symbol-name #:size size #:color color) => identity]
    ;; Fall back to Unicode
    [(get-unicode-symbol symbol-name) => identity]
    ;; Last resort
    [else "?"]))

(define (render-with-font symbol-name size color)
  "Render symbol using system fonts (requires font installation)"
  ;; This would integrate with actual font rendering systems
  ;; For now, fallback to Unicode
  (or (get-unicode-symbol symbol-name) "?"))

;; Symbol validation and registration
(define/contract (register-custom-symbol symbol-name unicode-char svg-file description)
  (-> string? string? string? string? void?)
  "Register a custom knitting symbol"

  (log-info "Registering custom symbol: ~a" symbol-name)

  (hash-set! knitting-symbols symbol-name
             (hash 'unicode unicode-char
                   'svg svg-file
                   'description description))

  (log-debug "Custom symbol registered: ~a -> ~a" symbol-name description))

(define/contract (validate-symbol-library)
  (-> boolean?)
  "Validate the symbol library for completeness and accessibility"

  (log-info "Validating symbol library...")

  (define all-valid? #t)
  (define symbol-count 0)
  (define svg-available 0)
  (define unicode-available 0)

  (for ([(symbol-name symbol-info) knitting-symbols])
    (set! symbol-count (+ symbol-count 1))

    ;; Check SVG availability
    (define svg-file (hash-ref symbol-info 'svg))
    (define svg-path (build-path svg-symbols-path svg-file))
    (if (file-exists? svg-path)
        (set! svg-available (+ svg-available 1))
        (log-warning "Missing SVG for symbol: ~a (~a)" symbol-name svg-file))

    ;; Check Unicode availability
    (define unicode-char (hash-ref symbol-info 'unicode))
    (when unicode-char
      (set! unicode-available (+ unicode-available 1)))

    ;; Validate description
    (unless (hash-ref symbol-info 'description #f)
      (log-warning "Missing description for symbol: ~a" symbol-name)
      (set! all-valid? #f)))

  (log-info "Symbol library validation complete:")
  (log-info "  Total symbols: ~a" symbol-count)
  (log-info "  SVG available: ~a/~a (~a%)"
            svg-available symbol-count
            (inexact->exact (round (* 100 (/ svg-available symbol-count)))))
  (log-info "  Unicode available: ~a/~a (~a%)"
            unicode-available symbol-count
            (inexact->exact (round (* 100 (/ unicode-available symbol-count)))))

  all-valid?)

;; Font installation helpers
(define/contract (download-knitting-fonts #:destination [dest font-resources-path])
  (->* () (#:destination path-string?) boolean?)
  "Download and install knitting fonts to local resource directory"

  (log-info "Downloading knitting fonts to: ~a" dest)
  (make-directory* dest)

  ;; This would download from various open source knitting font repositories
  ;; For now, we provide installation instructions
  (define readme-content
    "# Knitting Font Installation

To enhance symbol rendering, install these open-source knitting fonts:

## Recommended Fonts:
1. **Knitting Font** by Sarah Patterson
   - Download: https://github.com/sarahpatterson/knitting-font
   - License: Open Font License

2. **Chart Symbols** by Various Contributors
   - Download: https://github.com/knitting-charts/chart-symbols
   - License: Creative Commons

## Installation Instructions:

### Windows:
1. Download font files (.ttf or .otf)
2. Right-click font file and select 'Install'
3. Restart your browser/application

### macOS:
1. Download font files
2. Double-click to open Font Book
3. Click 'Install Font'

### Linux:
1. Copy fonts to ~/.local/share/fonts/
2. Run: fc-cache -f -v

## Verification:
Run `racket -e '(require \"font-manager.rkt\") (detect-knitting-fonts)'` to verify installation.
")

  (call-with-output-file (build-path dest "README.md")
    (λ (out) (write-string readme-content out))
    #:exists 'replace)

  (log-info "Font installation instructions written to: ~a" (build-path dest "README.md"))
  #t)

;; Performance monitoring
(define font-render-stats (make-hash))

(define (record-render-stats mode success? render-time)
  "Record font rendering statistics"
  (define key (format "~a-~a" mode (if success? "success" "failure")))
  (hash-update! font-render-stats key (λ (x) (+ x 1)) 0)
  (hash-update! font-render-stats 'total-render-time (λ (x) (+ x render-time)) 0))

(define/contract (get-font-statistics)
  (-> hash?)
  "Get font rendering statistics"
  (hash-copy font-render-stats))

;; Module exports
(provide
 ;; Symbol rendering
 render-symbol
 get-symbol-svg
 get-unicode-symbol
 get-symbol-description

 ;; Rendering modes
 set-rendering-mode!
 current-rendering-mode

 ;; Font detection
 detect-knitting-fonts
 font-available?

 ;; Symbol management
 register-custom-symbol
 validate-symbol-library

 ;; Installation helpers
 download-knitting-fonts

 ;; Statistics
 get-font-statistics

 ;; Configuration
 knitting-symbols
 font-resources-path
 svg-symbols-path)