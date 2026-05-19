#!/usr/bin/env bash
# vuln-scan.sh - Run dependency vulnerability scanning across project
# Supports pip-audit (Python), npm audit (Node.js), cargo audit (Rust)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
SCAN_DIR="."
FAIL_ON_HIGH=true
OUTPUT_FORMAT="text"
OUTPUT_FILE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Run vulnerability scanning on project dependencies.

Options:
    -d, --directory DIR       Project directory (default: .)
    -f, --format FORMAT       Output format: text, json, sarif (default: text)
    -o, --output FILE         Write report to file
    --no-fail                 Don't fail on high severity vulnerabilities
    -h, --help                Show this help message

Examples:
    # Scan current directory
    $0

    # Scan with JSON output
    $0 -f json -o vuln-report.json

    # Scan specific project
    $0 -d /path/to/project

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--directory) SCAN_DIR="$2"; shift 2 ;;
        -f|--format) OUTPUT_FORMAT="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        --no-fail) FAIL_ON_HIGH=false; shift ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

echo -e "${BLUE}=== Vulnerability Scanner ===${NC}"
echo "Scan directory: $SCAN_DIR"
echo ""

cd "$SCAN_DIR"

VULN_FOUND=false

# Python - pip-audit
if [[ -f "requirements.txt" || -f "pyproject.toml" || -f "setup.py" ]]; then
    echo -e "${YELLOW}[Python] Scanning with pip-audit...${NC}"

    if command -v pip-audit &> /dev/null; then
        if [[ -n "$OUTPUT_FILE" && "$OUTPUT_FORMAT" == "json" ]]; then
            pip-audit --format json > "${OUTPUT_FILE%.json}_python.json" || VULN_FOUND=true
        else
            pip-audit --desc || VULN_FOUND=true
        fi
        echo ""
    else
        echo -e "${YELLOW}  pip-audit not installed. Install: pip install pip-audit${NC}"
        echo ""
    fi
fi

# Node.js - npm audit
if [[ -f "package.json" ]]; then
    echo -e "${YELLOW}[Node.js] Scanning with npm audit...${NC}"

    if command -v npm &> /dev/null; then
        if [[ -n "$OUTPUT_FILE" && "$OUTPUT_FORMAT" == "json" ]]; then
            npm audit --json > "${OUTPUT_FILE%.json}_npm.json" || VULN_FOUND=true
        else
            npm audit || VULN_FOUND=true
        fi
        echo ""
    else
        echo -e "${YELLOW}  npm not installed${NC}"
        echo ""
    fi
fi

# Rust - cargo audit
if [[ -f "Cargo.toml" ]]; then
    echo -e "${YELLOW}[Rust] Scanning with cargo-audit...${NC}"

    if command -v cargo-audit &> /dev/null; then
        if [[ -n "$OUTPUT_FILE" && "$OUTPUT_FORMAT" == "json" ]]; then
            cargo audit --json > "${OUTPUT_FILE%.json}_cargo.json" || VULN_FOUND=true
        else
            cargo audit || VULN_FOUND=true
        fi
        echo ""
    else
        echo -e "${YELLOW}  cargo-audit not installed. Install: cargo install cargo-audit${NC}"
        echo ""
    fi
fi

# Java/Maven - dependency-check (if available)
if [[ -f "pom.xml" ]]; then
    echo -e "${YELLOW}[Java/Maven] Checking for OWASP Dependency-Check...${NC}"

    if command -v dependency-check &> /dev/null; then
        dependency-check --project "$(basename $PWD)" --scan . --format JSON || VULN_FOUND=true
        echo ""
    else
        echo -e "${YELLOW}  OWASP Dependency-Check not installed${NC}"
        echo -e "${YELLOW}  Download from: https://owasp.org/www-project-dependency-check/${NC}"
        echo ""
    fi
fi

# Summary
echo -e "${BLUE}=== Scan Complete ===${NC}"

if [[ "$VULN_FOUND" == true ]]; then
    echo -e "${RED}✗ Vulnerabilities detected${NC}"
    echo ""
    echo -e "${YELLOW}Recommended actions:${NC}"
    echo "  1. Review vulnerability details"
    echo "  2. Update affected dependencies"
    echo "  3. Check for security patches"
    echo "  4. Consider alternative packages if no fix available"

    if [[ "$FAIL_ON_HIGH" == true ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓ No known vulnerabilities found${NC}"
fi

echo ""
echo "Run 'npm audit fix' or 'pip install --upgrade' to update packages"
