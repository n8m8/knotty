# Docker Development Environment for Knotty DSL

This document provides comprehensive information about the Docker-based development environment for the Knotty DSL project. The containerized setup ensures consistent development environments across platforms and enables AI development agents to rebuild the project reliably.

## Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- 4GB+ available RAM
- 2GB+ available disk space

### Basic Setup

```bash
# Clone the repository
git clone https://github.com/your-org/knotty.git
cd knotty

# Initial setup
./scripts/docker-dev.sh setup

# Start development environment
./scripts/docker-dev.sh dev
```

## Architecture Overview

The Docker environment provides multiple service configurations:

### Core Services

- **knotty-dev**: Main development environment with full Racket and Java setup
- **knotty-test**: Testing environment with coverage and CI tools
- **knotty-prod**: Production simulation with minimal runtime
- **saxon-validator**: Dedicated XSLT validation service

### Optional Services

- **docs-server**: Documentation generation and serving
- **pattern-db**: PostgreSQL database for pattern storage
- **pattern-cache**: Redis cache for performance
- **performance-monitor**: Prometheus monitoring stack

## Service Profiles

Use Docker Compose profiles to control which services start:

```bash
# Basic development (default)
docker-compose up

# Include testing services
docker-compose --profile testing up

# Full stack with database and monitoring
docker-compose --profile full up

# Documentation server only
docker-compose --profile docs up docs-server
```

## Development Workflow

### Daily Development

```bash
# Start development environment
./scripts/docker-dev.sh dev

# Open interactive shell
./scripts/docker-dev.sh shell

# Run tests
./scripts/docker-dev.sh test

# View logs
./scripts/docker-dev.sh logs
```

### Inside the Container

Once inside the development container:

```bash
# Compile Racket modules
raco make lib/*.rkt

# Run specific tests
raco test tests/test-saxon-integration.rkt

# Generate documentation
raco scribble docs/manual.scrbl

# Validate Saxon setup
racket -e "(require \"lib/saxon-integration.rkt\") (test-saxon-installation)"
```

## Container Details

### Development Container (`knotty-dev`)

**Base Image**: `racket/racket:8.11-full`

**Installed Tools**:
- Racket 8.11+ with full package set
- OpenJDK 17 for Saxon XSLT processing
- Saxon-HE 12.9 JAR file
- Development fonts and symbol libraries
- Git, editors, and debugging tools

**Volumes**:
- Project source: `/app` (live mount)
- Cache: `/app/cache` (persistent)
- Logs: `/app/logs` (persistent)
- Resources: `/app/resources` (persistent)

**Environment Variables**:
- `KNOTTY_ENV=development`
- `JAVA_HOME=/opt/java/openjdk`
- `RACKET_VERSION=8.11`

### Testing Container (`knotty-test`)

Extends the development container with:
- Code coverage tools (`cover`, `lcov`)
- CI/CD utilities
- Performance benchmarking tools
- Automated test runners

### Production Container (`knotty-prod`)

Minimal runtime container with:
- Racket runtime (minimal install)
- OpenJDK 17 JRE
- Saxon XSLT processor
- Production-optimized resource files

## File Structure

```
/app/                           # Container working directory
├── lib/                        # Core library modules
│   ├── saxon-integration.rkt   # Enhanced XSLT processing
│   ├── font-manager.rkt        # Font and symbol management
│   ├── path-resolver.rkt       # Cross-platform path handling
│   └── saxon-he-12.9.jar      # Saxon XSLT processor
├── resources/                  # Static resources
│   ├── fonts/                  # Knitting symbol fonts
│   ├── symbols/               # SVG symbol library
│   └── templates/             # XSLT templates
├── cache/                      # Build and runtime cache
├── logs/                       # Application logs
├── tests/                      # Test suites
└── examples/                   # Example patterns
```

## Resource Management

### Saxon XSLT Processor

The Saxon JAR is automatically downloaded during container build:

```racket
;; Test Saxon installation
(require "lib/saxon-integration.rkt")
(test-saxon-installation)

;; Run XSLT transformation
(run-saxon "input.xml" "transform.xsl" "output.svg")
```

### Font and Symbol Management

```racket
;; Access knitting symbols
(require "lib/font-manager.rkt")

;; Render symbol as SVG
(render-symbol "k2tog" #:size "24" #:color "blue")

;; Get Unicode fallback
(get-unicode-symbol "cable-4-front")
```

### Cross-Platform Paths

```racket
;; Resolve resource paths
(require "lib/path-resolver.rkt")

;; Get platform-appropriate paths
(resolve-resource-path 'symbols "cable-patterns")
(find-java-executable)
(validate-java-installation)
```

## Persistent Data

### Named Volumes

- `knotty-cache`: Build artifacts and temporary files
- `knotty-logs`: Application and system logs
- `knotty-resources`: Downloaded fonts and symbols
- `pattern-db-data`: PostgreSQL database (if using database profile)
- `pattern-cache-data`: Redis cache data

