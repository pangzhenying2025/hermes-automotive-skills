#!/usr/bin/env bash
set -euo pipefail
# Search skills by keyword
KEYWORD=${1:-battery}
echo "Searching skills for: $KEYWORD"
find /home/rpi/Opensource/automotive-claude-code-agents/skills -name "*.md" -exec grep -l "$KEYWORD" {} \; 2>/dev/null | head -n 10
