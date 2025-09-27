# Platform-Specific Notes

This guide provides platform-specific considerations, optimizations, and troubleshooting for AI agents working with Knotty across different operating systems and environments.

## macOS

### System Requirements
- macOS 10.15 (Catalina) or later
- Xcode Command Line Tools
- 8GB+ RAM recommended

### Installation
```bash
# Install Homebrew (if not present)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js via Homebrew
brew install node@20
brew link node@20
```

### Apple Silicon (M1/M2/M3) Optimizations
```bash
# Check architecture
uname -m  # Should show arm64

# Optimize for Apple Silicon
export NODE_OPTIONS="--max-old-space-size=8192"
export PARCEL_WORKERS=8

# Use native ARM64 packages
npm config set target_arch arm64
```

### Common Issues
**Xcode Command Line Tools Missing:**
```bash
xcode-select --install
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

**Permission Issues:**
```bash
sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}
```

## Ubuntu/Debian

### System Requirements
- Ubuntu 20.04 LTS+ / Debian 11+
- 4GB+ RAM (8GB+ recommended)

### Installation
```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js and build tools
sudo apt-get install -y nodejs build-essential python3-dev git curl
```

### Performance Optimizations
```bash
# Increase file watch limits
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
echo fs.inotify.max_queued_events=16384 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Optimize memory usage
export NODE_OPTIONS="--max-old-space-size=4096"
export PARCEL_WORKERS=$(nproc)
```

### Common Issues
**Permission Problems:**
```bash
# Use nvm instead of system Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
```

**Build Tools Missing:**
```bash
sudo apt-get install -y build-essential python3-dev
```

## Windows with WSL2

### System Requirements
- Windows 10 version 2004+ or Windows 11
- WSL2 enabled
- 8GB+ RAM recommended

### Setup
```powershell
# Enable WSL2 (run as Administrator)
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Install Ubuntu
wsl --install -d Ubuntu-20.04
```

### Best Practices
```bash
# IMPORTANT: Keep files in WSL2 filesystem for performance
# Use ~/workspace instead of /mnt/c/

# Configure git for WSL2
git config --global core.autocrlf false
git config --global core.filemode false

# Optimize for WSL2
export NODE_OPTIONS="--max-old-space-size=3072"
export PARCEL_WORKERS=4
```

### Common Issues
**Slow Performance:**
```bash
# Move project to WSL2 filesystem
cp -r /mnt/c/Users/YourName/knotty ~/workspace/knotty
cd ~/workspace/knotty
```

**Line Ending Issues:**
```bash
# Fix line endings
find . -type f -name "*.js" -o -name "*.json" | xargs dos2unix
git config --global core.eol lf
```

## Alpine Linux

### Installation
```bash
# Update and install packages
apk update
apk add --no-cache nodejs npm python3 make g++ linux-headers git curl
```

### Optimizations
```bash
# Alpine-specific memory settings
export MALLOC_ARENA_MAX=2
export NODE_OPTIONS="--max-old-space-size=2048"
export PARCEL_WORKERS=2
```

### Common Issues
**Native Module Compilation:**
```bash
# Install additional build tools
apk add --no-cache libc6-compat
```

## Cross-Platform Scripts

### Universal Setup Script
```bash
#!/bin/bash
# cross-platform-setup.sh

# Detect platform
PLATFORM=$(uname -s)
ARCH=$(uname -m)

case "$PLATFORM" in
  Darwin)
    echo "Configuring for macOS..."
    export NODE_OPTIONS="--max-old-space-size=4096"
    if [[ "$ARCH" == "arm64" ]]; then
      export PARCEL_WORKERS=8
    else
      export PARCEL_WORKERS=4
    fi
    ;;
  Linux)
    echo "Configuring for Linux..."
    export NODE_OPTIONS="--max-old-space-size=4096"
    export PARCEL_WORKERS=$(nproc)
    ;;
  MINGW*|MSYS*|CYGWIN*)
    echo "Configuring for Windows..."
    export NODE_OPTIONS="--max-old-space-size=3072"
    export PARCEL_WORKERS=4
    ;;
  *)
    echo "Unknown platform: $PLATFORM"
    export NODE_OPTIONS="--max-old-space-size=2048"
    export PARCEL_WORKERS=2
    ;;
esac

echo "Platform: $PLATFORM $ARCH"
echo "Memory: ${NODE_OPTIONS}"
echo "Workers: ${PARCEL_WORKERS}"
```

### Environment Detection
```javascript
// Platform detection in Node.js
const os = require('os');

function getPlatformConfig() {
  const platform = os.platform();
  const arch = os.arch();
  const cpus = os.cpus().length;
  const memory = Math.round(os.totalmem() / 1024 / 1024 / 1024);

  const config = {
    darwin: {
      workers: arch === 'arm64' ? 8 : 4,
      memory: 4096
    },
    linux: {
      workers: cpus,
      memory: 4096
    },
    win32: {
      workers: 4,
      memory: 3072
    }
  };

  return config[platform] || { workers: 2, memory: 2048 };
}
```

## Best Practices

1. **Always test on multiple platforms** before deployment
2. **Use environment variables** for platform-specific settings
3. **Provide fallback configurations** for unknown platforms
4. **Document platform-specific requirements** clearly
5. **Use cross-platform tools** when possible

This guide ensures AI agents can successfully deploy and optimize Knotty across all supported environments.