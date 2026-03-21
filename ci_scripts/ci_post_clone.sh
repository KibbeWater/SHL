#!/bin/bash
set -e

echo "📦 Installing Tuist..."

# Install Tuist if not available
if ! command -v tuist &> /dev/null; then
    brew install tuist
fi

echo "✅ Tuist version: $(tuist version)"

# Navigate to project root
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Fetch dependencies and generate project
echo "📥 Fetching dependencies..."
tuist install

echo "🔧 Generating Xcode project..."
tuist generate --no-open

echo "✅ Project generated successfully"
