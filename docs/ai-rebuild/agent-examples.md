# AI Agent Integration Examples

This guide provides concrete examples of how AI agents can effectively interact with the Knotty rebuild system.

## Basic Setup Agent Example

```python
"""
Example: AI agent performing autonomous Knotty setup
"""
import subprocess
import os
import time

class KnottySetupAgent:
    def __init__(self, workspace_path):
        self.workspace = workspace_path
        self.setup_complete = False

    def execute_command(self, command, check=True):
        """Execute shell command with error handling"""
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                cwd=self.workspace
            )
            if check and result.returncode != 0:
                raise Exception(f"Command failed: {result.stderr}")
            return result
        except Exception as e:
            self.log_error(f"Command execution failed: {e}")
            raise

    def setup_project(self):
        """Complete project setup"""
        try:
            self.check_prerequisites()
            self.clean_existing_state()
            self.install_dependencies()
            self.perform_initial_build()
            self.validate_setup()

            self.setup_complete = True
            self.log_info("✅ Setup completed successfully")

        except Exception as e:
            self.log_error(f"❌ Setup failed: {e}")
            self.attempt_recovery()

    def check_prerequisites(self):
        """Verify system prerequisites"""
        self.log_info("Checking prerequisites...")

        # Check Node.js version
        result = self.execute_command("node --version")
        node_version = result.stdout.strip()
        if not any(v in node_version for v in ["v18.", "v20.", "v21."]):
            raise Exception(f"Unsupported Node.js version: {node_version}")

        self.log_info(f"Node.js: {node_version}")
        return True

    def install_dependencies(self):
        """Install project dependencies"""
        self.log_info("Installing dependencies...")
        start_time = time.time()

        result = self.execute_command("npm install")

        install_time = time.time() - start_time
        self.log_info(f"Dependencies installed in {install_time:.1f}s")

    def perform_initial_build(self):
        """Perform initial build and measure performance"""
        self.log_info("Performing initial build...")
        start_time = time.time()

        result = self.execute_command("npm run build")

        build_time = time.time() - start_time
        if build_time > 30:
            self.log_warning(f"Build time exceeded target: {build_time:.1f}s")
        else:
            self.log_info(f"✅ Build completed in {build_time:.1f}s")

    def attempt_recovery(self):
        """Attempt automatic recovery from setup failures"""
        self.log_info("Attempting automatic recovery...")

        recovery_steps = [
            ("Clear npm cache", "npm cache clean --force"),
            ("Reinstall dependencies", "rm -rf node_modules/ && npm install"),
            ("Clear all caches", "rm -rf .parcel-cache/ dist/"),
        ]

        for step_name, command in recovery_steps:
            try:
                self.log_info(f"Recovery step: {step_name}")
                self.execute_command(command)

                # Try build after each recovery step
                result = self.execute_command("npm run build", check=False)
                if result.returncode == 0:
                    self.log_info(f"✅ Recovery successful after: {step_name}")
                    return True

            except Exception as e:
                self.log_warning(f"Recovery step failed: {step_name} - {e}")

        return False

    def log_info(self, message):
        print(f"[INFO] {message}")

    def log_warning(self, message):
        print(f"[WARN] {message}")

    def log_error(self, message):
        print(f"[ERROR] {message}")

# Usage example
if __name__ == "__main__":
    agent = KnottySetupAgent("/path/to/knotty")
    agent.setup_project()
```

## Development Assistant Agent

```javascript
/**
 * Example: AI agent assisting with development workflows
 */
class KnottyDevelopmentAgent {
    constructor(projectPath) {
        this.projectPath = projectPath;
        this.devServer = null;
    }

    async startDevelopmentSession() {
        console.log('🚀 Starting development session...');

        try {
            await this.verifySetup();
            await this.startDevServer();
            await this.setupFileWatchers();
            this.startPerformanceMonitoring();

            console.log('✅ Development session active');

        } catch (error) {
            console.error('❌ Failed to start development session:', error);
            await this.handleDevelopmentError(error);
        }
    }

    async verifySetup() {
        const fs = require('fs').promises;
        const path = require('path');

        // Check required files
        const requiredFiles = [
            'package.json',
            'src/index.js',
            'src/index.html'
        ];

        for (const file of requiredFiles) {
            const filePath = path.join(this.projectPath, file);
            try {
                await fs.access(filePath);
            } catch {
                throw new Error(`Required file missing: ${file}`);
            }
        }
    }

    async startDevServer() {
        const { spawn } = require('child_process');

        return new Promise((resolve, reject) => {
            this.devServer = spawn('npm', ['run', 'dev'], {
                cwd: this.projectPath,
                stdio: ['pipe', 'pipe', 'pipe']
            });

            let serverReady = false;
            const timeout = setTimeout(() => {
                if (!serverReady) {
                    reject(new Error('Dev server failed to start within 30s'));
                }
            }, 30000);

            this.devServer.stdout.on('data', (data) => {
                const output = data.toString();
                console.log('📡 Dev server:', output.trim());

                if (output.includes('Server running at')) {
                    serverReady = true;
                    clearTimeout(timeout);
                    resolve();
                }
            });
        });
    }

    startPerformanceMonitoring() {
        setInterval(() => {
            const used = process.memoryUsage();
            const totalMB = Math.round(used.rss / 1024 / 1024);

            if (totalMB > 500) {
                console.log(`⚠️ High memory usage: ${totalMB}MB`);
            }

        }, 30000); // Check every 30 seconds
    }

    async executeCommand(command) {
        const { exec } = require('child_process');
        const util = require('util');
        const execAsync = util.promisify(exec);

        try {
            const { stdout, stderr } = await execAsync(command, {
                cwd: this.projectPath
            });
            return stdout;
        } catch (error) {
            console.error(`Command failed: ${command}`, error);
            throw error;
        }
    }
}
```

