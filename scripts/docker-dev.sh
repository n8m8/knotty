#!/bin/bash

# Docker Development Helper Script for Knotty DSL
# Provides convenient commands for Docker-based development

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Check if Docker and Docker Compose are available
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed or not in PATH"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Docker Development Helper for Knotty DSL

Usage: $0 <command> [options]

Commands:
    setup           Initial setup of development environment
    dev             Start development environment
    test            Run tests in container
    build           Build all Docker images
    clean           Clean up containers and volumes
    shell           Open shell in development container
    logs            Show logs from containers
    status          Show status of all containers
    validate        Validate Saxon and environment setup
    docs            Start documentation server
    full            Start full development stack
    stop            Stop all containers
    restart         Restart development environment

Examples:
    $0 setup           # First-time setup
    $0 dev             # Start development environment
    $0 test            # Run all tests
    $0 shell           # Open interactive shell
    $0 clean           # Clean up everything

Environment Variables:
    KNOTTY_PROFILE     Docker Compose profile to use (default: development)
    KNOTTY_BUILD_ARGS  Additional build arguments
    KNOTTY_DETACH      Run in detached mode (true/false)

EOF
}

# Setup function
setup_environment() {
    log_info "Setting up Knotty DSL development environment..."

    # Create necessary directories
    mkdir -p "$PROJECT_ROOT"/{cache,logs,test-results,coverage}

    # Download Saxon if not present
    if [ ! -f "$PROJECT_ROOT/lib/saxon-he-12.9.jar" ]; then
        log_info "Downloading Saxon XSLT processor..."
        cd "$PROJECT_ROOT/lib"
        if [ -x "./download-saxon.sh" ]; then
            ./download-saxon.sh
        else
            log_warning "Saxon download script not found, will download in container"
        fi
    fi

    # Build base development image
    log_info "Building development Docker image..."
    docker-compose -f "$COMPOSE_FILE" build knotty-dev

    log_success "Setup complete! Use '$0 dev' to start development environment"
}

# Start development environment
start_dev() {
    local detach=""
    if [ "${KNOTTY_DETACH:-false}" = "true" ]; then
        detach="-d"
    fi

    log_info "Starting Knotty DSL development environment..."
    docker-compose -f "$COMPOSE_FILE" --profile ${KNOTTY_PROFILE:-development} up $detach knotty-dev
}

# Run tests
run_tests() {
    log_info "Running Knotty DSL tests..."
    docker-compose -f "$COMPOSE_FILE" --profile testing up --build knotty-test
}

# Build all images
build_images() {
    log_info "Building all Docker images..."
    docker-compose -f "$COMPOSE_FILE" build --parallel
    log_success "All images built successfully"
}

# Clean up
cleanup() {
    log_warning "This will remove all Knotty DSL containers and volumes!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Stopping containers..."
        docker-compose -f "$COMPOSE_FILE" down --remove-orphans

        log_info "Removing volumes..."
        docker volume rm $(docker volume ls -q | grep knotty) 2>/dev/null || true

        log_info "Removing images..."
        docker rmi $(docker images --filter "reference=knotty*" -q) 2>/dev/null || true

        log_success "Cleanup complete"
    else
        log_info "Cleanup cancelled"
    fi
}

# Open shell in development container
open_shell() {
    log_info "Opening shell in development container..."

    # Check if container is running
    if ! docker-compose -f "$COMPOSE_FILE" ps knotty-dev | grep -q "Up"; then
        log_info "Development container not running, starting it..."
        docker-compose -f "$COMPOSE_FILE" up -d knotty-dev
        sleep 5
    fi

    docker-compose -f "$COMPOSE_FILE" exec knotty-dev /bin/bash
}

# Show logs
show_logs() {
    local service="${1:-}"
    if [ -n "$service" ]; then
        docker-compose -f "$COMPOSE_FILE" logs -f "$service"
    else
        docker-compose -f "$COMPOSE_FILE" logs -f
    fi
}

# Show status
show_status() {
    log_info "Container status:"
    docker-compose -f "$COMPOSE_FILE" ps

    log_info "Volume usage:"
    docker volume ls | grep knotty || echo "No Knotty volumes found"

    log_info "Image sizes:"
    docker images | grep knotty || echo "No Knotty images found"
}

# Validate environment
validate_environment() {
    log_info "Validating Knotty DSL environment..."

    # Check if Saxon JAR exists
    if [ -f "$PROJECT_ROOT/lib/saxon-he-12.9.jar" ]; then
        log_success "Saxon XSLT processor found"
    else
        log_warning "Saxon XSLT processor not found locally"
    fi

    # Test in container
    log_info "Testing Saxon in container..."
    docker-compose -f "$COMPOSE_FILE" run --rm knotty-dev \
        racket -e "(require \"lib/saxon-integration.rkt\") (test-saxon-installation)"

    log_info "Testing path resolver..."
    docker-compose -f "$COMPOSE_FILE" run --rm knotty-dev \
        racket -e "(require \"lib/path-resolver.rkt\") (displayln (get-resource-info))"

    log_success "Environment validation complete"
}

# Start documentation server
start_docs() {
    log_info "Starting documentation server..."
    docker-compose -f "$COMPOSE_FILE" --profile docs up -d docs-server
    log_success "Documentation server started at http://localhost:8082"
}

# Start full stack
start_full() {
    log_info "Starting full development stack..."
    docker-compose -f "$COMPOSE_FILE" --profile full up -d
    log_success "Full stack started"
}

# Stop containers
stop_containers() {
    log_info "Stopping all containers..."
    docker-compose -f "$COMPOSE_FILE" down
    log_success "All containers stopped"
}

# Restart development environment
restart_dev() {
    log_info "Restarting development environment..."
    docker-compose -f "$COMPOSE_FILE" restart knotty-dev
    log_success "Development environment restarted"
}

# Main script logic
main() {
    check_docker

    case "${1:-}" in
        "setup")
            setup_environment
            ;;
        "dev")
            start_dev
            ;;
        "test")
            run_tests
            ;;
        "build")
            build_images
            ;;
        "clean")
            cleanup
            ;;
        "shell")
            open_shell
            ;;
        "logs")
            show_logs "${2:-}"
            ;;
        "status")
            show_status
            ;;
        "validate")
            validate_environment
            ;;
        "docs")
            start_docs
            ;;
        "full")
            start_full
            ;;
        "stop")
            stop_containers
            ;;
        "restart")
            restart_dev
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        "")
            log_error "No command specified"
            show_usage
            exit 1
            ;;
        *)
            log_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"