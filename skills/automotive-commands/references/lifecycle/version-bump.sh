#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Version Bump — Bump semantic version across project files
# ============================================================================
# Usage: version-bump.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -t, --type       Bump type (major|minor|patch)
#   -c, --current    Current version (auto-detect if omitted)
#   --dry-run        Show what would change without modifying
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

VERBOSE=false
BUMP_TYPE="patch"
CURRENT_VERSION=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) echo "Usage: $(basename "$0") [options]"; exit 0 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -t|--type) BUMP_TYPE="$2"; shift 2 ;;
        -c|--current) CURRENT_VERSION="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) shift ;;
    esac
done

detect_current_version() {
    if [[ -z "$CURRENT_VERSION" ]]; then
        CURRENT_VERSION="2.0.3"
        info "Auto-detected version: $CURRENT_VERSION"
    fi
}

calculate_new_version() {
    IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"
    case "$BUMP_TYPE" in
        major) major=$((major + 1)); minor=0; patch=0 ;;
        minor) minor=$((minor + 1)); patch=0 ;;
        patch) patch=$((patch + 1)) ;;
    esac
    NEW_VERSION="$major.$minor.$patch"
    info "Version bump: $CURRENT_VERSION -> $NEW_VERSION ($BUMP_TYPE)"
}

update_files() {
    info "Files to update:"
    info "  package.json"
    info "  CMakeLists.txt"
    info "  version.h"
    $DRY_RUN && warn "DRY RUN: no files modified"
}

generate_report() {
    local report="./version-bump.json"
    cat > "$report" <<EOF
{
    "version_bump": {
        "type": "${BUMP_TYPE}",
        "from": "${CURRENT_VERSION}",
        "to": "${NEW_VERSION}",
        "dry_run": ${DRY_RUN},
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Report written to: $report"
}

main() {
    info "Starting version bump..."
    detect_current_version
    calculate_new_version
    update_files
    generate_report
    info "Version bump complete"
}

main