### Volume Management

```bash
# List volumes
docker volume ls | grep knotty

# Backup volume
docker run --rm -v knotty-cache:/data -v $(pwd):/backup alpine tar czf /backup/cache-backup.tar.gz -C /data .

# Restore volume
docker run --rm -v knotty-cache:/data -v $(pwd):/backup alpine tar xzf /backup/cache-backup.tar.gz -C /data
```

## Performance Considerations

### Resource Requirements

**Minimum**:
- 2 CPU cores
- 4GB RAM
- 2GB disk space

**Recommended**:
- 4+ CPU cores
- 8GB RAM
- 10GB disk space

### Build Optimization

```bash
# Build with BuildKit for faster builds
DOCKER_BUILDKIT=1 docker-compose build

# Use build cache
docker-compose build --build-arg BUILDKIT_INLINE_CACHE=1
```

### Runtime Optimization

```bash
# Adjust Java heap for Saxon
export SAXON_MEMORY=2048m

# Use production profile for deployment
docker-compose --profile production up -d knotty-prod
```

## Debugging and Troubleshooting

### Common Issues

1. **Saxon JAR not found**:
   ```bash
   # Re-download Saxon
   docker-compose exec knotty-dev bash -c "cd lib && ./download-saxon.sh"
   ```

2. **Java version incompatible**:
   ```bash
   # Check Java version
   docker-compose exec knotty-dev java -version
   ```

3. **Permission errors**:
   ```bash
   # Fix ownership
   docker-compose exec knotty-dev chown -R knotty:knotty /app
   ```

### Debug Mode

```bash
# Start with debug logging
KNOTTY_LOG_LEVEL=debug docker-compose up knotty-dev

# Enable Racket tracing
RACKET_TRACE=1 docker-compose up knotty-dev
```

### Health Checks

All containers include health checks:

```bash
# Check container health
docker-compose ps

# View health check logs
docker inspect --format='{{json .State.Health}}' knotty-development | jq
```

## Security Considerations

### Network Isolation

Containers communicate through the `knotty-dev-network` bridge network, isolated from the host network by default.

### Volume Security

- Cache and logs use named volumes (not host mounts)
- Source code is mounted read-write for development
- Production containers use read-only mounts where possible

### User Permissions

Development containers run as the `knotty` user (non-root) for security.

## CI/CD Integration

### GitHub Actions

```yaml
# Example workflow
- name: Test in Docker
  run: |
    docker-compose --profile testing up --build --abort-on-container-exit knotty-test
```

### Local Testing

```bash
# Simulate CI environment
CI=true ./scripts/docker-dev.sh test
```

## Monitoring and Observability

### Prometheus Metrics

When using the monitoring profile:
- Prometheus: http://localhost:9090
- Application metrics: http://localhost:8080/metrics

### Log Aggregation

```bash
# View all service logs
docker-compose logs -f

# Filter by service
docker-compose logs -f knotty-dev

# Export logs
docker-compose logs --no-color > knotty-logs.txt
```

## Advanced Configuration

### Environment Variables

Create `.env` file for custom configuration:

```bash
# Docker Compose environment
COMPOSE_PROJECT_NAME=knotty-custom
KNOTTY_PROFILE=development

# Application configuration
KNOTTY_LOG_LEVEL=info
SAXON_MEMORY=1024m
JAVA_OPTS=-Xms512m -Xmx2048m

# Database configuration (if using)
POSTGRES_DB=my_patterns
POSTGRES_USER=developer
POSTGRES_PASSWORD=secure_password
```

### Custom Images

Build with custom arguments:

```bash
# Custom Java version
docker-compose build --build-arg JAVA_VERSION=11 knotty-dev

# Development tools
docker-compose build --build-arg BUILD_TYPE=development-extended knotty-dev
```

## Maintenance

### Regular Tasks

```bash
# Update base images
docker-compose pull

# Rebuild with latest dependencies
docker-compose build --no-cache

# Clean up unused resources
docker system prune -f

# Update Saxon processor
docker-compose exec knotty-dev bash -c "cd lib && ./download-saxon.sh"
```

### Backup Strategy

```bash
# Backup script example
#!/bin/bash
DATE=$(date +%Y%m%d-%H%M%S)
docker run --rm -v knotty-cache:/data -v $(pwd):/backup alpine \
  tar czf /backup/knotty-backup-${DATE}.tar.gz -C /data .
```

## Support and Contributing

### Getting Help

1. Check container logs: `docker-compose logs knotty-dev`
2. Validate environment: `./scripts/docker-dev.sh validate`
3. Open GitHub issue with container details

### Contributing

1. Test changes in container: `./scripts/docker-dev.sh test`
2. Ensure multi-platform compatibility
3. Update documentation for new features
4. Add appropriate health checks

## License

This Docker configuration is part of the Knotty DSL project and follows the same license terms.