#!/bin/bash

# Release script for Glimpsify
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 1.0.0

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

VERSION=$1
TAG="v$VERSION"

# Validate version format (semantic versioning)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format. Use semantic versioning (e.g., 1.0.0)"
    exit 1
fi

echo "Creating release for version $VERSION..."

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "Warning: You're not on the main branch. Current branch: $CURRENT_BRANCH"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Working directory is not clean. Please commit or stash your changes."
    git status --short
    exit 1
fi

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Error: Tag $TAG already exists"
    exit 1
fi

# Update version in Info.plist if it exists
if [ -f "Glimpsify/Info.plist" ]; then
    echo "Updating version in Info.plist..."
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" Glimpsify/Info.plist
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" Glimpsify/Info.plist
fi

# Create and push tag
echo "Creating tag $TAG..."
git tag -a "$TAG" -m "Release version $VERSION"

echo "Pushing tag to origin..."
git push origin "$TAG"

echo "Release $TAG created successfully!"
echo "GitHub Actions will automatically build and create the release."
echo "Check the Actions tab on GitHub for build progress." 