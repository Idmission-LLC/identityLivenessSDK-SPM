#!/bin/sh

# Fail immediately on error
set -e

# Validate input
if [ -z "$1" ]; then
  echo "❌ Usage: $0 <SDK_VERSION> [TAG_VERSION]"
  exit 1
fi

SDK_VERSION=$1
TAG_VERSION=${2:-$SDK_VERSION}   # defaults to SDK_VERSION if not given

cd "$(dirname "$0")"   # go to identitymediumsdk2.0/

# # Check if branch is clean
# if [ -n "$(git status --porcelain)" ]; then
#  echo "✅ LivenessSDK: Found uncommitted changes, proceeding."
# else
#  echo "❌ LivenessSDK: No changes to commit. Working tree is clean."
#  exit 1
# fi

# Check if tag already exists
if git rev-parse "$TAG_VERSION" >/dev/null 2>&1; then
  echo "❌ Tag '$TAG_VERSION' already exists. Please choose a different version."
  exit 1
fi

# Commit changes
echo "🚀 LivenessSDK: Adding & committing changes…"
git add .
if git diff --cached --quiet; then
  echo "ℹ️ LivenessSDK: No changes to commit, skipping commit."
else
  git commit -m "Updated SDK v${SDK_VERSION}"
fi

# Push to remote master
echo "⬆️ LivenessSDK: Pushing to origin master…"
git push origin main

# Create & push tag
echo "🏷️ LivenessSDK: Creating and pushing tag '${TAG_VERSION}'…"
git tag "${TAG_VERSION}"
git push origin "${TAG_VERSION}"

echo "✅ Done! LivenessSDK updated and tagged as '${TAG_VERSION}'."
