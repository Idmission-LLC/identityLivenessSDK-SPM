#!/bin/sh
# Commit Package.swift and tag the SPM release, after the pod repo's ./GitHub_LivenessSDK_Release.sh
# pointed Package.swift at the liveness-<SDK_VERSION> zips.

# Fail immediately on error
set -e

# Validate input
if [ -z "$1" ]; then
  echo "❌ Usage: $0 <SDK_VERSION> [TAG_VERSION]"
  exit 1
fi

SDK_VERSION=$1
# SwiftPM only sees semantic-version tags, so this defaults to the SDK version's first three numbers (11.1.19.2.5 → 11.1.19)
TAG_VERSION=${2:-$(echo "$SDK_VERSION" | cut -d. -f1-3)}
if ! echo "$TAG_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'; then
  echo "❌ '$TAG_VERSION' isn't a semantic version (like 11.1.20 or 11.1.20-rc.1)."
  exit 1
fi

cd "$(dirname "$0")"   # go to identitymediumsdk2.0/

if [ "$(git branch --show-current)" != main ]; then
  echo "❌ LivenessSDK: Check out main first."
  exit 1
fi

# Every binary target must download this SDK version's zips
if grep 'binaryTarget' Package.swift | grep -v -F -- "-${SDK_VERSION}/"; then
  echo "❌ LivenessSDK: These binary targets aren't on SDK ${SDK_VERSION}: run the pod repo's GitHub_LivenessSDK_Release.sh first."
  exit 1
fi
git fetch -q --tags origin

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
