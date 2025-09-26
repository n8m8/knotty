#lang typed/racket

(require "knotty-lib/main.rkt")

;; Debug color values
(define red-yarn (yarn #xFF0000 "Red"))
(define blue-yarn (yarn #x0000FF "Blue"))

(printf "Red yarn color: #~a (~a decimal)\n"
        (string-upcase (number->string (Yarn-color red-yarn) 16))
        (Yarn-color red-yarn))
(printf "Blue yarn color: #~a (~a decimal)\n"
        (string-upcase (number->string (Yarn-color blue-yarn) 16))
        (Yarn-color blue-yarn))

;;; Test with 6-digit padding
(: format-hex-color (Integer -> String))
(define (format-hex-color n)
  (let ([hex-str (string-upcase (number->string n 16))])
    (string-append (make-string (max 0 (- 6 (string-length hex-str))) #\0) hex-str)))

(printf "Red yarn color (padded): #~a\n" (format-hex-color (Yarn-color red-yarn)))
(printf "Blue yarn color (padded): #~a\n" (format-hex-color (Yarn-color blue-yarn)))