#!/bin/bash

# setup_repo.sh - Fresh repository setup script
# This script sets up a fresh repository with all dependencies and builds
# Note: Adapted from HumanLayer setup - customize for your project

set -e  # Exit on any error

# Script location-independent path resolution (SWD pattern)
SWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SWD/.." && pwd)

# Source the run_silent utility
source "$SWD/run_silent.sh"

# Detect if running in CI
if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
    IS_CI=true
else
    IS_CI=false
fi

# Function to install CI-specific tools
install_ci_tools() {
    echo "🔧 Installing CI-specific tools..."
    
    # Install Claude Code CLI
    run_silent "Installing Claude Code CLI" "npm install -g @anthropic-ai/claude-code"
    # Install golangci-lint
    if ! command -v golangci-lint &> /dev/null; then
        run_silent "Installing golangci-lint" "go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
    fi
}

# Main setup flow
echo "🚀 Setting up repository..."
echo "⚠️  NOTE: This script is a template from HumanLayer. Customize it for your project!"
echo ""

# Install CI tools if in CI environment
if [ "$IS_CI" = true ]; then
    install_ci_tools
fi

# Install platform-specific dependencies
echo "🔍 Checking platform-specific dependencies..."
bash "$SWD/install_platform_deps.sh"

# ⚠️  CUSTOMIZE BELOW FOR YOUR PROJECT
# The original HumanLayer setup included:
# - mockgen installation for Go mocking
# - HLD (Humanlayer Daemon) build
# - TypeScript SDK build
# - WUI (Web UI) build
# - hlyr CLI build
#
# Replace these with commands for your actual project dependencies

echo "📦 TODO: Add your project-specific setup commands here"
echo "Examples:"
echo "  - npm install"
echo "  - make setup"
echo "  - bun install"
echo "  - cargo build"

echo "✅ Basic setup complete!"
echo ""
echo "Next steps:"
echo "1. Customize this script for your project"
echo "2. Add your project's build commands"
echo "3. Run from repo root: ./hack/setup_repo.sh"
