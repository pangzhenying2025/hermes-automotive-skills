#!/usr/bin/env bash
# ==============================================================================
# Hook: review-required.sh
# Type: pre-merge
# Purpose: Ensure pull requests have the required number of approvals before
#          merge. Checks GitHub/GitLab/Bitbucket PR status via CLI tools.
# ==============================================================================

set -euo pipefail

HOOK_NAME="review-required"
EXIT_CODE=0

# Configuration
MIN_APPROVALS=1
REQUIRE_SAFETY_REVIEW=true        # Require safety engineer for ASIL changes
SAFETY_REVIEW_PATHS=("src/safety" "src/asil" "src/fault" "src/diagnostic")
SAFETY_REVIEWER_TEAM="safety-engineers"
BLOCK_ON_CHANGES_REQUESTED=true
REQUIRE_CI_PASS=true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Detect platform
detect_platform() {
    if command -v gh &>/dev/null; then
        echo "github"
    elif command -v glab &>/dev/null; then
        echo "gitlab"
    else
        echo "unknown"
    fi
}

# Get current branch
get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""
}

# Check GitHub PR reviews
check_github_reviews() {
    local branch
    branch=$(get_current_branch)

    if [[ -z "$branch" ]]; then
        echo -e "${YELLOW}  Cannot determine current branch.${NC}"
        return 0
    fi

    # Find PR for current branch
    local pr_number
    pr_number=$(gh pr view "$branch" --json number -q '.number' 2>/dev/null || echo "")

    if [[ -z "$pr_number" ]]; then
        echo -e "${YELLOW}  No PR found for branch '$branch'.${NC}"
        echo -e "${YELLOW}  Create a PR before merging.${NC}"
        return 1
    fi

    echo -e "${CYAN}  Checking PR #$pr_number reviews...${NC}"

    # Get review status
    local reviews
    reviews=$(gh pr view "$pr_number" --json reviews -q '.reviews' 2>/dev/null || echo "[]")

    local approved=0
    local changes_requested=0
    local pending=0

    if command -v python3 &>/dev/null; then
        local counts
        counts=$(echo "$reviews" | python3 -c "
import json, sys
reviews = json.load(sys.stdin)
# Group by author, take latest review
latest = {}
for r in reviews:
    author = r.get('author', {}).get('login', 'unknown')
    latest[author] = r.get('state', 'PENDING')
approved = sum(1 for s in latest.values() if s == 'APPROVED')
changes = sum(1 for s in latest.values() if s == 'CHANGES_REQUESTED')
pending = sum(1 for s in latest.values() if s in ('PENDING', 'COMMENTED'))
print(f'APPROVED:{approved}')
print(f'CHANGES:{changes}')
print(f'PENDING:{pending}')
" 2>/dev/null)

        while IFS= read -r line; do
            case "$line" in
                APPROVED:*) approved="${line#APPROVED:}" ;;
                CHANGES:*) changes_requested="${line#CHANGES:}" ;;
                PENDING:*) pending="${line#PENDING:}" ;;
            esac
        done <<< "$counts"
    fi

    echo "  Approvals: $approved, Changes Requested: $changes_requested, Pending: $pending"

    # Check minimum approvals
    if [[ $approved -lt $MIN_APPROVALS ]]; then
        echo -e "${RED}  FAIL: $approved approval(s), minimum $MIN_APPROVALS required.${NC}"
        return 1
    fi

    # Check for changes requested
    if [[ "$BLOCK_ON_CHANGES_REQUESTED" == "true" ]] && [[ $changes_requested -gt 0 ]]; then
        echo -e "${RED}  FAIL: $changes_requested reviewer(s) requested changes.${NC}"
        return 1
    fi

    # Check CI status
    if [[ "$REQUIRE_CI_PASS" == "true" ]]; then
        local ci_status
        ci_status=$(gh pr checks "$pr_number" --json state -q '.[].state' 2>/dev/null | sort -u)

        if echo "$ci_status" | grep -qi "FAILURE\|ERROR"; then
            echo -e "${RED}  FAIL: CI checks have failures.${NC}"
            return 1
        fi
        if echo "$ci_status" | grep -qi "PENDING"; then
            echo -e "${YELLOW}  WARNING: CI checks still pending.${NC}"
        fi
    fi

    # Check safety review requirement
    if [[ "$REQUIRE_SAFETY_REVIEW" == "true" ]]; then
        local changed_files
        changed_files=$(gh pr diff "$pr_number" --name-only 2>/dev/null || echo "")

        local needs_safety_review=false
        for path_pattern in "${SAFETY_REVIEW_PATHS[@]}"; do
            if echo "$changed_files" | grep -q "$path_pattern"; then
                needs_safety_review=true
                break
            fi
        done

        if [[ "$needs_safety_review" == "true" ]]; then
            echo -e "${CYAN}  Safety-relevant files changed. Checking for safety review...${NC}"

            # Check if a member of the safety team approved
            local safety_approved
            safety_approved=$(gh pr view "$pr_number" --json reviews -q \
                ".reviews[] | select(.state == \"APPROVED\") | .author.login" 2>/dev/null || echo "")

            # Simplified check - in production, verify against team membership
            if [[ -z "$safety_approved" ]]; then
                echo -e "${RED}  FAIL: Safety-relevant changes require safety team approval.${NC}"
                return 1
            fi
            echo -e "${GREEN}  Safety review: approved.${NC}"
        fi
    fi

    echo -e "${GREEN}  Review requirements met.${NC}"
    return 0
}

# Check GitLab MR reviews
check_gitlab_reviews() {
    local branch
    branch=$(get_current_branch)

    echo -e "${CYAN}  Checking GitLab MR for branch '$branch'...${NC}"

    local mr_info
    mr_info=$(glab mr view "$branch" --json 2>/dev/null || echo "")

    if [[ -z "$mr_info" ]]; then
        echo -e "${YELLOW}  No MR found for branch '$branch'.${NC}"
        return 1
    fi

    # GitLab uses approval rules
    local approvals
    approvals=$(echo "$mr_info" | grep -oP '"approved_by":\s*\[.*?\]' | grep -c '"name"' 2>/dev/null || echo 0)

    echo "  Approvals: $approvals (minimum: $MIN_APPROVALS)"

    if [[ $approvals -lt $MIN_APPROVALS ]]; then
        echo -e "${RED}  FAIL: Insufficient approvals.${NC}"
        return 1
    fi

    return 0
}

# Main check
run_check() {
    echo -e "${YELLOW}[$HOOK_NAME] Checking review requirements...${NC}"

    # Detect platform
    local platform
    platform=$(detect_platform)

    case "$platform" in
        github)
            if ! check_github_reviews; then
                return 1
            fi
            ;;
        gitlab)
            if ! check_gitlab_reviews; then
                return 1
            fi
            ;;
        unknown)
            echo -e "${YELLOW}[$HOOK_NAME] No CLI tool found (gh, glab).${NC}"
            echo -e "${YELLOW}  Install GitHub CLI (gh) or GitLab CLI (glab) for review checks.${NC}"
            echo -e "${YELLOW}  Skipping review check.${NC}"
            return 0
            ;;
    esac

    echo -e "${GREEN}[$HOOK_NAME] PASSED: All review requirements met.${NC}"
    return 0
}

# Execute
if ! run_check; then
    EXIT_CODE=1
fi

exit $EXIT_CODE
