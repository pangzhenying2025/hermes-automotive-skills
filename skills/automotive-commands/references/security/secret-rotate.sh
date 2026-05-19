#!/usr/bin/env bash
# secret-rotate.sh - Rotate secrets in .env files with new random values
# Generates cryptographically secure random values for API keys, tokens, etc.

set -euo pipefail

# Default values
ENV_FILE=".env.example"
DRY_RUN=false
BACKUP=true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Rotate secrets in .env files with new cryptographically secure random values.

Options:
    -f, --file FILE           Environment file (default: .env.example)
    -n, --dry-run             Show what would be rotated without changing
    --no-backup               Don't create backup file
    -h, --help                Show this help message

Examples:
    # Dry-run to see what would change
    $0 -f .env.local -n

    # Rotate secrets in .env.example
    $0 -f .env.example

WARNING: This will replace secret values with new random strings.
         Only use on template files, not production .env files.

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file) ENV_FILE="$2"; shift 2 ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        --no-backup) BACKUP=false; shift ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

if [[ ! -f "$ENV_FILE" ]]; then
    echo -e "${RED}Error: File not found: $ENV_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}=== Secret Rotation Tool ===${NC}"
echo "File: $ENV_FILE"
echo "Mode: $(if [[ $DRY_RUN == true ]]; then echo 'DRY RUN'; else echo 'LIVE'; fi)"
echo ""

# Patterns for secret detection
SECRET_PATTERNS=(
    "API_KEY"
    "SECRET"
    "TOKEN"
    "PASSWORD"
    "PRIVATE_KEY"
    "ENCRYPTION_KEY"
    "JWT_SECRET"
)

generate_random_hex() {
    local length=${1:-32}
    openssl rand -hex "$length"
}

generate_random_base64() {
    local length=${1:-32}
    openssl rand -base64 "$length" | tr -d '\n'
}

# Create backup
if [[ $BACKUP == true && $DRY_RUN == false ]]; then
    BACKUP_FILE="${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$ENV_FILE" "$BACKUP_FILE"
    echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
    echo ""
fi

ROTATED_COUNT=0
TEMP_FILE=$(mktemp)

while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
        echo "$line" >> "$TEMP_FILE"
        continue
    fi

    # Check if line contains a secret pattern
    SHOULD_ROTATE=false
    for pattern in "${SECRET_PATTERNS[@]}"; do
        if [[ "$line" =~ $pattern ]]; then
            SHOULD_ROTATE=true
            break
        fi
    done

    if [[ $SHOULD_ROTATE == true && "$line" =~ = ]]; then
        VAR_NAME=$(echo "$line" | cut -d= -f1)
        OLD_VALUE=$(echo "$line" | cut -d= -f2-)

        # Determine secret type and generate appropriate random value
        if [[ "$VAR_NAME" =~ JWT|TOKEN ]]; then
            NEW_VALUE=$(generate_random_base64 48)
        elif [[ "$VAR_NAME" =~ ENCRYPTION_KEY ]]; then
            NEW_VALUE=$(generate_random_hex 32)
        else
            NEW_VALUE=$(generate_random_hex 24)
        fi

        if [[ $DRY_RUN == true ]]; then
            echo -e "${YELLOW}Would rotate:${NC} $VAR_NAME"
            echo "  Old: ${OLD_VALUE:0:20}..."
            echo "  New: ${NEW_VALUE:0:20}..."
            echo ""
        else
            echo -e "${GREEN}Rotated:${NC} $VAR_NAME"
        fi

        echo "${VAR_NAME}=${NEW_VALUE}" >> "$TEMP_FILE"
        ((ROTATED_COUNT++))
    else
        echo "$line" >> "$TEMP_FILE"
    fi

done < "$ENV_FILE"

if [[ $DRY_RUN == false ]]; then
    mv "$TEMP_FILE" "$ENV_FILE"
    echo ""
    echo -e "${GREEN}✓ Rotated $ROTATED_COUNT secrets in $ENV_FILE${NC}"
else
    rm "$TEMP_FILE"
    echo ""
    echo -e "${YELLOW}DRY RUN: Would rotate $ROTATED_COUNT secrets${NC}"
fi

echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  - Update actual .env files manually"
echo "  - Redeploy services with new secrets"
echo "  - Update key management systems (AWS Secrets Manager, etc.)"
echo "  - Invalidate old secrets in external services"
