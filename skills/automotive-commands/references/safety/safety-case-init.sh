#!/usr/bin/env bash
# safety-case-init.sh - Initialize safety case folder structure
# Uses GSN (Goal Structuring Notation) pattern per ISO 26262-8

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
PROJECT_NAME=""
OUTPUT_DIR="./safety_case"
ASIL_LEVEL=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -p PROJECT_NAME [OPTIONS]

Initialize safety case folder structure with GSN templates.

Required:
    -p, --project NAME        Project name

Options:
    -o, --output DIR          Output directory (default: ./safety_case)
    -a, --asil LEVEL          ASIL level (A, B, C, D)
    -h, --help                Show this help message

Examples:
    # Initialize safety case for ASIL D brake system
    $0 -p "Electronic Brake Control" -a D

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project) PROJECT_NAME="$2"; shift 2 ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -a|--asil) ASIL_LEVEL="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

if [[ -z "$PROJECT_NAME" ]]; then
    echo -e "${RED}Error: Project name is required${NC}"
    usage
fi

echo -e "${BLUE}=== Safety Case Initialization ===${NC}"
echo "Project: $PROJECT_NAME"
echo "Output: $OUTPUT_DIR"
echo ""

# Create folder structure
mkdir -p "$OUTPUT_DIR"/{goals,strategies,solutions,context,assumptions,justifications,evidence}

# Create main safety case document
cat > "$OUTPUT_DIR/README.md" <<EOF
# Safety Case - $PROJECT_NAME

**ISO 26262-8 Compliance**
$(date +"%Y-%m-%d")
$(if [[ -n "$ASIL_LEVEL" ]]; then echo "**ASIL Level**: $ASIL_LEVEL"; fi)

## Goal Structuring Notation (GSN)

This safety case uses GSN to present safety arguments.

### Structure

- **goals/** - Safety goals and sub-goals
- **strategies/** - Argumentation strategies
- **solutions/** - Evidence and verification results
- **context/** - System context and assumptions
- **assumptions/** - Underlying assumptions
- **justifications/** - Rationale for choices
- **evidence/** - Supporting artifacts

## Top-Level Safety Claim

G1: $PROJECT_NAME is acceptably safe to operate in its intended environment.

See \`goals/G1_top_level.md\` for full argumentation.

EOF

# Create top-level goal
cat > "$OUTPUT_DIR/goals/G1_top_level.md" <<EOF
# G1: Top-Level Safety Goal

**Claim**: $PROJECT_NAME is acceptably safe to operate in its intended environment.

## Context

- C1: System operates in automotive environment (see \`context/C1_environment.md\`)
- C2: ASIL $ASIL_LEVEL requirements apply
- C3: ISO 26262:2018 development process followed

## Strategy

S1: Argument over hazard coverage

- All identified hazards are mitigated to acceptable risk level

## Sub-Goals

- G1.1: All hazards identified through HARA
- G1.2: All safety goals achieved
- G1.3: All safety requirements verified
- G1.4: Freedom from interference demonstrated (ASIL C/D)
- G1.5: No systematic faults in design

## Evidence

- E1: HARA worksheet (see \`evidence/HARA.md\`)
- E2: Safety requirements specification
- E3: Verification report
- E4: DFA report

EOF

# Create context document
cat > "$OUTPUT_DIR/context/C1_environment.md" <<EOF
# C1: Operational Environment

## Vehicle Type
- [ ] Passenger car (M1)
- [ ] Commercial vehicle (N1/N2/N3)
- [ ] Bus (M2/M3)

## Operating Conditions
- Temperature range:
- Voltage range:
- EMC environment:

## Operational Design Domain (ODD)
- Road types:
- Weather conditions:
- Speed range:

EOF

# Create strategy document
cat > "$OUTPUT_DIR/strategies/S1_hazard_coverage.md" <<EOF
# S1: Argument Over Hazard Coverage

## Strategy Description

Demonstrate safety by showing that:
1. All hazards have been identified
2. Each hazard has assigned safety goals
3. Safety goals are achieved through design

## Decomposition

This strategy decomposes into:
- G1.1: Hazard identification is complete
- G1.2: All safety goals are met

## Supporting Evidence

- HARA workshop records
- Hazard log
- Safety goal allocation

EOF

echo -e "${GREEN}✓ Safety case structure created${NC}"
echo ""
echo "Created structure:"
tree -L 2 "$OUTPUT_DIR" 2>/dev/null || find "$OUTPUT_DIR" -type f

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Complete HARA and add to evidence/"
echo "  2. Define safety goals in goals/"
echo "  3. Develop argumentation strategies in strategies/"
echo "  4. Link verification results in solutions/"
echo "  5. Document all assumptions in assumptions/"
