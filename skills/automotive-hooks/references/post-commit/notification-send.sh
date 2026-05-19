#!/usr/bin/env bash
# ==============================================================================
# Hook: notification-send.sh
# Type: post-commit
# Purpose: Send team notifications for significant commits. Supports Slack
#          webhooks, Microsoft Teams, email, and desktop notifications.
# ==============================================================================

set -euo pipefail

HOOK_NAME="notification-send"

# Configuration
NOTIFY_ON_SAFETY_CHANGES=true
NOTIFY_ON_BREAKING_CHANGES=true
NOTIFY_ON_RELEASE_TAGS=true
NOTIFY_ON_HOTFIX=true
ENABLE_DESKTOP_NOTIFY=true

# Notification channels (set via environment variables)
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
TEAMS_WEBHOOK_URL="${TEAMS_WEBHOOK_URL:-}"
NOTIFY_EMAIL="${NOTIFY_EMAIL:-}"

# Safety-relevant paths
SAFETY_PATHS=("src/safety" "src/asil" "src/fault" "src/diagnostic"
              "src/protection" "include/safety")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get commit details
get_commit_info() {
    local format="$1"
    git log -1 --format="$format" 2>/dev/null || echo ""
}

# Check if commit touches safety-relevant files
is_safety_change() {
    local changed_files
    changed_files=$(git diff --name-only HEAD~1..HEAD 2>/dev/null || echo "")

    for path in "${SAFETY_PATHS[@]}"; do
        if echo "$changed_files" | grep -q "$path"; then
            return 0
        fi
    done
    return 1
}

# Check if this is a breaking change
is_breaking_change() {
    local message
    message=$(get_commit_info "%s")
    echo "$message" | grep -qiE "(breaking|BREAKING)" || \
    echo "$message" | grep -qE "^.*!:"
}

# Check if this is a hotfix
is_hotfix() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    echo "$branch" | grep -qi "hotfix"
}

# Check if this commit has a release tag
has_release_tag() {
    git tag --points-at HEAD 2>/dev/null | grep -qE "^v[0-9]"
}

# Build notification message
build_message() {
    local reason="$1"
    local commit_hash
    commit_hash=$(get_commit_info "%h")
    local author
    author=$(get_commit_info "%an")
    local message
    message=$(get_commit_info "%s")
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    local repo
    repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local changed_files
    changed_files=$(git diff --shortstat HEAD~1..HEAD 2>/dev/null || echo "no stats")

    cat << EOF
{
  "reason": "$reason",
  "repository": "$repo",
  "branch": "$branch",
  "commit": "$commit_hash",
  "author": "$author",
  "message": "$(echo "$message" | sed 's/"/\\"/g')",
  "stats": "$(echo "$changed_files" | sed 's/"/\\"/g')",
  "timestamp": "$timestamp"
}
EOF
}

# Build Slack notification payload
build_slack_payload() {
    local reason="$1"
    local commit_hash
    commit_hash=$(get_commit_info "%h")
    local author
    author=$(get_commit_info "%an")
    local message
    message=$(get_commit_info "%s")
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    local repo
    repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")

    local emoji icon_color
    case "$reason" in
        "Safety Change") emoji=":warning:"; icon_color="#FF6B6B" ;;
        "Breaking Change") emoji=":boom:"; icon_color="#FF4444" ;;
        "Release Tag") emoji=":rocket:"; icon_color="#4CAF50" ;;
        "Hotfix") emoji=":ambulance:"; icon_color="#FF9800" ;;
        *) emoji=":information_source:"; icon_color="#2196F3" ;;
    esac

    cat << EOF
{
  "attachments": [
    {
      "color": "$icon_color",
      "blocks": [
        {
          "type": "header",
          "text": {
            "type": "plain_text",
            "text": "$emoji $reason: $repo"
          }
        },
        {
          "type": "section",
          "fields": [
            {"type": "mrkdwn", "text": "*Branch:*\n$branch"},
            {"type": "mrkdwn", "text": "*Author:*\n$author"},
            {"type": "mrkdwn", "text": "*Commit:*\n\`$commit_hash\`"},
            {"type": "mrkdwn", "text": "*Message:*\n$(echo "$message" | head -c 100 | sed 's/"/\\"/g')"}
          ]
        }
      ]
    }
  ]
}
EOF
}