## Autonomous Setup Script

```bash
#!/bin/bash
# autonomous-setup.sh - Complete autonomous setup

set -e

echo "🤖 Knotty AI Agent - Autonomous Setup"

# Detect platform
PLATFORM=$(uname -s)
ARCH=$(uname -m)
echo "Platform detected: $PLATFORM $ARCH"

# Set platform-specific variables
case "$PLATFORM" in
    Darwin)
        NODE_MEMORY="4096"
        WORKERS="4"
        if [[ "$ARCH" == "arm64" ]]; then
            WORKERS="8"
        fi
        ;;
    Linux)
        NODE_MEMORY="4096"
        WORKERS=$(nproc)
        ;;
    *)
        NODE_MEMORY="2048"
        WORKERS="2"
        ;;
esac

export NODE_OPTIONS="--max-old-space-size=${NODE_MEMORY}"
export PARCEL_WORKERS="${WORKERS}"

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 18+ first."
    exit 1
fi

NODE_VERSION=$(node --version | sed 's/v//')
NODE_MAJOR=$(echo $NODE_VERSION | cut -d. -f1)

if [ "$NODE_MAJOR" -lt 18 ]; then
    echo "❌ Node.js version $NODE_VERSION is too old. Please upgrade to 18+."
    exit 1
fi

echo "✅ Node.js version $NODE_VERSION is compatible"

# Clean existing state
echo "Cleaning existing state..."
rm -rf node_modules/ dist/ .parcel-cache/ package-lock.json 2>/dev/null || true

# Install dependencies
echo "Installing dependencies..."
START_TIME=$(date +%s)
npm install
END_TIME=$(date +%s)
INSTALL_TIME=$((END_TIME - START_TIME))
echo "Dependencies installed in ${INSTALL_TIME}s"

# Perform initial build
echo "Performing initial build..."
START_TIME=$(date +%s)
npm run build
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))

if [ "$BUILD_TIME" -lt 30 ]; then
    echo "✅ Build completed in ${BUILD_TIME}s (target: <30s)"
else
    echo "⚠️ Build took ${BUILD_TIME}s (target: <30s)"
fi

# Test development server
echo "Testing development server..."
npm run dev &
DEV_PID=$!
sleep 10

if curl -s http://localhost:1234 > /dev/null; then
    echo "✅ Development server responding"
else
    echo "⚠️ Development server not responding"
fi

kill $DEV_PID 2>/dev/null || true

# Generate setup report
cat > setup-report.json << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "platform": "$PLATFORM",
  "architecture": "$ARCH",
  "node_version": "$NODE_VERSION",
  "build_time_seconds": $BUILD_TIME,
  "install_time_seconds": $INSTALL_TIME,
  "success": true
}
EOF

echo "🎉 Autonomous setup completed successfully!"
```

## Error Recovery Agent

