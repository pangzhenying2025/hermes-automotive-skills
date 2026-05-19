#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Secret and Credential Scanner Hook
################################################################################
# Purpose: Prevent accidental commit of secrets, credentials, and sensitive data
# Checks:
#   - API keys, tokens, passwords in code
#   - AWS, Azure, GCP credentials
#   - Private keys (RSA, DSA, EC)
#   - Database connection strings
#   - Bearer tokens, Basic auth headers
#   - .env files (except .env.example)
# Exit codes:
#   0 - No secrets found
#   1 - Secrets detected
################################################################################

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Track findings
secrets_found=0

echo -e "${YELLOW}Running secret scan...${NC}"

# Get all staged files (not just C/C++)
mapfile -t staged_files < <(git diff --cached --name-only --diff-filter=ACM || true)

if [ ${#staged_files[@]} -eq 0 ]; then
    echo -e "${GREEN}No files staged, skipping secret scan${NC}"
    exit 0
fi

echo "Scanning ${#staged_files[@]} file(s) for secrets..."

################################################################################
# Whitelist patterns (legitimate uses)
################################################################################
is_whitelisted() {
    local file="$1"

    # Whitelist .env.example files
    if [[ "$file" =~ \.env\.example$ ]]; then
        return 0
    fi

    # Whitelist test fixture files with clearly fake credentials
    if [[ "$file" =~ test.*fixtures? ]] || [[ "$file" =~ mocks? ]]; then
        return 0
    fi

    # Whitelist documentation
    if [[ "$file" =~ \.(md|txt|rst)$ ]]; then
        return 0
    fi

    return 1
}

################################################################################
# Function: Check for .env and key files
################################################################################
check_sensitive_files() {
    local file="$1"

    # Block .env files (but allow .env.example)
    if [[ "$file" =~ \.env$ ]] && [[ ! "$file" =~ \.env\.example$ ]]; then
        echo -e "${RED}BLOCKED: $file - .env files should never be committed${NC}"
        return 1
    fi

    # Block private key files
    if [[ "$file" =~ \.(pem|key|p12|pfx|keystore|jks)$ ]]; then
        echo -e "${RED}BLOCKED: $file - Private key file detected${NC}"
        return 1
    fi

    # Block certificate files that might contain private keys
    if [[ "$file" =~ (private.*\.crt|private.*\.cer)$ ]]; then
        echo -e "${RED}BLOCKED: $file - Private certificate file detected${NC}"
        return 1
    fi

    return 0
}

################################################################################
# Function: Scan file content for secret patterns
################################################################################
scan_file_content() {
    local file="$1"
    local violations=0

    # Skip binary files
    if file "$file" 2>/dev/null | grep -q "binary"; then
        return 0
    fi

    # Skip large files (> 1MB)
    if [ -f "$file" ] && [ $(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null) -gt 1048576 ]; then
        echo -e "${YELLOW}Skipping large file: $file${NC}"
        return 0
    fi

    # Generic API key patterns
    if grep -nEi "(api[_-]?key|apikey|api[_-]?secret)['\"]?\s*[:=]\s*['\"]?[a-zA-Z0-9_\-]{20,}" "$file" 2>/dev/null; then
        echo -e "${RED}$file: API key pattern detected${NC}"
        violations=1
    fi

    # Generic password patterns
    if grep -nEi "(password|passwd|pwd)['\"]?\s*[:=]\s*['\"]?[a-zA-Z0-9!@#\$%^&*]{8,}" "$file" 2>/dev/null; then
        # Exclude common placeholders
        if ! grep -qEi "(password|passwd|pwd)['\"]?\s*[:=]\s*['\"]?(your_password|changeme|password|******|placeholder|example)" "$file" 2>/dev/null; then
            echo -e "${RED}$file: Password pattern detected${NC}"
            violations=1
        fi
    fi

    # Bearer tokens
    if grep -nE "['\"]Bearer [A-Za-z0-9._\-]{20,}['\"]" "$file" 2>/dev/null; then
        echo -e "${RED}$file: Bearer token detected${NC}"
        violations=1
    fi

    # Basic auth credentials
    if grep -nE "['\"]Basic [A-Za-z0-9+/=]{20,}['\"]" "$file" 2>/dev/null; then
        echo -e "${RED}$file: Basic auth credential detected${NC}"
        violations=1
    fi

    # AWS access keys
    if grep -nE "(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|aws_access_key_id|aws_secret_access_key)['\"]?\s*[:=]\s*['\"]?[A-Z0-9]{16,}" "$file" 2>/dev/null; then
        echo -e "${RED}$file: AWS credential detected${NC}"
        violations=1
    fi

    # AWS secret access key pattern (40 characters)
    if grep -nE "['\"][A-Za-z0-9/+=]{40}['\"]" "$file" 2>/dev/null | grep -i "aws\|secret"; then
        echo -e "${RED}$file: Potential AWS secret access key detected${NC}"
        violations=1
    fi

    # Azure connection strings
    if grep -nEi "DefaultEndpointsProtocol=https;AccountName=[a-zA-Z0-9]+;AccountKey=[A-Za-z0-9+/=]{40,}" "$file" 2>/dev/null; then
        echo -e "${RED}$file: Azure storage connection string detected${NC}"
        violations=1
    fi

    # GCP service account keys (JSON pattern)
    if grep -nE "\"private_key\":\s*\"-----BEGIN PRIVATE KEY-----" "$file" 2>/dev/null; then
        echo -e "${RED}$file: GCP service account private key detected${NC}"
        violations=1
    fi

    # RSA private keys
    if grep -n "-----BEGIN RSA PRIVATE KEY-----" "$file" 2>/dev/null; then
        echo -e "${RED}$file: RSA private key detected${NC}"
        violations=1
    fi

    # Generic private keys
    if grep -n "-----BEGIN PRIVATE KEY-----" "$file" 2>/dev/null; then
        echo -e "${RED}$file: Private key detected${NC}"
        violations=1
    fi

    # EC private keys
    if grep -n "-----BEGIN EC PRIVATE KEY-----" "$file" 2>/dev/null; then
        echo -e "${RED}$file: EC private key detected${NC}"
        violations=1
    fi

    # DSA private keys
    if grep -n "-----BEGIN DSA PRIVATE KEY-----" "$file" 2>/dev/null; then
        echo -e "${RED}$file: DSA private key detected${NC}"
        violations=1
    fi

    # Database connection strings
    if grep -nEi "(mongodb|mysql|postgresql|postgres)://[a-zA-Z0-9_]+:[a-zA-Z0-9_!@#\$%^&*]+@" "$file" 2>/dev/null; then
        echo -e "${RED}$file: Database connection string with credentials detected${NC}"
        violations=1
    fi

    # Generic tokens
    if grep -nEi "(token|secret|credential)['\"]?\s*[:=]\s*['\"]?[a-zA-Z0-9_.\-]{32,}" "$file" 2>/dev/null; then
        # Exclude test placeholders
        if ! grep -qEi "(token|secret)['\"]?\s*[:=]\s*['\"]?(test_token|fake_secret|example|placeholder|your_token)" "$file" 2>/dev/null; then
            echo -e "${RED}$file: Token/secret pattern detected${NC}"
            violations=1
        fi
    fi

    # GitHub tokens (ghp_, gho_, ghr_, ghs_)
    if grep -nE "(ghp|gho|ghr|ghs)_[A-Za-z0-9_]{36,}" "$file" 2>/dev/null; then
        echo -e "${RED}$file: GitHub token detected${NC}"
        violations=1
    fi

    # Slack tokens
    if grep -nE "xox[baprs]-[A-Za-z0-9\-]+" "$file" 2>/dev/null; then
        echo -e "${RED}$file: Slack token detected${NC}"
        violations=1
    fi

    # Generic hex secrets (64+ hex chars, likely SHA256 secrets)
    if grep -nE "['\"][a-fA-F0-9]{64,}['\"]" "$file" 2>/dev/null | head -3; then
        echo -e "${YELLOW}$file: Long hex string detected (potential secret)${NC}"
        # Don't fail on this, just warn
    fi

    return $violations
}

################################################################################
# Main scan logic
################################################################################
for file in "${staged_files[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi

    # Check if file is whitelisted
    if is_whitelisted "$file"; then
        echo -e "${GREEN}Whitelisted: $file${NC}"
        continue
    fi

    # Check sensitive file types
    if ! check_sensitive_files "$file"; then
        secrets_found=1
        continue
    fi

    # Scan file content
    if ! scan_file_content "$file"; then
        secrets_found=1
    fi
done

################################################################################
# Summary
################################################################################
echo ""
echo "========================================"
if [ $secrets_found -eq 0 ]; then
    echo -e "${GREEN}Secret scan PASSED${NC}"
    echo "No secrets or credentials detected"
    exit 0
else
    echo -e "${RED}Secret scan FAILED${NC}"
    echo "Secrets or credentials detected in staged files"
    echo ""
    echo "Actions:"
    echo "  1. Remove the secrets from the files"
    echo "  2. Use environment variables or secret managers instead"
    echo "  3. Add .env files to .gitignore"
    echo "  4. If this is a false positive, add the file pattern to whitelist"
    echo ""
    echo "To bypass (NOT RECOMMENDED):"
    echo "  git commit --no-verify"
    exit 1
fi
