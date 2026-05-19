#!/usr/bin/env bash
# Initialize new automotive project with Claude Code Agents
# Creates project structure, configs, and templates

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PLATFORM_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Project defaults
PROJECT_NAME=""
PROJECT_TYPE="adas"
PROJECT_DIR=""
USE_GIT=true
USE_DOCKER=true
USE_AUTOSAR=false

# Usage
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] PROJECT_NAME

Initialize a new automotive project with Claude Code Agents.

ARGUMENTS:
    PROJECT_NAME            Name of the project to create

OPTIONS:
    -t, --type TYPE         Project type: adas, battery, autosar, diagnostic (default: adas)
    -d, --dir DIRECTORY     Project directory (default: ./<project-name>)
    --no-git                Skip git initialization
    --no-docker             Skip Docker configuration
    --with-autosar          Include AUTOSAR configuration
    -h, --help              Show this help message

PROJECT TYPES:
    adas            ADAS/autonomous driving project
    battery         Battery management system
    autosar         AUTOSAR Classic/Adaptive project
    diagnostic      Diagnostic/UDS project

EXAMPLES:
    # Create ADAS project
    $(basename "$0") my-adas-project

    # Create battery management project with AUTOSAR
    $(basename "$0") -t battery --with-autosar bms-controller

    # Create project in specific directory
    $(basename "$0") -d /path/to/projects -t diagnostic obd-scanner

EOF
    exit 0
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--type)
                PROJECT_TYPE="$2"
                shift 2
                ;;
            -d|--dir)
                PROJECT_DIR="$2"
                shift 2
                ;;
            --no-git)
                USE_GIT=false
                shift
                ;;
            --no-docker)
                USE_DOCKER=false
                shift
                ;;
            --with-autosar)
                USE_AUTOSAR=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                PROJECT_NAME="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$PROJECT_NAME" ]]; then
        log_error "Project name required"
        usage
    fi

    if [[ -z "$PROJECT_DIR" ]]; then
        PROJECT_DIR="$(pwd)/${PROJECT_NAME}"
    fi
}

# Validate inputs
validate_inputs() {
    log_info "Validating inputs..."

    # Check project type
    case "$PROJECT_TYPE" in
        adas|battery|autosar|diagnostic)
            ;;
        *)
            log_error "Invalid project type: $PROJECT_TYPE"
            exit 1
            ;;
    esac

    # Check if directory exists
    if [[ -e "$PROJECT_DIR" ]]; then
        log_error "Directory already exists: $PROJECT_DIR"
        exit 1
    fi

    log_success "Validation passed"
}

# Create project structure
create_structure() {
    log_info "Creating project structure..."

    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR" || exit 1

    # Base structure
    mkdir -p src/{core,utils,interfaces}
    mkdir -p tests/{unit,integration,e2e}
    mkdir -p docs/{architecture,api,guides}
    mkdir -p configs/{dev,staging,prod}
    mkdir -p scripts
    mkdir -p data/{raw,processed,models}
    mkdir -p .github/workflows

    log_success "Project structure created"
}