# Send Slack notification
send_slack() {
    local payload="$1"

    if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
        return 0
    fi

    if ! command -v curl &>/dev/null; then
        echo -e "${YELLOW}  curl not found, cannot send Slack notification.${NC}"
        return 0
    fi

    curl -s -o /dev/null -w "%{http_code}" \
         -X POST \
         -H "Content-Type: application/json" \
         -d "$payload" \
         "$SLACK_WEBHOOK_URL" &>/dev/null || true
}

# Send Teams notification
send_teams() {
    local reason="$1"

    if [[ -z "$TEAMS_WEBHOOK_URL" ]]; then
        return 0
    fi

    local commit_hash author message branch
    commit_hash=$(get_commit_info "%h")
    author=$(get_commit_info "%an")
    message=$(get_commit_info "%s")
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    local payload
    payload=$(cat << EOF
{
  "@type": "MessageCard",
  "summary": "$reason: $message",
  "themeColor": "FF6B6B",
  "title": "$reason",
  "sections": [{
    "facts": [
      {"name": "Branch", "value": "$branch"},
      {"name": "Author", "value": "$author"},
      {"name": "Commit", "value": "$commit_hash"},
      {"name": "Message", "value": "$(echo "$message" | head -c 100 | sed 's/"/\\"/g')"}
    ]
  }]
}
EOF
)

    curl -s -o /dev/null \
         -H "Content-Type: application/json" \
         -d "$payload" \
         "$TEAMS_WEBHOOK_URL" &>/dev/null || true
}

# Send desktop notification
send_desktop() {
    local reason="$1"
    local message
    message=$(get_commit_info "%s")

    if [[ "$ENABLE_DESKTOP_NOTIFY" != "true" ]]; then
        return 0
    fi

    if command -v notify-send &>/dev/null; then
        notify-send "$HOOK_NAME: $reason" "$message" --urgency=normal &>/dev/null || true
    elif command -v osascript &>/dev/null; then
        osascript -e "display notification \"$message\" with title \"$reason\"" &>/dev/null || true
    fi
}

# Main notification logic
run_notifications() {
    local should_notify=false
    local reason=""

    # Check notification triggers
    if [[ "$NOTIFY_ON_SAFETY_CHANGES" == "true" ]] && is_safety_change; then
        should_notify=true
        reason="Safety Change"
    fi

    if [[ "$NOTIFY_ON_BREAKING_CHANGES" == "true" ]] && is_breaking_change; then
        should_notify=true
        reason="Breaking Change"
    fi

    if [[ "$NOTIFY_ON_HOTFIX" == "true" ]] && is_hotfix; then
        should_notify=true
        reason="Hotfix"
    fi

    if [[ "$NOTIFY_ON_RELEASE_TAGS" == "true" ]] && has_release_tag; then
        should_notify=true
        reason="Release Tag"
    fi

    if [[ "$should_notify" == "false" ]]; then
        return 0
    fi

    echo -e "${CYAN}[$HOOK_NAME] Sending notification: $reason${NC}"

    # Send to all configured channels
    local slack_payload
    slack_payload=$(build_slack_payload "$reason")
    send_slack "$slack_payload"
    send_teams "$reason"
    send_desktop "$reason"

    # Log the notification
    local log_entry
    log_entry=$(build_message "$reason")
    mkdir -p .metrics
    echo "$log_entry" >> .metrics/notifications.jsonl 2>/dev/null || true

    echo -e "${GREEN}[$HOOK_NAME] Notification sent: $reason${NC}"
}

# Execute (non-blocking)
run_notifications 2>/dev/null || true
