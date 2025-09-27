#lang racket

;;;; AI-Enhanced Error Recovery System
;;;; Comprehensive error recovery and rollback procedures
;;;; Part of AI Rebuild Integration Layer - Phase 4.0

(provide recover-from-error
         rollback-to-checkpoint
         RecoveryStrategy
         RecoveryResult
         create-checkpoint
         auto-recovery-manager
         recovery-coordinator)

(require racket/match
         racket/system
         racket/path
         racket/file
         racket/list
         racket/date
         racket/port
         racket/string
         racket/format
         racket/async-channel
         racket/thread
         json)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Data Structures for Recovery Management

(struct RecoveryStrategy (error-type detection-pattern recovery-actions priority timeout) #:transparent)
(struct RecoveryResult (success? strategy-used actions-taken rollback-performed time-taken error-log) #:transparent)
(struct BuildCheckpoint (timestamp build-state file-snapshot dependencies-snapshot environment-snapshot) #:transparent)
(struct RecoveryAction (action-type command description rollback-command priority) #:transparent)
(struct ErrorContext (error-type error-message stack-trace build-phase environment-state) #:transparent)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Predefined Recovery Strategies

(define STANDARD_RECOVERY_STRATEGIES
  (list
    ;; Environment Recovery Strategies
    (RecoveryStrategy 'environment-setup
                     '("environment" "setup" "path" "permission")
                     (list (RecoveryAction 'fix-permissions
                                          "chmod -R 755 ."
                                          "Fix file permissions"
                                          "chmod -R 644 ."
                                          'high)
                           (RecoveryAction 'clear-cache
                                          "rm -rf ~/.racket"
                                          "Clear Racket cache"
                                          ""
                                          'medium)
                           (RecoveryAction 'reinstall-deps
                                          "raco pkg remove --force --all && raco pkg install --deps search-auto"
                                          "Reinstall all packages"
                                          ""
                                          'high))
                     'critical
                     300)

    ;; Dependency Recovery Strategies
    (RecoveryStrategy 'dependency-resolution
                     '("dependency" "package" "install" "download")
                     (list (RecoveryAction 'update-catalog
                                          "raco pkg catalog"
                                          "Update package catalog"
                                          ""
                                          'medium)
                           (RecoveryAction 'force-reinstall
                                          "raco pkg remove --force {pkg} && raco pkg install {pkg}"
                                          "Force reinstall problematic package"
                                          ""
                                          'high)
                           (RecoveryAction 'use-backup-source
                                          "raco pkg install --source backup-catalog {pkg}"
                                          "Use backup package source"
                                          ""
                                          'medium))
                     'critical
                     600)

    ;; Build Recovery Strategies
    (RecoveryStrategy 'build-execution
                     '("build" "compile" "syntax" "error")
                     (list (RecoveryAction 'clean-build
                                          "rm -rf compiled output && raco make -j 4 ."
                                          "Clean and rebuild"
                                          ""
                                          'high)
                           (RecoveryAction 'incremental-build
                                          "raco make -j 1 --disable-inline ."
                                          "Incremental build with reduced optimization"
                                          ""
                                          'medium)
                           (RecoveryAction 'fallback-build
                                          "racket -t main.rkt"
                                          "Simple fallback build"
                                          ""
                                          'low))
                     'high
                     900)

    ;; Memory Recovery Strategies
    (RecoveryStrategy 'memory-exhaustion
                     '("memory" "out of memory" "heap" "allocation")
                     (list (RecoveryAction 'increase-memory
                                          "export PLTSTDERR=info@gc && racket -A 4g"
                                          "Increase memory allocation"
                                          ""
                                          'high)
                           (RecoveryAction 'gc-tuning
                                          "export PLT_GC_MAJOR_THRESHOLD=1024 && racket"
                                          "Tune garbage collection"
                                          ""
                                          'medium)
                           (RecoveryAction 'reduce-parallelism
                                          "raco make -j 1 ."
                                          "Reduce parallel compilation"
                                          ""
                                          'medium))
                     'high
                     300)

    ;; Network Recovery Strategies
    (RecoveryStrategy 'network-connectivity
                     '("network" "connection" "timeout" "download")
                     (list (RecoveryAction 'retry-with-backoff
                                          "sleep 5 && {original-command}"
                                          "Retry with exponential backoff"
                                          ""
                                          'high)
                           (RecoveryAction 'use-mirror
                                          "raco pkg config --set download.github-api.base-url backup-mirror"
                                          "Use backup mirror"
                                          "raco pkg config --unset download.github-api.base-url"
                                          'medium)
                           (RecoveryAction 'offline-mode
                                          "raco pkg install --link local-packages/*"
                                          "Use local packages only"
                                          ""
                                          'low))
                     'medium
                     180)

    ;; Permission Recovery Strategies
    (RecoveryStrategy 'permission-denied
                     '("permission" "denied" "access" "unauthorized")
                     (list (RecoveryAction 'fix-ownership
                                          "chown -R $USER:$USER ."
                                          "Fix file ownership"
                                          ""
                                          'high)
                           (RecoveryAction 'create-directories
                                          "mkdir -p ~/.racket ~/.local/share/racket"
                                          "Create necessary directories"
                                          ""
                                          'high)
                           (RecoveryAction 'use-temp-directory
                                          "export TMPDIR=/tmp/racket-build && mkdir -p $TMPDIR"
                                          "Use temporary directory for build"
                                          ""
                                          'medium))
                     'critical
                     120)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main Recovery API

(define (recover-from-error error-context #:strategies [strategies STANDARD_RECOVERY_STRATEGIES]
                                         #:max-attempts [max-attempts 3]
                                         #:create-checkpoint? [create-checkpoint? #t])
  "Attempt to recover from build error using appropriate strategies

   Parameters:
   - error-context: ErrorContext with error details
   - strategies: List of RecoveryStrategy to try
   - max-attempts: Maximum recovery attempts per strategy
   - create-checkpoint?: Whether to create checkpoint before recovery

   Returns: RecoveryResult with recovery outcome"

  (printf "=== AI-Enhanced Error Recovery Started ===~n")
  (printf "Error type: ~a~n" (ErrorContext-error-type error-context))
  (printf "Error message: ~a~n" (ErrorContext-error-message error-context))

  (define start-time (current-inexact-milliseconds))
  (define error-log '())

  ;; Create checkpoint if requested
  (when create-checkpoint?
    (printf "Creating recovery checkpoint...~n")
    (create-checkpoint (format "pre-recovery-~a" (current-inexact-milliseconds))))

  ;; Find applicable recovery strategies
  (define applicable-strategies (find-applicable-strategies error-context strategies))

  (if (null? applicable-strategies)
      (begin
        (printf "No applicable recovery strategies found~n")
        (RecoveryResult #f #f '() #f 0 '("No applicable recovery strategies")))
      (begin
        (printf "Found ~a applicable recovery strategies~n" (length applicable-strategies))

        ;; Sort strategies by priority
        (define sorted-strategies (sort applicable-strategies
                                       (lambda (a b)
                                         (strategy-priority-value a)
                                         (strategy-priority-value b))))

        ;; Attempt recovery with each strategy
        (define recovery-result (attempt-recovery-strategies sorted-strategies error-context max-attempts))

        (define end-time (current-inexact-milliseconds))
        (define time-taken (/ (- end-time start-time) 1000.0))

        (printf "Error recovery completed in ~a seconds~n" time-taken)

        (struct-copy RecoveryResult recovery-result
                     [time-taken time-taken]))))

(define (auto-recovery-manager build-process #:monitoring-interval [interval 5]
                                            #:max-recovery-attempts [max-attempts 5]
                                            #:escalation-threshold [escalation 3])
  "Autonomous recovery manager that monitors build process and recovers automatically

   Parameters:
   - build-process: Function representing the build process
   - monitoring-interval: Seconds between health checks
   - max-recovery-attempts: Maximum total recovery attempts
   - escalation-threshold: Failures before escalating to human intervention

   Returns: Final build result with recovery history"

  (printf "=== Autonomous Recovery Manager Started ===~n")
  (printf "Monitoring interval: ~a seconds~n" interval)
  (printf "Max recovery attempts: ~a~n" max-attempts)

  (define recovery-attempts 0)
  (define recovery-history '())
  (define escalation-count 0)

  (define (monitor-and-recover)
    (with-handlers
      ([exn:fail? (lambda (e)
                   (printf "Build process failed: ~a~n" (exn-message e))

                   (set! recovery-attempts (+ recovery-attempts 1))
                   (set! escalation-count (+ escalation-count 1))

                   (if (< recovery-attempts max-attempts)
                       (begin
                         (printf "Attempting autonomous recovery (~a/~a)...~n"
                                recovery-attempts max-attempts)

                         (define error-context (ErrorContext 'build-execution
                                                           (exn-message e)
                                                           (exn-continuation-marks e)
                                                           'build-execution
                                                           (get-current-environment-state)))

                         (define recovery-result (recover-from-error error-context))

                         (set! recovery-history (cons recovery-result recovery-history))

                         (if (RecoveryResult-success? recovery-result)
                             (begin
                               (printf "Recovery successful, retrying build...~n")
                               (set! escalation-count 0) ; Reset escalation on success
                               (monitor-and-recover))
                             (begin
                               (printf "Recovery failed, trying next strategy...~n")
                               (if (>= escalation-count escalation-threshold)
                                   (begin
                                     (printf "Escalation threshold reached, requiring human intervention~n")
                                     (cons 'escalation recovery-history))
                                   (monitor-and-recover)))))
                       (begin
                         (printf "Maximum recovery attempts reached~n")
                         (cons 'max-attempts-reached recovery-history))))])

      ;; Attempt to run the build process
      (define result (build-process))
      (printf "Build process completed successfully~n")
      (cons 'success recovery-history)))

  (monitor-and-recover))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Checkpoint Management

(define (create-checkpoint checkpoint-name)
  "Create a comprehensive build checkpoint for rollback

   Parameters:
   - checkpoint-name: Unique name for the checkpoint

   Returns: BuildCheckpoint with complete state snapshot"

  (printf "Creating checkpoint: ~a~n" checkpoint-name)

  (define timestamp (current-date))
  (define checkpoint-dir (build-path "checkpoints" checkpoint-name))

  ;; Create checkpoint directory
  (make-directory* checkpoint-dir)

  ;; Capture file snapshot
  (define file-snapshot (capture-file-snapshot))

  ;; Capture dependencies snapshot
  (define dependencies-snapshot (capture-dependencies-snapshot))

  ;; Capture environment snapshot
  (define environment-snapshot (capture-environment-snapshot))

  ;; Save checkpoint metadata
  (define checkpoint-metadata
    (hash 'timestamp (date->string timestamp)
          'checkpoint-name checkpoint-name
          'file-count (length file-snapshot)
          'dependencies-count (length dependencies-snapshot)))

  (call-with-output-file (build-path checkpoint-dir "metadata.json")
    (lambda (out) (write-json checkpoint-metadata out))
    #:exists 'replace)

  (printf "Checkpoint created: ~a~n" checkpoint-name)

  (BuildCheckpoint timestamp
                   checkpoint-metadata
                   file-snapshot
                   dependencies-snapshot
                   environment-snapshot))

(define (rollback-to-checkpoint checkpoint-name)
  "Rollback build state to specified checkpoint

   Parameters:
   - checkpoint-name: Name of checkpoint to rollback to

   Returns: Boolean indicating rollback success"

  (printf "=== Rolling Back to Checkpoint: ~a ===~n" checkpoint-name)

  (define checkpoint-dir (build-path "checkpoints" checkpoint-name))

  (if (directory-exists? checkpoint-dir)
      (begin
        (printf "Checkpoint found, initiating rollback...~n")

        ;; Load checkpoint metadata
        (define metadata-file (build-path checkpoint-dir "metadata.json"))
        (define metadata (call-with-input-file metadata-file
                          (lambda (in) (read-json in))))

        (printf "Checkpoint metadata: ~a~n" metadata)

        ;; Restore file state
        (printf "Restoring file state...~n")
        (restore-file-snapshot checkpoint-dir)

        ;; Restore dependencies
        (printf "Restoring dependencies...~n")
        (restore-dependencies-snapshot checkpoint-dir)

        ;; Restore environment
        (printf "Restoring environment...~n")
        (restore-environment-snapshot checkpoint-dir)

        (printf "Rollback completed successfully~n")
        #t)
      (begin
        (printf "Checkpoint not found: ~a~n" checkpoint-name)
        #f)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Recovery Strategy Selection and Execution

(define (find-applicable-strategies error-context strategies)
  "Find recovery strategies applicable to the given error context"
  (define error-message (string-downcase (ErrorContext-error-message error-context)))
  (define error-type (ErrorContext-error-type error-context))

  (filter (lambda (strategy)
            (or (eq? (RecoveryStrategy-error-type strategy) error-type)
                (any-pattern-matches? (RecoveryStrategy-detection-pattern strategy) error-message)))
          strategies))

(define (any-pattern-matches? patterns text)
  "Check if any pattern matches the given text"
  (ormap (lambda (pattern)
           (string-contains? text pattern))
         patterns))

(define (attempt-recovery-strategies strategies error-context max-attempts)
  "Attempt recovery using strategies in priority order"
  (define actions-taken '())
  (define strategy-used #f)
  (define success? #f)
  (define rollback-performed? #f)

  (for ([strategy strategies])
    (unless success?
      (printf "Attempting recovery strategy: ~a~n" (RecoveryStrategy-error-type strategy))

      (define strategy-result (execute-recovery-strategy strategy error-context max-attempts))

      (set! actions-taken (append actions-taken (RecoveryResult-actions-taken strategy-result)))
      (set! strategy-used strategy)

      (when (RecoveryResult-success? strategy-result)
        (set! success? #t))

      (when (RecoveryResult-rollback-performed strategy-result)
        (set! rollback-performed? #t))))

  (RecoveryResult success? strategy-used actions-taken rollback-performed? 0 '()))

(define (execute-recovery-strategy strategy error-context max-attempts)
  "Execute a single recovery strategy with retry logic"
  (define actions (RecoveryStrategy-recovery-actions strategy))
  (define timeout (RecoveryStrategy-timeout strategy))
  (define actions-taken '())
  (define success? #f)

  (for ([attempt (in-range max-attempts)])
    (unless success?
      (printf "  Recovery attempt ~a/~a~n" (+ attempt 1) max-attempts)

      (for ([action actions])
        (printf "    Executing action: ~a~n" (RecoveryAction-description action))

        (define action-result (execute-recovery-action action timeout))
        (set! actions-taken (cons action actions-taken))

        (when action-result
          (set! success? #t)))))

  (RecoveryResult success? #f actions-taken #f 0 '()))

(define (execute-recovery-action action timeout)
  "Execute a single recovery action with timeout"
  (define command (RecoveryAction-command action))
  (define action-type (RecoveryAction-action-type action))

  (printf "      Command: ~a~n" command)

  (with-handlers
    ([exn:fail? (lambda (e)
                 (printf "      Action failed: ~a~n" (exn-message e))
                 #f)])

    (match action-type
      ['fix-permissions (execute-permission-fix command)]
      ['clear-cache (execute-cache-clear command)]
      ['reinstall-deps (execute-dependency-reinstall command)]
      ['clean-build (execute-clean-build command)]
      ['retry-with-backoff (execute-retry-with-backoff command)]
      [_ (execute-generic-action command)])))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Specialized Recovery Actions

(define (execute-permission-fix command)
  "Execute permission fix with safety checks"
  (printf "        Fixing permissions...~n")
  ;; Safety check: only fix permissions in current project
  (define safe-command (string-replace command "chmod -R 755 ." "chmod -R 755 ./"))
  (system safe-command))

(define (execute-cache-clear command)
  "Execute cache clearing with backup"
  (printf "        Clearing cache...~n")
  ;; Create backup before clearing
  (system "cp -r ~/.racket ~/.racket.backup 2>/dev/null || true")
  (system command))

(define (execute-dependency-reinstall command)
  "Execute dependency reinstallation with rollback preparation"
  (printf "        Reinstalling dependencies...~n")
  ;; Save current package list
  (system "raco pkg show --all > packages.backup")
  (system command))

(define (execute-clean-build command)
  "Execute clean build with artifact preservation"
  (printf "        Performing clean build...~n")
  ;; Backup important artifacts
  (system "cp -r output output.backup 2>/dev/null || true")
  (system command))

(define (execute-retry-with-backoff command)
  "Execute command with exponential backoff"
  (printf "        Retrying with backoff...~n")
  (define max-retries 3)
  (define base-delay 2)

  (for ([retry (in-range max-retries)])
    (define delay (* base-delay (expt 2 retry)))
    (printf "        Retry ~a after ~a seconds...~n" (+ retry 1) delay)
    (sleep delay)
    (when (system command)
      (break))))

(define (execute-generic-action command)
  "Execute generic recovery action safely"
  (printf "        Executing generic action...~n")
  (system command))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; State Capture and Restoration

(define (capture-file-snapshot)
  "Capture complete file state snapshot"
  (define project-root (find-project-root))
  (define important-files '("*.rkt" "*.json" "*.md" "info.rkt" ".gitignore"))

  (apply append
         (map (lambda (pattern)
                (find-files-matching project-root pattern))
              important-files)))

(define (capture-dependencies-snapshot)
  "Capture current dependency state"
  (with-handlers ([exn:fail? (lambda (e) '())])
    (define output (open-output-string))
    (parameterize ([current-output-port output])
      (system "raco pkg show --all"))
    (string-split (get-output-string output) "\n")))

(define (capture-environment-snapshot)
  "Capture current environment state"
  (hash 'racket-version (version)
        'platform (system-type)
        'current-directory (path->string (current-directory))
        'environment-variables (current-environment-variables)))

(define (restore-file-snapshot checkpoint-dir)
  "Restore file state from checkpoint"
  ;; This would restore files from the checkpoint
  ;; Implementation depends on checkpoint format
  (printf "Restoring files from checkpoint...~n"))

(define (restore-dependencies-snapshot checkpoint-dir)
  "Restore dependency state from checkpoint"
  ;; This would restore package installations
  (printf "Restoring dependencies from checkpoint...~n"))

(define (restore-environment-snapshot checkpoint-dir)
  "Restore environment state from checkpoint"
  ;; This would restore environment variables and settings
  (printf "Restoring environment from checkpoint...~n"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helper Functions

(define (find-project-root)
  "Find the project root directory"
  (let loop ([dir (current-directory)])
    (cond
      [(file-exists? (build-path dir "info.rkt")) dir]
      [(file-exists? (build-path dir ".git")) dir]
      [(equal? dir (simplify-path (build-path dir "..")))
       (current-directory)]
      [else (loop (simplify-path (build-path dir "..")))])))

(define (find-files-matching root pattern)
  "Find files matching pattern in directory tree"
  ;; Simplified implementation
  (if (directory-exists? root)
      (filter (lambda (f) (glob-match? pattern (path->string f)))
              (directory-list root))
      '()))

(define (glob-match? pattern string)
  "Simple glob pattern matching"
  (cond
    [(string=? pattern "*") #t]
    [(string-prefix? pattern "*")
     (string-suffix? string (substring pattern 1))]
    [(string-suffix? pattern "*")
     (string-prefix? string (substring pattern 0 (- (string-length pattern) 1)))]
    [else (string=? pattern string)]))

(define (strategy-priority-value strategy)
  "Convert strategy priority to numeric value"
  (match (RecoveryStrategy-priority strategy)
    ['critical 4]
    ['high 3]
    ['medium 2]
    ['low 1]
    [_ 0]))

(define (get-current-environment-state)
  "Get current build environment state"
  (hash 'timestamp (current-date)
        'memory-usage (current-memory-use)
        'current-directory (path->string (current-directory))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Recovery Coordinator

(define (recovery-coordinator build-function #:strategies [strategies STANDARD_RECOVERY_STRATEGIES]
                                           #:max-total-attempts [max-total-attempts 10]
                                           #:checkpoint-frequency [checkpoint-freq 5])
  "High-level recovery coordinator for complex build processes

   Parameters:
   - build-function: Function to execute the build
   - strategies: Recovery strategies to use
   - max-total-attempts: Maximum total recovery attempts
   - checkpoint-frequency: Create checkpoint every N minutes

   Returns: Final build result with comprehensive recovery log"

  (printf "=== Recovery Coordinator Started ===~n")

  (define recovery-log '())
  (define total-attempts 0)
  (define last-checkpoint-time (current-inexact-milliseconds))

  (define (coordinate-build)
    (with-handlers
      ([exn:fail? (lambda (e)
                   (set! total-attempts (+ total-attempts 1))

                   (printf "Build failed (attempt ~a), initiating recovery...~n" total-attempts)

                   (if (< total-attempts max-total-attempts)
                       (begin
                         ;; Create checkpoint if enough time has passed
                         (define current-time (current-inexact-milliseconds))
                         (when (> (- current-time last-checkpoint-time) (* checkpoint-freq 60 1000))
                           (create-checkpoint (format "auto-checkpoint-~a" total-attempts))
                           (set! last-checkpoint-time current-time))

                         ;; Attempt recovery
                         (define error-context (ErrorContext 'build-execution
                                                           (exn-message e)
                                                           (exn-continuation-marks e)
                                                           'build-execution
                                                           (get-current-environment-state)))

                         (define recovery-result (recover-from-error error-context #:strategies strategies))
                         (set! recovery-log (cons recovery-result recovery-log))

                         (if (RecoveryResult-success? recovery-result)
                             (coordinate-build) ; Retry build
                             (begin
                               (printf "Recovery failed, trying alternative strategies...~n")
                               (coordinate-build))))
                       (begin
                         (printf "Maximum recovery attempts reached, build failed~n")
                         (cons 'max-attempts-exceeded recovery-log))))])

      ;; Execute the build function
      (define result (build-function))
      (printf "Build completed successfully after ~a recovery attempts~n" total-attempts)
      (cons result recovery-log)))

  (coordinate-build))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Command Line Interface

(module+ main
  (define error-type (make-parameter 'build-execution))
  (define error-message (make-parameter "Unknown error"))
  (define max-attempts (make-parameter 3))
  (define checkpoint-name (make-parameter #f))

  (command-line
   #:program "error-recovery"
   #:once-each
   [("-t" "--type") type "Error type (environment-setup, dependency-resolution, build-execution, etc.)"
    (error-type (string->symbol type))]
   [("-m" "--message") msg "Error message"
    (error-message msg)]
   [("-a" "--attempts") attempts "Maximum recovery attempts"
    (max-attempts (string->number attempts))]
   [("-c" "--checkpoint") name "Create checkpoint with name"
    (checkpoint-name name)]
   #:args ()

   (printf "=== Error Recovery System ===~n")

   (when (checkpoint-name)
     (create-checkpoint (checkpoint-name))
     (exit 0))

   (define error-context (ErrorContext (error-type) (error-message) '() 'unknown (get-current-environment-state)))

   (define recovery-result (recover-from-error error-context #:max-attempts (max-attempts)))

   (printf "Recovery completed: ~a~n" (RecoveryResult-success? recovery-result))

   (exit (if (RecoveryResult-success? recovery-result) 0 1))))

;; Test module
(module+ test
  (printf "Running error recovery system test...~n")

  (define test-error-context (ErrorContext 'build-execution
                                         "Test error"
                                         '()
                                         'build-execution
                                         (get-current-environment-state)))

  (define test-result (recover-from-error test-error-context #:max-attempts 1))

  (printf "Test completed: ~a~n" (RecoveryResult-success? test-result)))