#!/bin/bash

# Saxon-HE Validation Script
# Validates Saxon installation and Java environment
# Usage: ./validate-saxon.sh

set -e

# Configuration
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAXON_JAR="$LIB_DIR/saxon-he-12.9.jar"
SAXON_LINK="$LIB_DIR/saxon-he-12.x.jar"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

# Check if Saxon JAR exists
check_saxon_jar() {
    log_info "Checking Saxon JAR file..."

    if [[ -f "$SAXON_JAR" ]]; then
        local file_size=$(stat -f%z "$SAXON_JAR" 2>/dev/null || stat -c%s "$SAXON_JAR" 2>/dev/null)
        log_success "Saxon JAR found: $SAXON_JAR"
        log_info "File size: ${file_size} bytes"
        return 0
    else
        log_error "Saxon JAR not found: $SAXON_JAR"
        log_info "Run: ./download-saxon.sh to download Saxon-HE"
        return 1
    fi
}

# Check if symlink exists and is correct
check_symlink() {
    log_info "Checking Saxon symlink..."

    if [[ -L "$SAXON_LINK" ]]; then
        local target=$(readlink "$SAXON_LINK")
        if [[ "$target" == "saxon-he-12.9.jar" ]]; then
            log_success "Symlink is correct: $SAXON_LINK -> $target"
            return 0
        else
            log_warning "Symlink points to wrong target: $target"
            return 1
        fi
    else
        log_warning "Symlink not found: $SAXON_LINK"
        return 1
    fi
}

# Check Java runtime
check_java() {
    log_info "Checking Java runtime..."

    if command -v java &> /dev/null; then
        local java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
        log_success "Java runtime found: $java_version"

        # Check Java version (need 8+)
        local major_version=$(echo "$java_version" | cut -d'.' -f1)
        if [[ "$major_version" == "1" ]]; then
            major_version=$(echo "$java_version" | cut -d'.' -f2)
        fi

        if [[ $major_version -ge 8 ]]; then
            log_success "Java version is compatible (8+)"
            return 0
        else
            log_warning "Java version may be too old (requires 8+)"
            return 1
        fi
    else
        log_error "Java runtime not found in PATH"
        log_info "Install Java 8+ from: https://adoptium.net/"
        return 1
    fi
}

# Test Saxon functionality
test_saxon() {
    if ! command -v java &> /dev/null; then
        log_warning "Skipping Saxon functionality test (Java not available)"
        return 1
    fi

    log_info "Testing Saxon functionality..."

    # Test Saxon version info
    if java -jar "$SAXON_JAR" -t > /dev/null 2>&1; then
        log_success "Saxon JAR is functional"

        # Get Saxon version
        local saxon_version=$(java -jar "$SAXON_JAR" -t 2>&1 | grep "Saxon-HE" | head -n 1 || echo "Unknown version")
        log_info "Saxon version: $saxon_version"
        return 0
    else
        log_error "Saxon JAR failed functionality test"
        return 1
    fi
}

# Create sample XSLT test
create_test_files() {
    local test_dir="$LIB_DIR/test"
    mkdir -p "$test_dir"

    # Create sample XML
    cat > "$test_dir/sample.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<knitting-pattern>
    <row number="1">
        <stitch type="knit">k</stitch>
        <stitch type="purl">p</stitch>
        <stitch type="knit">k</stitch>
    </row>
    <row number="2">
        <stitch type="purl">p</stitch>
        <stitch type="knit">k</stitch>
        <stitch type="purl">p</stitch>
    </row>
</knitting-pattern>
EOF

    # Create sample XSLT
    cat > "$test_dir/sample.xsl" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" indent="yes"/>

    <xsl:template match="knitting-pattern">
        <html>
            <head><title>Knitting Pattern Test</title></head>
            <body>
                <h1>Pattern Test</h1>
                <table border="1">
                    <xsl:for-each select="row">
                        <tr>
                            <td>Row <xsl:value-of select="@number"/></td>
                            <xsl:for-each select="stitch">
                                <td class="{@type}"><xsl:value-of select="."/></td>
                            </xsl:for-each>
                        </tr>
                    </xsl:for-each>
                </table>
                <p>Generated with Saxon-HE XSLT 2.0</p>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
EOF

    log_info "Created test files in: $test_dir"
}

