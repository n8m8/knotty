#!/bin/bash

# Saxon-HE Download Script
# Downloads the specified version of Saxon-HE from Maven Central
# Usage: ./download-saxon.sh [version]
# Default version: 12.9

set -e

# Configuration
DEFAULT_VERSION="12.9"
VERSION="${1:-$DEFAULT_VERSION}"
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAR_NAME="saxon-he-${VERSION}.jar"
JAR_PATH="${LIB_DIR}/${JAR_NAME}"

# Maven Central URL pattern
MAVEN_BASE_URL="https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE"
DOWNLOAD_URL="${MAVEN_BASE_URL}/${VERSION}/Saxon-HE-${VERSION}.jar"

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

# Check if curl is available
check_curl() {
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi
}

# Check if Java is available
check_java() {
    if ! command -v java &> /dev/null; then
        log_warning "Java runtime not found in PATH"
        log_warning "Saxon requires Java 8+ to run"
        return 1
    else
        java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
        log_info "Java version detected: ${java_version}"
        return 0
    fi
}

# Validate version format
validate_version() {
    if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        log_error "Invalid version format: $VERSION"
        log_error "Expected format: X.Y or X.Y.Z (e.g., 12.9, 12.9.1)"
        exit 1
    fi
}

# Check if file already exists
check_existing() {
    if [[ -f "$JAR_PATH" ]]; then
        log_warning "Saxon-HE ${VERSION} already exists at: $JAR_PATH"
        read -p "Do you want to re-download? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Using existing JAR file"
            exit 0
        fi
    fi
}

# Test if URL exists
test_url() {
    log_info "Testing availability of Saxon-HE ${VERSION}..."
    if ! curl --head --silent --fail "$DOWNLOAD_URL" > /dev/null; then
        log_error "Saxon-HE version ${VERSION} not found at Maven Central"
        log_error "URL: $DOWNLOAD_URL"
        log_info "Available versions: https://mvnrepository.com/artifact/net.sf.saxon/Saxon-HE"
        exit 1
    fi
}

# Download Saxon JAR
download_saxon() {
    log_info "Downloading Saxon-HE ${VERSION} from Maven Central..."
    log_info "URL: $DOWNLOAD_URL"
    log_info "Destination: $JAR_PATH"

    # Create lib directory if it doesn't exist
    mkdir -p "$LIB_DIR"

    # Download with progress bar
    if curl -L --progress-bar -o "$JAR_PATH" "$DOWNLOAD_URL"; then
        log_success "Downloaded Saxon-HE ${VERSION}"
    else
        log_error "Failed to download Saxon-HE ${VERSION}"
        # Clean up partial download
        [[ -f "$JAR_PATH" ]] && rm "$JAR_PATH"
        exit 1
    fi
}

# Verify downloaded JAR
verify_jar() {
    log_info "Verifying downloaded JAR file..."

    # Check file size (Saxon-HE 12.9 is ~5.5MB)
    file_size=$(stat -f%z "$JAR_PATH" 2>/dev/null || stat -c%s "$JAR_PATH" 2>/dev/null)
    if [[ $file_size -lt 1000000 ]]; then
        log_error "Downloaded file appears too small (${file_size} bytes)"
        exit 1
    fi

    # Test JAR file integrity
    if command -v java &> /dev/null; then
        log_info "Testing JAR file with Java..."
        if java -jar "$JAR_PATH" -t > /dev/null 2>&1; then
            log_success "JAR file verified successfully"
        else
            log_warning "JAR file test failed (may still be functional)"
        fi
    else
        log_warning "Cannot verify JAR without Java runtime"
    fi

    log_info "File size: ${file_size} bytes"
}

# Create symlink for generic filename
create_symlink() {
    local generic_name="saxon-he-12.x.jar"
    local symlink_path="${LIB_DIR}/${generic_name}"

    # Remove existing symlink
    [[ -L "$symlink_path" ]] && rm "$symlink_path"

    # Create new symlink
    if ln -sf "$JAR_NAME" "$symlink_path"; then
        log_info "Created symlink: $generic_name -> $JAR_NAME"
    else
        log_warning "Failed to create symlink (not critical)"
    fi
}

# Display usage instructions
show_usage() {
    echo "Saxon-HE Download Script"
    echo ""
    echo "Usage: $0 [version]"
    echo ""
    echo "Arguments:"
    echo "  version    Saxon-HE version to download (default: $DEFAULT_VERSION)"
    echo ""
    echo "Examples:"
    echo "  $0           # Download version $DEFAULT_VERSION"
    echo "  $0 12.8      # Download version 12.8"
    echo "  $0 11.7      # Download version 11.7"
    echo ""
    echo "The downloaded JAR will be placed in: $LIB_DIR"
}

# Clean up old versions
cleanup_old_versions() {
    log_info "Checking for old Saxon versions..."

    # Find all Saxon JAR files except the current one
    old_files=$(find "$LIB_DIR" -name "saxon-he-*.jar" ! -name "$JAR_NAME" 2>/dev/null || true)

    if [[ -n "$old_files" ]]; then
        log_warning "Found old Saxon versions:"
        echo "$old_files"
        read -p "Remove old versions? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$old_files" | xargs rm -f
            log_success "Removed old versions"
        fi
    fi
}

# Main execution
main() {
    # Show help if requested
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi

    log_info "Saxon-HE Download Script"
    log_info "Target version: $VERSION"

    # Perform checks
    validate_version
    check_curl
    check_java
    check_existing
    test_url

    # Download and verify
    download_saxon
    verify_jar
    create_symlink
    cleanup_old_versions

    log_success "Saxon-HE ${VERSION} installation complete!"
    log_info "JAR location: $JAR_PATH"

    # Display integration example
    echo ""
    log_info "Racket integration example:"
    echo "  (define saxon-jar-path \"$JAR_PATH\")"
    echo "  (system (format \"java -jar ~a -s:input.xml -xsl:transform.xsl -o:output.xml\" saxon-jar-path))"
}

# Run main function
main "$@"