# Create README
create_readme() {
    log_info "Creating README..."

    cat > "${PROJECT_DIR}/README.md" <<EOF
# ${PROJECT_NAME}

${PROJECT_TYPE^} project powered by Automotive Claude Code Agents.

## Overview

<!-- Add project description here -->

## Features

- Automotive-grade development with Claude Code
- Built-in safety and compliance checks
- Multi-model LLM Council for critical decisions
- Comprehensive testing and validation

## Getting Started

### Prerequisites

- Python 3.8+
- Automotive Claude Code Agents platform
- See \`requirements.txt\` for dependencies

### Installation

\`\`\`bash
# Clone and setup
git clone <repository-url>
cd ${PROJECT_NAME}

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest tests/
\`\`\`

### Usage

\`\`\`bash
# Run main application
python src/main.py

# Run with Claude Code
claude-code
\`\`\`

## Project Structure

\`\`\`
${PROJECT_NAME}/
├── src/              # Source code
│   ├── core/         # Core functionality
│   ├── utils/        # Utility functions
│   └── interfaces/   # External interfaces
├── tests/            # Test suites
├── docs/             # Documentation
├── configs/          # Configuration files
├── scripts/          # Build and deployment scripts
└── data/             # Data files
\`\`\`

## Development

### Running Tests

\`\`\`bash
# Unit tests
pytest tests/unit/

# Integration tests
pytest tests/integration/

# Coverage report
pytest --cov=src tests/
\`\`\`

### Code Quality

\`\`\`bash
# Format code
black src/ tests/

# Lint code
ruff check src/ tests/

# Type checking
mypy src/
\`\`\`

## Documentation

See [docs/](docs/) for comprehensive documentation.

## License

<!-- Add license information -->

## Contact

<!-- Add contact information -->

EOF

    log_success "README created"
}

# Create requirements.txt
create_requirements() {
    log_info "Creating requirements.txt..."

    cat > "${PROJECT_DIR}/requirements.txt" <<EOF
# ${PROJECT_NAME} - Python Dependencies

# Core dependencies
anthropic>=0.39.0
openai>=1.54.0
pyyaml>=6.0.2
python-dotenv>=1.0.0

# Automotive protocols
python-can>=4.4.2
cantools>=39.4.5

EOF

    # Add type-specific dependencies
    case "$PROJECT_TYPE" in
        adas)
            cat >> "${PROJECT_DIR}/requirements.txt" <<EOF
# ADAS/Perception
opencv-python>=4.8.0
numpy>=1.24.0
scipy>=1.11.0
open3d>=0.17.0

EOF
            ;;
        battery)
            cat >> "${PROJECT_DIR}/requirements.txt" <<EOF
# Battery Management
numpy>=1.24.0
scipy>=1.11.0
pandas>=2.0.0
matplotlib>=3.7.0

EOF
            ;;
        diagnostic)
            cat >> "${PROJECT_DIR}/requirements.txt" <<EOF
# Diagnostic Protocols
udsoncan>=1.21.0
doip>=1.2.0

EOF
            ;;
    esac

    cat >> "${PROJECT_DIR}/requirements.txt" <<EOF
# Testing
pytest>=8.3.3
pytest-cov>=5.0.0
pytest-asyncio>=0.23.8

# Code quality
black>=24.8.0
ruff>=0.6.9
mypy>=1.11.2
EOF

    log_success "requirements.txt created"
}

# Create .env.example
create_env_example() {
    log_info "Creating .env.example..."

    cat > "${PROJECT_DIR}/.env.example" <<EOF
# ${PROJECT_NAME} - Environment Configuration

# LLM APIs
ANTHROPIC_API_KEY=your_anthropic_api_key_here
OPENAI_API_KEY=your_openai_api_key_here

# Project settings
PROJECT_NAME=${PROJECT_NAME}
PROJECT_TYPE=${PROJECT_TYPE}
ENVIRONMENT=development

# CAN configuration
CAN_INTERFACE=vcan0
CAN_BITRATE=500000

# Logging
LOG_LEVEL=INFO
LOG_DIR=logs

# Development
DEBUG=true
EOF

    log_success ".env.example created"
}

# Create .gitignore
create_gitignore() {
    log_info "Creating .gitignore..."

    cat > "${PROJECT_DIR}/.gitignore" <<'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/
.venv/
pip-log.txt
pip-delete-this-directory.txt
.pytest_cache/
.coverage
htmlcov/
*.egg-info/
dist/
build/

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Environment
.env
.env.local
*.key
*.pem

# Logs
logs/
*.log

# Data
data/raw/*
data/processed/*
!data/.gitkeep

# Documentation builds
site/
docs/_build/

# OS
Thumbs.db
.DS_Store

# Temporary
tmp/
temp/
*.tmp

# Coverage
.coverage
htmlcov/

# MyPy
.mypy_cache/

# Ruff
.ruff_cache/
EOF

    log_success ".gitignore created"
}

# Create pytest config
create_pytest_config() {
    log_info "Creating pytest configuration..."

    cat > "${PROJECT_DIR}/pytest.ini" <<EOF
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts =
    -v
    --strict-markers
    --cov=src
    --cov-report=term-missing
    --cov-report=html
markers =
    unit: Unit tests
    integration: Integration tests
    e2e: End-to-end tests
    slow: Slow running tests
EOF

    log_success "pytest.ini created"
}

# Create Docker files
create_docker_files() {
    if [[ "$USE_DOCKER" != true ]]; then
        return
    fi

    log_info "Creating Docker configuration..."

    cat > "${PROJECT_DIR}/Dockerfile" <<'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Run tests
RUN pytest tests/

CMD ["python", "src/main.py"]
EOF

    cat > "${PROJECT_DIR}/docker-compose.yml" <<EOF
version: '3.8'

services:
  ${PROJECT_NAME}:
    build: .
    container_name: ${PROJECT_NAME}
    volumes:
      - ./src:/app/src
      - ./data:/app/data
      - ./configs:/app/configs
    environment:
      - ENVIRONMENT=development
    env_file:
      - .env
EOF

    log_success "Docker files created"
}

# Create sample code
create_sample_code() {
    log_info "Creating sample code..."

    cat > "${PROJECT_DIR}/src/main.py" <<EOF
"""
${PROJECT_NAME} - Main Application
"""

import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)


def main():
    """Main entry point for ${PROJECT_NAME}."""
    logger.info("Starting ${PROJECT_NAME} (${PROJECT_TYPE})")

    # TODO: Implement main functionality

    logger.info("${PROJECT_NAME} completed successfully")


if __name__ == "__main__":
    main()
EOF

    cat > "${PROJECT_DIR}/tests/test_basic.py" <<EOF
"""
Basic tests for ${PROJECT_NAME}
"""

import pytest


def test_import():
    """Test that main module can be imported."""
    from src import main
    assert hasattr(main, 'main')


def test_basic_functionality():
    """Test basic functionality."""
    # TODO: Add actual tests
    assert True
EOF

    log_success "Sample code created"
}

# Initialize git
init_git() {
    if [[ "$USE_GIT" != true ]]; then
        return
    fi

    log_info "Initializing git repository..."

    cd "$PROJECT_DIR" || exit 1

    git init
    git add .
    git commit -m "feat: initial project setup for ${PROJECT_NAME}

Project type: ${PROJECT_TYPE}
Generated by: Automotive Claude Code Agents"

    log_success "Git repository initialized"
}

# Create summary
create_summary() {
    echo ""
    echo "=========================================="
    log_success "Project ${PROJECT_NAME} created successfully!"
    echo "=========================================="
    echo ""
    echo "Project Details:"
    echo "  Name:      ${PROJECT_NAME}"
    echo "  Type:      ${PROJECT_TYPE}"
    echo "  Location:  ${PROJECT_DIR}"
    echo "  Git:       ${USE_GIT}"
    echo "  Docker:    ${USE_DOCKER}"
    echo "  AUTOSAR:   ${USE_AUTOSAR}"
    echo ""
    echo "Next Steps:"
    echo "  1. cd ${PROJECT_DIR}"
    echo "  2. cp .env.example .env"
    echo "  3. Edit .env with your configuration"
    echo "  4. pip install -r requirements.txt"
    echo "  5. pytest tests/"
    echo "  6. Start developing with Claude Code!"
    echo ""
}

# Main
main() {
    log_info "Automotive Claude Code - Project Initialization"
    echo ""

    parse_args "$@"
    validate_inputs
    create_structure
    create_readme
    create_requirements
    create_env_example
    create_gitignore
    create_pytest_config
    create_docker_files
    create_sample_code
    init_git
    create_summary
}

main "$@"