```bash
#!/bin/bash
# error-recovery-agent.sh - Automated error recovery

recover_from_error() {
    local error_type="$1"
    local attempt="$2"

    echo "🔧 Attempting recovery for: $error_type (attempt $attempt)"

    case "$error_type" in
        "build_failure")
            case "$attempt" in
                1)
                    echo "Clearing build cache..."
                    rm -rf .parcel-cache/ dist/
                    npm run build
                    ;;
                2)
                    echo "Reinstalling dependencies..."
                    rm -rf node_modules/ package-lock.json
                    npm install
                    npm run build
                    ;;
                3)
                    echo "Resetting to clean state..."
                    git clean -fdx
                    npm install
                    npm run build
                    ;;
            esac
            ;;
        "permission_error")
            case "$attempt" in
                1)
                    echo "Fixing file permissions..."
                    chmod -R 755 .
                    ;;
                2)
                    echo "Using nvm instead of system Node.js..."
                    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
                    source ~/.bashrc
                    nvm install 20
                    ;;
            esac
            ;;
        "memory_error")
            case "$attempt" in
                1)
                    echo "Increasing Node.js memory limit..."
                    export NODE_OPTIONS="--max-old-space-size=4096"
                    npm run build
                    ;;
                2)
                    echo "Using swap and reducing workers..."
                    export NODE_OPTIONS="--max-old-space-size=2048"
                    export PARCEL_WORKERS=1
                    npm run build
                    ;;
            esac
            ;;
    esac
}

# Main error detection and recovery loop
detect_and_recover() {
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        echo "🔍 Diagnostic attempt $attempt..."

        if npm run build 2>&1 | tee build.log; then
            echo "✅ Build successful on attempt $attempt"
            rm -f build.log
            return 0
        fi

        # Analyze error log
        if grep -q "EACCES\|permission denied" build.log; then
            recover_from_error "permission_error" $attempt
        elif grep -q "JavaScript heap out of memory" build.log; then
            recover_from_error "memory_error" $attempt
        else
            recover_from_error "build_failure" $attempt
        fi

        attempt=$((attempt + 1))
        sleep 2
    done

    echo "❌ Recovery failed after $max_attempts attempts"
    return 1
}

detect_and_recover
```

## Performance Monitoring Agent

```python
"""
Example: Performance monitoring for continuous optimization
"""
import time
import subprocess
import json
from datetime import datetime

class KnottyPerformanceAgent:
    def __init__(self, project_path):
        self.project_path = project_path
        self.performance_targets = {
            "build_time_max": 30,
            "bundle_size_max": 500 * 1024,  # 500KB
        }

    def monitor_build_performance(self):
        """Monitor and report build performance"""
        print("📊 Monitoring build performance...")

        # Clean build measurement
        subprocess.run(["rm", "-rf", "dist/", ".parcel-cache/"],
                      cwd=self.project_path)

        # Measure build time
        start_time = time.time()
        result = subprocess.run(["npm", "run", "build"],
                               cwd=self.project_path,
                               capture_output=True, text=True)
        build_time = time.time() - start_time

        # Measure bundle size
        bundle_size = self.get_bundle_size()

        # Create performance report
        metrics = {
            "timestamp": datetime.now().isoformat(),
            "build_time": build_time,
            "bundle_size": bundle_size,
            "performance_score": self.calculate_performance_score(build_time, bundle_size)
        }

        self.analyze_performance(metrics)
        return metrics

    def get_bundle_size(self):
        """Calculate total bundle size"""
        import os
        total_size = 0
        dist_path = os.path.join(self.project_path, "dist")

        if os.path.exists(dist_path):
            for root, dirs, files in os.walk(dist_path):
                for file in files:
                    if file.endswith(('.js', '.css', '.html')):
                        file_path = os.path.join(root, file)
                        total_size += os.path.getsize(file_path)

        return total_size

    def calculate_performance_score(self, build_time, bundle_size):
        """Calculate performance score (0-100)"""
        score = 100

        if build_time > self.performance_targets["build_time_max"]:
            score -= 30

        if bundle_size > self.performance_targets["bundle_size_max"]:
            score -= 40

        # Bonus points for excellent performance
        if build_time < 15:
            score += 10

        if bundle_size < 300 * 1024:  # Under 300KB
            score += 20

        return max(0, min(100, score))

    def analyze_performance(self, metrics):
        """Analyze performance and suggest optimizations"""
        build_time = metrics["build_time"]
        bundle_size = metrics["bundle_size"]

        print(f"Build time: {build_time:.1f}s")
        print(f"Bundle size: {bundle_size // 1024}KB")
        print(f"Performance score: {metrics['performance_score']:.1f}/100")

        # Suggest optimizations
        if build_time > 30:
            print("💡 Build optimization suggestions:")
            print("   - Clear Parcel cache: rm -rf .parcel-cache/")
            print("   - Increase memory: export NODE_OPTIONS='--max-old-space-size=4096'")

        if bundle_size > 500 * 1024:
            print("💡 Bundle optimization suggestions:")
            print("   - Enable tree shaking")
            print("   - Use dynamic imports for code splitting")
```

These examples demonstrate how AI agents can effectively integrate with the Knotty rebuild system for autonomous setup, development assistance, error recovery, and performance monitoring.