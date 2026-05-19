#!/usr/bin/env bash
set -euo pipefail
# Generate release notes from git log
FROM_TAG=${1:-v1.0.0}
TO_TAG=${2:-HEAD}
echo "Release Notes ($FROM_TAG → $TO_TAG)"
git log --oneline "$FROM_TAG..$TO_TAG" --pretty=format:"- %s" 2>/dev/null || echo "Git not available"
