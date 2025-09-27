#!/bin/bash

#
# Build Integration Validation Script
#
# Integrates the Knotty validation system with the build process.
# Designed for use in makefiles, CI/CD pipelines, and automated builds.
#

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VALIDATION_SCRIPT="$SCRIPT_DIR/validate.rkt"

# Default options
CATEGORIES="integration,health"
REPETITIONS=3
VERBOSE=false
EXIT_ON_FAILURE=true

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Build Integration Validation Script for Knotty

OPTIONS:
    -c, --categories CATS    Validation categories (default: integration,health)
                            Available: unit,integration,artifacts,benchmarks,health
    -r, --repetitions NUM    Number of benchmark repetitions (default: 3)
    -v, --verbose           Enable verbose output
    -q, --quick             Quick validation (integration,health only, 1 repetition)
    -f, --full              Full validation (all categories, 5 repetitions)
    --no-exit-on-failure    Don't exit with error code on validation failure
    -h, --help              Show this help message

EXAMPLES:
    $0                      # Run default validation
    $0 --quick              # Quick validation for development
    $0 --full               # Comprehensive validation for CI/CD
    $0 -c unit,integration  # Custom categories
    $0 -c benchmarks -r 10  # Performance testing with 10 repetitions

EXIT CODES:
    0    All validations passed
    1    One or more validations failed
    2    Script error or invalid arguments

INTEGRATION:
    # In Makefile
    validate:
        @scripts/validation/validate-build.sh

    # In CI/CD pipeline
    - name: Validate Build
      run: scripts/validation/validate-build.sh --full

    # Pre-commit hook
    scripts/validation/validate-build.sh --quick || exit 1

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--categories)
            CATEGORIES="$2"
            shift 2
            ;;
        -r|--repetitions)
            REPETITIONS="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quick)
            CATEGORIES="integration,health"
            REPETITIONS=1
            shift
            ;;
        -f|--full)
            CATEGORIES="unit,integration,artifacts,benchmarks,health"
            REPETITIONS=5
            shift
            ;;
        --no-exit-on-failure)
            EXIT_ON_FAILURE=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 2
            ;;
    esac
done

# Validate dependencies
check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v racket &> /dev/null; then
        log_error "Racket is not installed or not in PATH"
        exit 2
    fi

    if [[ ! -f "$VALIDATION_SCRIPT" ]]; then
        log_error "Validation script not found: $VALIDATION_SCRIPT"
        exit 2
    fi

    log_success "Dependencies validated"
}

# Pre-validation checks
pre_validation_checks() {
    log_info "Running pre-validation checks..."

    # Check if we're in the project root
    if [[ ! -f "$PROJECT_ROOT/info.rkt" && ! -d "$PROJECT_ROOT/.git" ]]; then
        log_warning "Not in project root directory"
    fi

    # Check for common issues
    if [[ "$CATEGORIES" == *"unit"* ]]; then
        if [[ ! -d "$PROJECT_ROOT/tests" ]]; then
            log_warning "Tests directory not found - unit tests may fail"
        fi
    fi

    if [[ "$CATEGORIES" == *"artifacts"* ]]; then
        if [[ ! -d "$PROJECT_ROOT/output" ]]; then
            log_warning "Output directory not found - artifact verification may fail"
        fi
    fi

    log_success "Pre-validation checks completed"
}

# Run validation
run_validation() {
    log_info "Starting validation with categories: $CATEGORIES"
    log_info "Benchmark repetitions: $REPETITIONS"

    # Build validation command
    local cmd="racket '$VALIDATION_SCRIPT' -c '$CATEGORIES' -r '$REPETITIONS'"

    if [[ "$VERBOSE" == "true" ]]; then
        cmd="$cmd -v"
    fi

    log_info "Executing: $cmd"

    # Change to project root for validation
    cd "$PROJECT_ROOT"

    # Run validation and capture exit code
    if eval "$cmd"; then
        log_success "Validation completed successfully"
        return 0
    else
        local exit_code=$?
        log_error "Validation failed with exit code: $exit_code"
        return $exit_code
    fi
}

# Post-validation reporting
post_validation_reporting() {
    local validation_success=$1

    log_info "Generating post-validation report..."

    # Create validation report directory if it doesn't exist
    local report_dir="$PROJECT_ROOT/build/validation-reports"
    mkdir -p "$report_dir"

    # Generate timestamp
    local timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    local report_file="$report_dir/validation-report-$timestamp.txt"

    # Create validation report
    cat > "$report_file" << EOF
Knotty Validation Report
========================

Timestamp: $(date)
Categories: $CATEGORIES
Repetitions: $REPETITIONS
Verbose: $VERBOSE
Success: $validation_success

Project Root: $PROJECT_ROOT
Validation Script: $VALIDATION_SCRIPT

System Information:
- OS: $(uname -s)
- Architecture: $(uname -m)
- Racket Version: $(racket --version 2>/dev/null || echo "Not available")
- Java Version: $(java -version 2>&1 | head -n1 || echo "Not available")

EOF

    if [[ "$validation_success" == "true" ]]; then
        echo "Result: ✓ PASSED" >> "$report_file"
        log_success "Validation report saved: $report_file"
    else
        echo "Result: ✗ FAILED" >> "$report_file"
        log_error "Validation report saved: $report_file"
    fi
}

# Main execution
main() {
    log_info "Knotty Build Validation Starting..."

    # Run checks
    check_dependencies
    pre_validation_checks

    # Run validation
    local validation_exit_code=0
    if ! run_validation; then
        validation_exit_code=$?
    fi

    # Generate report
    local validation_success="false"
    if [[ $validation_exit_code -eq 0 ]]; then
        validation_success="true"
    fi

    post_validation_reporting "$validation_success"

    # Exit with appropriate code
    if [[ "$EXIT_ON_FAILURE" == "true" && $validation_exit_code -ne 0 ]]; then
        log_error "Validation failed - exiting with error code $validation_exit_code"
        exit $validation_exit_code
    elif [[ $validation_exit_code -ne 0 ]]; then
        log_warning "Validation failed but continuing due to --no-exit-on-failure"
        exit 0
    else
        log_success "Build validation completed successfully"
        exit 0
    fi
}

# Execute main function
main "$@"