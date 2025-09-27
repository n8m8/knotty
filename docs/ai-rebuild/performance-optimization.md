# Performance Optimization Guide

This guide provides strategies for AI agents to optimize Knotty's build performance, runtime efficiency, and resource utilization.

## Performance Targets

### Build Performance
- **Cold build:** <30 seconds
- **Incremental build:** <5 seconds
- **Hot reload:** <1 second
- **Memory usage:** <2GB during build

### Runtime Performance
- **Initial load:** <3 seconds
- **Bundle size:** <500KB gzipped
- **Memory usage:** <100MB in browser
- **Frame rate:** 60fps for animations

## Build Optimization

### Environment Variables for Performance
```bash
# Increase Node.js memory limit
export NODE_OPTIONS="--max-old-space-size=4096"

# Enable parallel processing
export PARCEL_WORKERS=4

# Optimize for SSD
export PARCEL_CACHE_DIR=".parcel-cache"
```

### Build Cache Optimization
```bash
#!/bin/bash
# optimize-cache.sh

# Ensure cache directory exists with optimal permissions
mkdir -p .parcel-cache
chmod 755 .parcel-cache

# Clean stale cache entries
find .parcel-cache -type f -mtime +7 -delete
```

## Bundle Optimization

### Dynamic Imports
```javascript
// Lazy load heavy components
const HeavyComponent = lazy(() => import('./HeavyComponent'));

// Split vendor bundles
const d3 = () => import('d3');

// Route-based splitting
const routes = [
  {
    path: '/visualizer',
    component: lazy(() => import('./pages/Visualizer'))
  }
];
```

### Bundle Analysis
```bash
# Analyze bundle composition
npm run analyze:bundle

# Check gzip sizes
npm run size-check
```

## Platform-Specific Optimizations

### macOS Optimizations
```bash
# Use Apple Silicon optimizations
if [[ $(uname -m) == "arm64" ]]; then
  export NODE_OPTIONS="--max-old-space-size=8192"
  export PARCEL_WORKERS=8
fi
```

### Linux Optimizations
```bash
# Increase file watch limits
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# CPU-specific optimizations
export PARCEL_WORKERS=$(nproc)
```

### Windows (WSL2) Optimizations
```bash
# Use WSL2 filesystem for better performance
# Move project to ~/workspace instead of /mnt/c/

# Windows-specific memory settings
export NODE_OPTIONS="--max-old-space-size=3072"
```

## Performance Monitoring

### Build Performance Benchmarks
```bash
#!/bin/bash
# benchmark-build.sh

echo "=== Build Performance Benchmark ==="

# Cold build benchmark
echo "Cold build test..."
rm -rf dist/ .parcel-cache/
time npm run build

# Incremental build benchmark
echo "Incremental build test..."
touch src/index.js
time npm run build

echo "=== Benchmark Complete ==="
```

### Performance Alerts
```bash
#!/bin/bash
# performance-check.sh

BUILD_TIME=$(time npm run build 2>&1 | grep real | awk '{print $2}')
BUNDLE_SIZE=$(stat -c%s dist/index.js)

# Alert if build time > 30s
if [[ $BUILD_TIME > "30.0s" ]]; then
  echo "⚠️  Build time exceeded 30s: $BUILD_TIME"
fi

# Alert if bundle size > 500KB
if [[ $BUNDLE_SIZE -gt 512000 ]]; then
  echo "⚠️  Bundle size exceeded 500KB: $(($BUNDLE_SIZE / 1024))KB"
fi
```

## Automated Optimization

### Auto-optimization Script
```bash
#!/bin/bash
# auto-optimize.sh

echo "🚀 Starting auto-optimization..."

# Optimize dependencies
npm audit fix
npm dedupe

# Update to latest compatible versions
npm update

# Clean and rebuild with optimizations
rm -rf node_modules/ .parcel-cache/
npm install
NODE_OPTIONS="--max-old-space-size=4096" npm run build:prod

echo "✅ Optimization complete"
```

## Performance Checklist

### Pre-deployment Checklist
- [ ] Build time <30 seconds
- [ ] Bundle size <500KB gzipped
- [ ] Memory usage <2GB during build
- [ ] No memory leaks detected
- [ ] All performance tests pass

Use this guide to maintain optimal performance across all environments and ensure the AI rebuild system operates efficiently at scale.