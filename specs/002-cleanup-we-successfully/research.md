# Research: Knotty DSL AI Rebuild Enablement Technology Analysis

**Feature**: Specification Cleanup and AI Rebuild Enablement
**Phase**: 0 - Outline & Research
**Date**: 2025-09-26

## Research Summary

This research addresses the technology requirements for enabling reliable, autonomous rebuilds of the Knotty DSL project by AI development agents. The analysis covers external dependencies, build environment standardization, and cross-platform deployment considerations that are critical for successful AI-driven project reconstruction.

## Technology Decisions

### Saxon XSLT Processor Integration

**Decision**: Saxon-HE 12.x with bundled JAR distribution
**Rationale**:
- XSLT 2.0/3.0 support required for advanced chart generation features
- Cross-platform Java portability ensures consistent behavior
- Bundled JAR approach eliminates system installation dependencies
- Command-line integration suitable for Racket system calls

**Alternatives considered**:
- xsltproc (libxslt): XSLT 1.0 only, insufficient for advanced features
- Apache Xalan: Development stalled, limited XSLT 2.0 support
- System package installation: Inconsistent across platforms and versions

**Implementation Strategy**:
```racket
(define saxon-jar-path (build-path resources-path "lib" "saxon-he-12.x.jar"))
(define (run-saxon input-xml xsl-file output-file)
  (system (format "java -jar ~a -s:~a -xsl:~a -o:~a"
                  saxon-jar-path input-xml xsl-file output-file)))
```

### Font Resource Management

**Decision**: SVG-based symbol rendering with Unicode fallbacks
**Rationale**:
- Eliminates font installation requirements across platforms
- Scalable vector graphics provide consistent symbol rendering
- Unicode fallback ensures basic functionality when symbols unavailable
- Legal distribution without font licensing concerns

**Alternatives considered**:
- Commercial knitting fonts: Licensing complexity and distribution restrictions
- System font dependencies: Inconsistent availability across platforms
- Icon font embedding: Browser compatibility and scaling issues

**Implementation Strategy**:
- Create SVG symbol library for knitting chart elements
- Implement Unicode character fallbacks for basic symbols
- Provide font installation documentation for enhanced rendering

### Racket Package Dependency Management

**Decision**: Git submodules with local catalog configuration
**Rationale**:
- Precise version control through commit-based dependencies
- Reproducible builds through locked dependency versions
- Local catalog provides controlled dependency resolution
- Compatible with existing Racket package infrastructure

**Alternatives considered**:
- Standard catalog dependencies: Version drift and reproducibility issues
- Manual dependency management: Complex and error-prone
- Binary package distribution: Build complexity and platform variations

**Implementation Strategy**:
```bash
# Create local package catalog
cd packages/
racket -l pkg/dirs-catalog --link catalog .
raco pkg config --set catalogs "file://$(pwd)/catalog" $(raco pkg config catalogs)
```

### Cross-Platform Build Environment

**Decision**: Docker containers with GitHub Actions matrix builds
**Rationale**:
- Consistent development environment across all platforms
- Automated cross-platform testing and validation
- Eliminates "works on my machine" issues for AI agents
- Standard containerization enables reproducible deployments

**Alternatives considered**:
- Native platform setup: Inconsistent environments and dependency conflicts
- Virtual machines: Resource overhead and slower build times
- Platform-specific build scripts: Maintenance complexity and drift

**Implementation Strategy**:
- Base image: `racket/racket:latest` with custom additions
- Multi-stage builds for optimized production containers
- GitHub Actions matrix for ubuntu-latest, windows-latest, macos-latest
- Environment variable abstraction for platform differences

### Build Tool Standardization

**Decision**: Custom Racket-based build system replacing GNU Make
**Rationale**:
- Cross-platform compatibility without external tool dependencies
- Native Racket integration with project modules and dependencies
- Simplified setup for AI agents without make installation requirements
- Better error handling and reporting through Racket exception system

