#lang typed/racket

(require "knotty-lib/main.rkt")

;; Create yarns with proper color values
(define red-yarn (yarn 16711680 "Red"))   ; #xFF0000 = 16711680
(define blue-yarn (yarn 255 "Blue"))      ; #0000FF = 255

;; Verify colors
(printf "Red color: ~a (hex: #~a)\n"
        (Yarn-color red-yarn)
        (string-upcase (number->string (Yarn-color red-yarn) 16)))
(printf "Blue color: ~a (hex: #~a)\n"
        (Yarn-color blue-yarn)
        (let ([hex-str (string-upcase (number->string (Yarn-color blue-yarn) 16))])
          (string-append (make-string (max 0 (- 6 (string-length hex-str))) #\0) hex-str)))

;; Create the corrected colorwork pattern
(define simple-stripes
  (pattern
    ((row 1) (k 8))      ; Row 1: knit 8 in red
    ((row 2) (p 8))      ; Row 2: purl 8 in red
    ((row 3) (cc1 (k 8))) ; Row 3: knit 8 in blue
    ((row 4) (cc1 (p 8))) ; Row 4: purl 8 in blue
    red-yarn    ; MC (main color)
    blue-yarn   ; CC1 (contrast color 1)
    ))

;; Export corrected HTML
(export-html simple-stripes "corrected-stripes.html")
(printf "Corrected HTML exported to corrected-stripes.html\n")