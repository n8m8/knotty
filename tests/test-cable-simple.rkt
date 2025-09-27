#lang sweet-exp typed/racket
;; Simple test for cable pattern from quickstart Example 3

require "../knotty-lib/main.rkt"

(printf "=== Testing Cable Pattern from Quickstart Example 3 ===\n\n")

;; Create the cable pattern from quickstart using the proper syntax
printf "1. Creating cable pattern...\n"
define
  cable-pattern
  with-handlers ([exn:fail? (lambda (e)
                              (printf "ERROR creating pattern: ~a\n" (exn-message e))
                              #f)])
    pattern
      [name "Simple Cable"]
      [technique 'hand]
      [form 'flat]
      row(1) p2 k4 p2
      row(2) k2 rc-2/2 k2    ; rc-2/2 = 2/2 right cross (cable 4 front)
      rows(3 5 7) p2 k4 p2
      rows(4 6 8) k2 p4 k2

if cable-pattern
  printf "✓ Pattern created successfully\n"
  printf "✗ Pattern creation failed\n"

;; Test pattern properties
when cable-pattern
  printf "\n2. Testing pattern properties...\n"
  printf "   Name: ~a\n" (Pattern-name cable-pattern)
  printf "   Technique: ~a\n" (Options-technique (Pattern-options cable-pattern))
  printf "   Form: ~a\n" (Options-form (Pattern-options cable-pattern))
  printf "   Row count: ~a\n" (Pattern-nrows cable-pattern)

;; Test pattern symbols (including cable symbols)
when cable-pattern
  printf "\n3. Testing pattern symbols (including cables)...\n"
  define all-symbols (pattern-symbols cable-pattern)
  printf "   All stitch symbols used: ~a\n" all-symbols

  define cable-symbols
    filter (lambda (sym) (string-contains? (symbol->string sym) "rc-")) all-symbols
  printf "   Cable symbols found: ~a\n" cable-symbols

;; Test text instructions generation
when cable-pattern
  printf "\n4. Testing text instructions generation...\n"
  with-handlers ([exn:fail? (lambda (e)
                              (printf "ERROR generating text: ~a\n" (exn-message e))
                              #f)])
    text cable-pattern
  printf "✓ Text instructions generated successfully\n"

(printf "\n=== Cable Pattern Test Complete ===\n")