**Alternatives considered**:
- GNU Make standardization: Windows compatibility issues
- CMake or Ninja: Additional dependency overhead
- Platform-specific build scripts: Maintenance and testing complexity

**Implementation Strategy**:
```racket
;; build.rkt - Custom build system
(define (build-target target)
  (match target
    ["test" (run-tests)]
    ["compile" (compile-libraries)]
    ["package" (create-distribution)]
    [_ (error "Unknown build target")]))
```

## External Dependencies Analysis

### Required Tools and Libraries
- **Java Runtime Environment**: JRE 8+ for Saxon XSLT processor
- **Racket Runtime**: Version 8.8+ with typed/racket support
- **Saxon XSLT Processor**: saxon-he-12.x.jar (bundled)
- **Git**: Version control and submodule dependency management

### Optional Enhancement Tools
- **Docker**: Container-based development environment
- **VS Code**: Development environment with Magic Racket extension
- **GitHub Actions**: Automated CI/CD and cross-platform testing

### Removed Dependencies
- **System Make**: Replaced with custom Racket build system
- **System Fonts**: Replaced with SVG symbol rendering
- **Package Manager Dependencies**: Replaced with bundled resources

## Performance Considerations

### Build Performance
- **Container Builds**: 2-3x slower than native but provides consistency
- **Package Installation**: Cached between builds for 5-10x speedup
- **Cross-Platform Testing**: Parallel matrix builds reduce total time

### Runtime Performance
- **Saxon XSLT**: Memory allocation with `-Xmx1024m` for large patterns
- **SVG Rendering**: Comparable performance to font-based rendering
- **Dependency Resolution**: Local catalog reduces network dependencies

### Scalability Factors
- **AI Agent Parallelization**: Independent build environments support concurrent rebuilds
- **Resource Requirements**: 2GB RAM minimum, 4GB recommended for complex patterns
- **Storage Requirements**: ~100MB for complete build environment

## Integration Points

### External Tool Integration
- **Java Process Execution**: Racket system calls with error handling
- **Git Submodule Management**: Automated initialization and updates
- **Container Orchestration**: Docker Compose for development environments

### CI/CD Integration
- **GitHub Actions**: Matrix builds with artifact collection
- **Package Distribution**: Automated releases with cross-platform binaries
- **Quality Gates**: Automated testing and validation before deployment

### Development Environment Integration
- **Dev Containers**: VS Code integration with pre-configured environment
- **Local Development**: Docker Compose setup with live reload
- **Testing Integration**: Automated test execution across platforms

## AI Rebuild Enablement

### Automation Requirements
- **Zero-Configuration Setup**: Container-based environment eliminates manual configuration
- **Dependency Validation**: Automated verification of all required components
- **Build Verification**: Comprehensive testing ensures successful reconstruction
- **Error Recovery**: Clear error messages and troubleshooting guidance

### Documentation Requirements
- **Setup Procedures**: Step-by-step instructions for each platform
- **Troubleshooting Guide**: Common issues and resolution procedures
- **Validation Checklist**: Verification steps for successful builds
- **Performance Benchmarks**: Expected build times and resource usage

### Quality Assurance
- **Reproducible Builds**: Identical outputs across platforms and build environments
- **Regression Testing**: Automated validation against reference implementations
- **Performance Monitoring**: Build time and resource usage tracking
- **Error Detection**: Comprehensive failure detection and reporting

## Research Conclusions

The enhanced build and dependency management strategy addresses all identified gaps for reliable AI-driven rebuilds. The combination of containerization, dependency bundling, and cross-platform standardization provides the foundation for autonomous project reconstruction while maintaining compatibility with the existing Knotty DSL implementation.

All technical decisions prioritize reproducibility and automation over performance, ensuring that AI agents can reliably rebuild the project across diverse environments and platforms. The research validates that this approach is feasible within the existing Racket ecosystem and compatible with current project architecture.