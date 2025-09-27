# AI Rebuild Troubleshooting Guide

This guide helps AI agents diagnose and resolve common issues during Knotty setup and operation.

## Diagnostic Tools

### Quick Health Check
```bash
#!/bin/bash
echo "=== Knotty Environment Diagnostics ==="
echo "Platform: $(uname -a)"
echo "Node.js: $(node --version 2>/dev/null || echo 'NOT FOUND')"
echo "npm: $(npm --version 2>/dev/null || echo 'NOT FOUND')"
echo "Git: $(git --version 2>/dev/null || echo 'NOT FOUND')"
echo "Disk space: $(df -h . | tail -1)"
echo "Package.json exists: $(test -f package.json && echo 'YES' || echo 'NO')"
echo "Node_modules exists: $(test -d node_modules && echo 'YES' || echo 'NO')"
```

## Common Issues and Solutions

### Installation Problems

**Error: Node.js Version Incompatible**
```bash
# Solution: Install correct Node.js version
nvm install 20
nvm use 20
node --version  # Verify
```

**Error: Permission Denied**
```bash
# Solution: Fix npm permissions
sudo chown -R $(whoami) ~/.npm
sudo chown -R $(whoami) /usr/local/lib/node_modules

# Or use nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
```

**Error: Network Timeout**
```bash
# Solution: Increase timeout and clear cache
npm config set timeout 60000
npm cache clean --force
npm install
```

**Error: Disk Space**
```bash
# Solution: Clear caches and check space
npm cache clean --force
rm -rf node_modules/ .parcel-cache/
df -h  # Check available space
```

### Build Problems

**Error: Parcel Build Fails**
```bash
# Solution: Clean and rebuild
rm -rf .parcel-cache/ dist/
rm -rf node_modules/
npm install
npm run build
```

**Error: Module Not Found**
```bash
# Solution: Check dependencies and paths
npm list --depth=0
ls -la src/
npm install  # Reinstall if needed
```

### Runtime Errors

**Error: Development Server Won't Start**
```bash
# Check what's using the port
lsof -i :1234
# Kill process if needed
lsof -ti:1234 | xargs kill -9
# Start on different port
PORT=3000 npm run dev
```

**Error: Hot Reload Not Working**
```bash
# Solution: Clear cache and restart
rm -rf .parcel-cache/
npm run dev

# On Linux, increase file watchers
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## Platform-Specific Issues

### macOS
**Xcode Tools Missing:**
```bash
xcode-select --install
```

### Ubuntu/Debian
**Build Tools Missing:**
```bash
sudo apt-get update
sudo apt-get install -y build-essential python3-dev
```

### Windows WSL2
**Slow Performance:**
```bash
# Move project to WSL2 filesystem
cp -r /mnt/c/Users/*/knotty ~/knotty
cd ~/knotty
```

## Automated Recovery

### Complete Reset Script
```bash
#!/bin/bash
echo "Starting complete reset..."

# Stop any running processes
pkill -f parcel
pkill -f node

# Clean all caches and builds
rm -rf node_modules/ dist/ .parcel-cache/ package-lock.json

# Clear npm cache
npm cache clean --force

# Reinstall from scratch
npm install

# Verify installation
npm run build

echo "Reset complete. Run 'npm run dev' to start development."
```

## When to Escalate

Escalate to human intervention when:
1. Multiple recovery attempts fail
2. System-level configuration issues persist
3. Hardware limitations prevent operation
4. Security/permission issues require administrative access

Always provide detailed logs and environment information when escalating.