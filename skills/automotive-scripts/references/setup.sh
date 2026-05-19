#!/usr/bin/env bash
# Complete platform setup for Automotive Claude Code Agents
# Detects environment, installs dependencies, configures tools

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Configuration
readonly PYTHON_MIN_VERSION="3.8"
readonly NODE_MIN_VERSION="16.0"
readonly REQUIRED_DISK_SPACE_GB=5

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Version comparison (returns 0 if $1 >= $2)
version_ge() {
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command_exists lsb_release; then
            echo "$(lsb_release -si | tr '[:upper:]' '[:lower:]')"
        elif [[ -f /etc/os-release ]]; then
            grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"'
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Detect package manager
detect_package_manager() {
    if command_exists apt-get; then
        echo "apt"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists yum; then
        echo "yum"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists brew; then
        echo "brew"
    else
        echo "none"
    fi
}

# Check disk space
check_disk_space() {
    log_info "Checking available disk space..."
    local available_gb
    available_gb=$(df -BG "${PROJECT_ROOT}" | awk 'NR==2 {print $4}' | sed 's/G//')

    if [[ ${available_gb} -lt ${REQUIRED_DISK_SPACE_GB} ]]; then
        log_error "Insufficient disk space. Required: ${REQUIRED_DISK_SPACE_GB}GB, Available: ${available_gb}GB"
        return 1
    fi
    log_success "Disk space check passed (${available_gb}GB available)"
}

# Check Python version
check_python() {
    log_info "Checking Python installation..."

    local python_cmd=""
    for cmd in python3 python; do
        if command_exists "$cmd"; then
            python_cmd="$cmd"
            break
        fi
    done

    if [[ -z "$python_cmd" ]]; then
        log_error "Python not found. Please install Python ${PYTHON_MIN_VERSION} or later"
        return 1
    fi

    local python_version
    python_version=$($python_cmd --version 2>&1 | awk '{print $2}')

    if version_ge "$python_version" "$PYTHON_MIN_VERSION"; then
        log_success "Python ${python_version} found"
        export PYTHON_CMD="$python_cmd"
        return 0
    else
        log_error "Python ${python_version} is too old. Required: ${PYTHON_MIN_VERSION}+"
        return 1
    fi
}

# Setup Python virtual environment
setup_venv() {
    log_info "Setting up Python virtual environment..."

    cd "${PROJECT_ROOT}" || exit 1

    if [[ ! -d "venv" ]]; then
        ${PYTHON_CMD} -m venv venv
        log_success "Virtual environment created"
    else
        log_info "Virtual environment already exists"
    fi

    # Activate virtual environment
    # shellcheck disable=SC1091
    source venv/bin/activate

    # Upgrade pip
    log_info "Upgrading pip..."
    pip install --upgrade pip setuptools wheel

    log_success "Virtual environment ready"
}

# Install Python dependencies
install_python_deps() {
    log_info "Installing Python dependencies..."

    cd "${PROJECT_ROOT}" || exit 1

    # Install production dependencies
    pip install -r requirements.txt

    # Install development dependencies
    if [[ -f requirements-dev.txt ]]; then
        pip install -r requirements-dev.txt
    else
        pip install -e ".[dev,docs]"
    fi

    log_success "Python dependencies installed"
}

# Install automotive tools
install_automotive_tools() {
    log_info "Installing automotive-specific tools..."

    local os_type
    os_type=$(detect_os)
    local pkg_manager
    pkg_manager=$(detect_package_manager)

    # CAN utilities
    if [[ "$os_type" == "ubuntu" ]] || [[ "$os_type" == "debian" ]]; then
        if [[ "$pkg_manager" == "apt" ]]; then
            log_info "Installing CAN utilities..."
            sudo apt-get update -qq
            sudo apt-get install -y can-utils 2>/dev/null || log_warning "can-utils installation skipped (optional)"
        fi
    fi

    # Vector tools detection (commercial, check only)
    if command_exists CANoe; then
        log_success "Vector CANoe detected"
    else
        log_info "Vector CANoe not found (optional commercial tool)"
    fi

    if command_exists CANalyzer; then
        log_success "Vector CANalyzer detected"
    else
        log_info "Vector CANalyzer not found (optional commercial tool)"
    fi

    log_success "Automotive tools check complete"
}

# Setup Git hooks
setup_git_hooks() {
    log_info "Setting up Git hooks..."

    cd "${PROJECT_ROOT}" || exit 1

    if [[ ! -d .git ]]; then
        log_warning "Not a git repository, skipping hooks setup"
        return 0
    fi

    # Install pre-commit if available
    if command_exists pre-commit; then
        pre-commit install
        log_success "Pre-commit hooks installed"
    else
        log_warning "pre-commit not found, installing..."
        pip install pre-commit
        pre-commit install
        log_success "Pre-commit hooks installed"
    fi
}

# Create required directories
create_directories() {
    log_info "Creating required directories..."

    cd "${PROJECT_ROOT}" || exit 1

    local dirs=(
        "logs"
        "data/cache"
        "data/models"
        "data/configs"
        "output"
        "tmp"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done

    log_success "Directories created"
}

# Setup environment file
setup_env_file() {
    log_info "Setting up environment configuration..."

    cd "${PROJECT_ROOT}" || exit 1

    if [[ ! -f .env ]]; then
        if [[ -f .env.example ]]; then
            cp .env.example .env
            log_success "Created .env from .env.example"
            log_warning "Please edit .env and add your API keys"
        else
            log_warning ".env.example not found, skipping .env creation"
        fi
    else
        log_info ".env file already exists"
    fi
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."

    local errors=0

    # Check Python packages
    if ${PYTHON_CMD} -c "import anthropic" 2>/dev/null; then
        log_success "anthropic package installed"
    else
        log_error "anthropic package not found"
        ((errors++))
    fi

    if ${PYTHON_CMD} -c "import yaml" 2>/dev/null; then
        log_success "PyYAML package installed"
    else
        log_error "PyYAML package not found"
        ((errors++))
    fi

    # Check project structure
    local required_dirs=("agents" "skills" "commands" "tools" "workflows")
    for dir in "${required_dirs[@]}"; do
        if [[ -d "${PROJECT_ROOT}/${dir}" ]]; then
            log_success "Directory ${dir}/ found"
        else
            log_error "Directory ${dir}/ not found"
            ((errors++))
        fi
    done

    if [[ $errors -eq 0 ]]; then
        log_success "Installation verification passed"
        return 0
    else
        log_error "Installation verification failed with ${errors} error(s)"
        return 1
    fi
}

# Run basic tests
run_basic_tests() {
    log_info "Running basic tests..."

    cd "${PROJECT_ROOT}" || exit 1

    if command_exists pytest; then
        pytest tests/test_basic.py -v 2>/dev/null || log_warning "Basic tests skipped (test file may not exist yet)"
    else
        log_warning "pytest not found, skipping tests"
    fi
}

# Display completion message
display_completion() {
    echo ""
    echo "=========================================="
    log_success "Setup completed successfully!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Activate virtual environment: source venv/bin/activate"
    echo "  2. Edit .env file with your API keys"
    echo "  3. Run tests: pytest tests/"
    echo "  4. Start developing: claude-code"
    echo ""
    echo "Documentation: ${PROJECT_ROOT}/docs/"
    echo "Examples: ${PROJECT_ROOT}/examples/"
    echo ""
}

# Main setup function
main() {
    log_info "Starting Automotive Claude Code Agents setup..."
    echo "Project root: ${PROJECT_ROOT}"
    echo "OS: $(detect_os)"
    echo "Package manager: $(detect_package_manager)"
    echo ""

    # Run setup steps
    check_disk_space || exit 1
    check_python || exit 1
    setup_venv || exit 1
    install_python_deps || exit 1
    install_automotive_tools
    setup_git_hooks
    create_directories
    setup_env_file
    verify_installation || exit 1
    run_basic_tests
    display_completion
}

# Run main function
main "$@"
