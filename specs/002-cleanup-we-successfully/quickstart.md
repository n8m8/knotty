# Quickstart: AI Rebuild Validation

**Feature**: Specification Cleanup and AI Rebuild Enablement
**Purpose**: Step-by-step validation guide for autonomous project reconstruction
**Target**: AI development agents and automated systems

## Prerequisites Verification

### 1. Platform Compatibility Check
```bash
# Verify target platform
uname -a  # Linux/macOS
systeminfo | findstr "OS Name"  # Windows

# Expected: Supported platform (Linux, macOS, Windows)
```

### 2. Base Requirements Validation
```bash
# Check Git availability
git --version
# Expected: git version 2.0+

# Verify Docker availability (recommended)
docker --version
# Expected: Docker version 20.0+

# Check Java availability for Saxon XSLT
java -version
# Expected: Java 8+ runtime
```

## Environment Setup

### 3. Clone Project Repository
```bash
git clone <repository-url>
cd knotty
git checkout 002-cleanup-we-successfully

# Verify project structure
ls -la
# Expected: knotty-lib/, tests/, docs/, specs/, Makefile
```

### 4. Initialize Dependencies
```bash
# Option A: Docker Environment (Recommended)
docker build -t knotty-build .
docker run -it --rm -v $(pwd):/workspace knotty-build

# Option B: Native Environment
# Install Racket 8.8+
# Download from: https://download.racket-lang.org/

# Verify Racket installation
racket --version
# Expected: Racket v8.8+
```

### 5. Install Racket Dependencies
```bash
# Install project as package with dependencies
raco pkg install --deps search-auto --link knotty-lib/ knotty/

# Verify package installation
raco pkg show knotty knotty-lib
# Expected: Package information displayed
```

## Build Validation

### 6. Compile Project Libraries
```bash
# Compile all library modules
raco setup --no-docs --pkgs knotty-lib

# Expected: No compilation errors
# Output: Setup complete
```

### 7. Validate Saxon XSLT Integration
```bash
# Check Saxon JAR availability
find . -name "saxon-he-*.jar" 2>/dev/null
# Expected: Path to Saxon JAR file

# Test Saxon execution
java -jar <saxon-jar-path> -?
# Expected: Saxon help output
```

### 8. Execute Test Suite
```bash
# Run comprehensive test suite
raco test knotty-lib/

# Expected: All tests pass
# Output: All tests passed
```

## Functionality Verification

### 9. Test Core DSL Functionality
```bash
# Execute demo pattern
racket knotty-lib/demo.rkt

# Expected: Pattern output with instructions
# Verify: Chart generation, text instructions
```

### 10. Validate Export Capabilities
```bash
# Test HTML export functionality
# (Implementation-specific commands based on CLI)

# Expected: HTML files generated successfully
# Verify: Chart symbols rendered, CSS styling applied
```

### 11. Performance Benchmarking
```bash
# Measure compilation performance
time raco setup --pkgs knotty-lib

# Expected: Completion within reasonable time
# Benchmark: < 30 seconds on standard hardware
```

## Integration Testing

### 12. Cross-Platform Compatibility
```bash
# Test platform-specific functionality
# Run on each target platform: Linux, macOS, Windows

# Expected: Consistent behavior across platforms
# Verify: Same output files, no platform-specific errors
```

### 13. Dependency Resolution Validation
```bash
# Clean and reinstall dependencies
raco pkg remove knotty knotty-lib
raco pkg install --deps search-auto --link knotty-lib/ knotty/

# Expected: Successful reinstallation
# Verify: All dependencies resolved correctly
```

### 14. Build Artifact Verification
```bash
# Verify all expected artifacts are generated
ls -la compiled/
ls -la docs/
# Add other artifact locations

# Expected: All build artifacts present
# Verify: File sizes reasonable, no corruption
```

## Validation Checklist

### Environment Setup ✓
- [ ] Platform compatibility verified
- [ ] Git and Java available
- [ ] Docker environment functional (if used)
- [ ] Racket runtime installed and functional

### Dependency Management ✓
- [ ] Project repository cloned successfully
- [ ] Racket packages installed without errors
- [ ] Saxon XSLT processor available and functional
- [ ] All external dependencies resolved

### Build Process ✓
- [ ] Library compilation successful
- [ ] No compilation errors or warnings
- [ ] Test suite execution passes completely
- [ ] Demo functionality executes correctly

### Integration Validation ✓
- [ ] HTML export functionality working
- [ ] Chart generation producing expected output
- [ ] Cross-platform behavior consistent
- [ ] Performance within acceptable thresholds

### Quality Assurance ✓
- [ ] All functional requirements validated
- [ ] Error handling working correctly
- [ ] Documentation and examples functional
- [ ] Build artifacts complete and valid

## Success Criteria

### Complete Success
All checklist items pass, and the system can:
1. Generate knitting pattern charts
2. Export to multiple formats (HTML, Knitspeak)
3. Execute all test suites successfully
4. Perform consistently across target platforms
5. Complete rebuild within performance thresholds

### Partial Success
Most functionality works with minor issues:
- Document specific issues encountered
- Provide workarounds for known problems
- Identify platform-specific limitations
- Note performance variations

### Failure Analysis
If validation fails:
1. **Environment Issues**: Check platform compatibility and dependencies
2. **Build Failures**: Verify Racket installation and package dependencies
3. **Test Failures**: Investigate specific test failures and error messages
4. **Integration Problems**: Check Saxon XSLT and external tool configuration
5. **Performance Issues**: Analyze resource usage and optimization opportunities

## Troubleshooting

### Common Issues
1. **Saxon JAR Not Found**: Ensure JAR file is bundled or downloaded correctly
2. **Racket Package Conflicts**: Clear package cache and reinstall
3. **Platform-Specific Paths**: Verify path separators and file permissions
4. **Java Version Compatibility**: Ensure Java 8+ for Saxon requirements
5. **Docker Issues**: Check container permissions and volume mounting

### Recovery Procedures
1. **Clean Install**: Remove all packages and reinstall from scratch
2. **Container Reset**: Rebuild Docker container with fresh environment
3. **Dependency Reset**: Clear Racket package cache and reinstall
4. **Artifact Cleanup**: Remove generated files and rebuild completely

This quickstart guide ensures reliable validation of AI rebuild capabilities while providing comprehensive troubleshooting and recovery procedures for autonomous operation.