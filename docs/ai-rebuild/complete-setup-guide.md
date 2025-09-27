# Complete AI Rebuild Setup Guide

This guide provides comprehensive setup instructions for AI agents to autonomously rebuild and work with the Knotty project.

## Quick Start for AI Agents

```bash
# Clone and setup
git clone <repository-url> knotty
cd knotty

# Install dependencies
npm install

# Build project (target: <30 seconds)
npm run build

# Start development server
npm run dev
```

## Prerequisites

### System Requirements
- Node.js 18+ or 20+ (LTS recommended)
- npm 9+ or yarn 1.22+
- Git 2.20+
- 4GB+ available disk space

### Platform Support
- macOS 10.15+ (Catalina)
- Ubuntu 20.04+ / Debian 11+
- Windows 10+ with WSL2
- Alpine Linux 3.15+

## Environment Validation

```bash
# Check versions
node --version  # Should be 18.x, 20.x, or 21.x
npm --version   # Should be 9.x or higher
git --version   # Should be 2.20+

# Check disk space
df -h .         # Should show 4GB+ available
```

## Troubleshooting

### Common Issues

**Node.js Version Mismatch:**
```bash
# Install correct version with nvm
nvm install 20
nvm use 20
```

**Permission Errors:**
```bash
# Fix npm permissions
sudo chown -R $(whoami) ~/.npm
```

**Build Failures:**
```bash
# Clean and rebuild
rm -rf node_modules/ .parcel-cache/ dist/
npm install
npm run build
```

**Memory Issues:**
```bash
# Increase Node.js memory limit
export NODE_OPTIONS="--max-old-space-size=4096"
npm run build
```

## Performance Targets

- **Build time:** <30 seconds (cold build)
- **Bundle size:** <500KB gzipped
- **Memory usage:** <2GB during build
- **Hot reload:** <1 second response time

## Success Criteria

Setup is complete when:
- [ ] All dependencies install without errors
- [ ] `npm run build` completes in <30 seconds
- [ ] `npm run dev` starts development server
- [ ] Examples load and function correctly

This guide enables AI agents to perform autonomous setup with comprehensive error recovery and validation procedures.