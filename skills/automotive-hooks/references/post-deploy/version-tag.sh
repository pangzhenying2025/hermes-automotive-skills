#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Version Tag Verification Hook (Post-Deploy)
################################################################################
# Purpose: Verify deployment has proper semantic version tag
# Ensures traceability from deployed software to git commit
################################################################################

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

echo -e "${YELLOW}Verifying version tag for deployment...${NC}"

# Get current git commit
CURRENT_COMMIT=$(git rev-parse HEAD)
echo "Current commit: $CURRENT_COMMIT"

# Check if current commit has a semantic version tag
TAGS=$(git tag --points-at HEAD | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+' || true)

if [ -z "$TAGS" ]; then
    echo -e "${RED}ERROR: No semantic version tag found for deployment${NC}"
    echo ""
    echo "Current commit must be tagged with semantic version (vX.Y.Z)"
    echo "Example: git tag -a v1.2.3 -m 'Release v1.2.3'"
    echo ""
    echo "Semantic versioning guidelines:"
    echo "  - MAJOR version: incompatible API changes"
    echo "  - MINOR version: backwards-compatible functionality"
    echo "  - PATCH version: backwards-compatible bug fixes"
    exit 1
fi

# Verify tag format
for tag in $TAGS; do
    if [[ "$tag" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        MAJOR="${BASH_REMATCH[1]}"
        MINOR="${BASH_REMATCH[2]}"
        PATCH="${BASH_REMATCH[3]}"
        echo -e "${GREEN}Valid version tag found: $tag${NC}"
        echo "  Major: $MAJOR, Minor: $MINOR, Patch: $PATCH"
    else
        echo -e "${YELLOW}Warning: Tag $tag does not follow semantic versioning${NC}"
    fi
done

# Check if tag is signed (recommended for production)
for tag in $TAGS; do
    if git tag -v "$tag" &>/dev/null; then
        echo -e "${GREEN}Tag $tag is GPG-signed${NC}"
    else
        echo -e "${YELLOW}Warning: Tag $tag is not GPG-signed${NC}"
        echo "For production deployments, sign tags with: git tag -s"
    fi
done

# Log deployment
DEPLOY_LOG="deployment.log"
echo "$(date -Iseconds) - Deployed version $TAGS from commit $CURRENT_COMMIT" >> "$DEPLOY_LOG"

echo ""
echo -e "${GREEN}Version tag verification PASSED${NC}"
echo "Deployment version: $TAGS"
exit 0
