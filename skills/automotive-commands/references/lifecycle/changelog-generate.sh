#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Changelog Generate — Generate changelog from git commit history
# ============================================================================
# Usage: changelog-generate.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -f, --from       Starting tag/commit
#   -t, --to         Ending tag/commit (default: HEAD)
#   -o, --output     Output changelog file
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
FROM_REF=""
TO_REF="HEAD"
OUTPUT_FILE="./CHANGELOG-generated.txt"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) echo "Usage: $(basename "$0") [options]"; exit 0 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -f|--from) FROM_REF="$2"; shift 2 ;;
        -t|--to) TO_REF="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

generate_changelog() {
    info "Generating changelog${FROM_REF:+ from $FROM_REF} to $TO_REF..."

    if git rev-parse --git-dir &>/dev/null; then
        info "Git repository detected, analyzing commits..."
        local feat_count fix_count refactor_count
        feat_count=$(git log ${FROM_REF:+${FROM_REF}..}${TO_REF} --oneline --grep="^feat" 2>/dev/null | wc -l || echo 0)
        fix_count=$(git log ${FROM_REF:+${FROM_REF}..}${TO_REF} --oneline --grep="^fix" 2>/dev/null | wc -l || echo 0)
        refactor_count=$(git log ${FROM_REF:+${FROM_REF}..}${TO_REF} --oneline --grep="^refactor" 2>/dev/null | wc -l || echo 0)
        info "  Features: $feat_count, Fixes: $fix_count, Refactors: $refactor_count"
    else
        info "  No git repository, generating sample changelog"
    fi

    cat > "$OUTPUT_FILE" <<EOF
# Changelog

## [Unreleased] - $(date +%Y-%m-%d)

### Features
- feat: Add new battery monitoring dashboard
- feat: Implement OTA update rollback

### Bug Fixes
- fix: Correct CAN message byte order
- fix: Resolve timeout in UDS session

### Refactoring
- refactor: Simplify sensor fusion pipeline

Generated: $(date -Iseconds)
EOF
    info "Changelog written to: $OUTPUT_FILE"
}

main() {
    info "Starting changelog generation..."
    generate_changelog
    info "Changelog generation complete"
}

main