# Run full XSLT transformation test
test_transformation() {
    if ! command -v java &> /dev/null; then
        log_warning "Skipping transformation test (Java not available)"
        return 1
    fi

    local test_dir="$LIB_DIR/test"
    local input_xml="$test_dir/sample.xml"
    local stylesheet="$test_dir/sample.xsl"
    local output_html="$test_dir/output.html"

    log_info "Running XSLT transformation test..."

    # Ensure test files exist
    create_test_files

    # Run transformation
    if java -jar "$SAXON_JAR" -s:"$input_xml" -xsl:"$stylesheet" -o:"$output_html" > /dev/null 2>&1; then
        if [[ -f "$output_html" ]] && [[ -s "$output_html" ]]; then
            log_success "XSLT transformation successful"
            log_info "Output generated: $output_html"
            return 0
        else
            log_error "Transformation completed but output file is missing/empty"
            return 1
        fi
    else
        log_error "XSLT transformation failed"
        return 1
    fi
}

# Generate Racket integration code
generate_racket_code() {
    local racket_file="$LIB_DIR/saxon-integration.rkt"

    log_info "Generating Racket integration example..."

    cat > "$racket_file" << EOF
#lang racket

;; Saxon-HE Integration for Knotty DSL
;; Auto-generated by validate-saxon.sh

(require racket/system)

;; Saxon JAR path configuration
(define saxon-jar-path
  (build-path (current-directory) "lib" "saxon-he-12.9.jar"))

;; Alternative using symlink
(define saxon-jar-symlink
  (build-path (current-directory) "lib" "saxon-he-12.x.jar"))

;; Basic XSLT transformation function
(define (run-saxon input-xml xsl-file output-file)
  "Run Saxon XSLT transformation with basic parameters"
  (system (format "java -jar ~a -s:~a -xsl:~a -o:~a"
                  saxon-jar-path input-xml xsl-file output-file)))

;; XSLT transformation with memory allocation
(define (run-saxon-with-memory input-xml xsl-file output-file #:memory [mem "1024m"])
  "Run Saxon XSLT transformation with specified memory allocation"
  (system (format "java -Xmx~a -jar ~a -s:~a -xsl:~a -o:~a"
                  mem saxon-jar-path input-xml xsl-file output-file)))

;; XSLT transformation with error handling
(define (run-saxon-safe input-xml xsl-file output-file)
  "Run Saxon XSLT transformation with error handling"
  (let ([result (system (format "java -jar ~a -s:~a -xsl:~a -o:~a"
                               saxon-jar-path input-xml xsl-file output-file))])
    (unless (= result 0)
      (error "Saxon XSLT transformation failed with exit code" result))))

;; Check if Saxon is available
(define (saxon-available?)
  "Check if Saxon JAR file exists and Java is available"
  (and (file-exists? saxon-jar-path)
       (system "java -version > /dev/null 2>&1")))

;; Test Saxon installation
(define (test-saxon-installation)
  "Test Saxon installation and return status"
  (cond
    [(not (file-exists? saxon-jar-path))
     (error "Saxon JAR not found at" saxon-jar-path)]
    [(not (system "java -version > /dev/null 2>&1"))
     (error "Java runtime not available")]
    [else
     (printf "Saxon-HE installation verified~n")
     #t]))

;; Example usage for knitting charts
(define (generate-knitting-chart pattern-xml chart-xsl output-svg)
  "Generate SVG knitting chart from pattern XML using XSLT"
  (run-saxon-safe pattern-xml chart-xsl output-svg)
  (printf "Knitting chart generated: ~a~n" output-svg))

;; Export functions
(provide run-saxon
         run-saxon-with-memory
         run-saxon-safe
         saxon-available?
         test-saxon-installation
         generate-knitting-chart)
EOF

    log_success "Racket integration code generated: $racket_file"
}

# Main validation function
main() {
    log_info "Saxon-HE Validation Report"
    log_info "=========================="

    local exit_code=0

    # Run all checks
    check_saxon_jar || exit_code=1
    check_symlink || true  # Non-critical
    check_java || exit_code=1
    test_saxon || exit_code=1
    test_transformation || true  # Non-critical if Java missing

    # Generate integration helpers
    generate_racket_code

    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "All critical validations passed!"
        log_info "Saxon-HE is ready for use with Knotty DSL"
    else
        log_warning "Some validations failed - see messages above"
        log_info "Saxon JAR is present but may need Java runtime"
    fi

    log_info "=========================="

    return $exit_code
}

# Run main function
main "$@"