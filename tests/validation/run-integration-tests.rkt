#lang racket/base

;; Integration test runner for validation tests
;; Runs all integration tests and reports results

(require rackunit
         rackunit/text-ui
         "test_environment_setup.rkt"
         "test_cross_platform.rkt"
         "test_saxon_integration.rkt")

(provide (all-defined-out))

;; Combined test suite for all validation tests
(define-test-suite all-validation-tests
  "Complete validation test suite - tests MUST FAIL initially"

  ;; Environment setup tests
  environment-setup-integration-tests

  ;; Cross-platform compatibility tests
  cross-platform-integration-tests

  ;; Saxon XSLT integration tests
  saxon-integration-tests)

;; Run all tests with detailed output
(module+ main
  (printf "Running Knotty Integration Validation Tests\n")
  (printf "===========================================\n\n")
  (printf "NOTE: These tests are designed to FAIL initially\n")
  (printf "as the full integration implementations don't exist yet.\n\n")

  (run-tests all-validation-tests))

;; Export test suite for external runners
(module+ test
  (run-tests all-validation-tests))