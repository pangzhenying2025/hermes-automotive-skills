#!/usr/bin/env bash
# Install comprehensive opensource automotive development tools
# Supports multiple platforms and detects existing installations

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS and package manager
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"'
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

detect_pkg_manager() {
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

# Install system dependencies
install_system_deps() {
    log_info "Installing system dependencies..."

    local os_type
    os_type=$(detect_os)
    local pkg_manager
    pkg_manager=$(detect_pkg_manager)

    case "$pkg_manager" in
        apt)
            sudo apt-get update -qq
            sudo apt-get install -y \
                build-essential \
                git \
                wget \
                curl \
                unzip \
                cmake \
                ninja-build \
                pkg-config \
                libssl-dev \
                libffi-dev \
                python3-dev \
                can-utils \
                iproute2 \
                net-tools \
                socat \
                graphviz \
                2>/dev/null || log_warning "Some packages may not be available"
            ;;
        dnf|yum)
            sudo $pkg_manager install -y \
                gcc \
                gcc-c++ \
                git \
                wget \
                curl \
                unzip \
                cmake \
                ninja-build \
                pkgconfig \
                openssl-devel \
                libffi-devel \
                python3-devel \
                can-utils \
                iproute \
                net-tools \
                socat \
                graphviz \
                2>/dev/null || log_warning "Some packages may not be available"
            ;;
        pacman)
            sudo pacman -Sy --noconfirm \
                base-devel \
                git \
                wget \
                curl \
                unzip \
                cmake \
                ninja \
                pkg-config \
                openssl \
                libffi \
                python \
                can-utils \
                iproute2 \
                net-tools \
                socat \
                graphviz \
                2>/dev/null || log_warning "Some packages may not be available"
            ;;
        brew)
            brew install \
                git \
                wget \
                curl \
                cmake \
                ninja \
                pkg-config \
                openssl \
                libffi \
                python@3.11 \
                socat \
                graphviz \
                2>/dev/null || log_warning "Some packages may not be available"
            ;;
        *)
            log_warning "Unknown package manager, skipping system dependencies"
            ;;
    esac

    log_success "System dependencies installed"
}

# Install CAN tools
install_can_tools() {
    log_info "Installing CAN bus tools..."

    local os_type
    os_type=$(detect_os)

    # can-utils (already handled in system deps for Linux)
    if command_exists candump; then
        log_success "can-utils installed"
    else
        log_warning "can-utils not available on this platform"
    fi

    # Python CAN packages
    pip install --upgrade \
        python-can \
        cantools \
        python-j1939 \
        canmatrix

    log_success "Python CAN tools installed"
}

# Install Vector tools detection (commercial)
check_vector_tools() {
    log_info "Checking for Vector tools..."

    local tools_found=0

    if command_exists CANoe; then
        log_success "Vector CANoe found"
        ((tools_found++))
    fi

    if command_exists CANalyzer; then
        log_success "Vector CANalyzer found"
        ((tools_found++))
    fi

    if command_exists CANape; then
        log_success "Vector CANape found"
        ((tools_found++))
    fi

    if [[ $tools_found -eq 0 ]]; then
        log_info "No Vector tools detected (optional commercial tools)"
        log_info "Visit https://www.vector.com/ for licenses"
    fi
}

# Install AUTOSAR tools
install_autosar_tools() {
    log_info "Installing AUTOSAR development tools..."

    # EB tresos (check only, commercial)
    if [[ -d "/opt/EB/tresos" ]] || [[ -d "$HOME/EB/tresos" ]]; then
        log_success "EB tresos Studio detected"
    else
        log_info "EB tresos Studio not found (optional commercial tool)"
        log_info "Visit https://www.elektrobit.com/tresos/ for licenses"
    fi

    # ARXML parsers
    pip install --upgrade \
        lxml \
        xmlschema

    log_success "AUTOSAR XML tools installed"
}

# Install diagnostic tools
install_diagnostic_tools() {
    log_info "Installing diagnostic tools (UDS, DoIP, XCP)..."

    # Python diagnostic packages
    pip install --upgrade \
        udsoncan \
        doip \
        python-uds

    log_success "Diagnostic protocol libraries installed"
}

# Install ADAS/perception tools
install_adas_tools() {
    log_info "Installing ADAS and perception tools..."

    # OpenCV and vision libraries
    pip install --upgrade \
        opencv-python \
        opencv-contrib-python \
        numpy \
        scipy \
        scikit-image \
        pillow

    # Point cloud processing
    pip install --upgrade \
        open3d \
        pyntcloud

    log_success "ADAS tools installed"
}

# Install ROS tools (optional)
install_ros_tools() {
    log_info "Checking for ROS installation..."

    if [[ -f /opt/ros/humble/setup.bash ]]; then
        log_success "ROS 2 Humble detected"
    elif [[ -f /opt/ros/foxy/setup.bash ]]; then
        log_success "ROS 2 Foxy detected"
    elif [[ -f /opt/ros/noetic/setup.bash ]]; then
        log_success "ROS Noetic detected"
    else
        log_info "ROS not detected (optional for sensor simulation)"
        log_info "Visit https://www.ros.org/ for installation"
    fi

    # ROS Python tools
    pip install --upgrade \
        rosdep \
        rosinstall \
        rosinstall-generator \
        rospkg \
        2>/dev/null || log_warning "ROS Python tools skipped"
}

# Install battery management tools
install_battery_tools() {
    log_info "Installing battery management system tools..."

    # Battery modeling and analysis
    pip install --upgrade \
        numpy \
        scipy \
        pandas \
        matplotlib \
        seaborn

    # CAN-based BMS tools (already covered by python-can)
    log_success "Battery management tools installed"
}

# Install code quality tools
install_quality_tools() {
    log_info "Installing code quality tools..."

    # Python quality tools
    pip install --upgrade \
        black \
        ruff \
        mypy \
        pylint \
        flake8 \
        isort \
        bandit \
        safety

    # Pre-commit framework
    pip install --upgrade pre-commit

    # C/C++ tools (if available)
    local pkg_manager
    pkg_manager=$(detect_pkg_manager)

    case "$pkg_manager" in
        apt)
            sudo apt-get install -y \
                clang-format \
                clang-tidy \
                cppcheck \
                valgrind \
                2>/dev/null || log_warning "Some C++ tools not available"
            ;;
        dnf|yum)
            sudo $pkg_manager install -y \
                clang-tools-extra \
                cppcheck \
                valgrind \
                2>/dev/null || log_warning "Some C++ tools not available"
            ;;
        brew)
            brew install \
                clang-format \
                cppcheck \
                valgrind \
                2>/dev/null || log_warning "Some C++ tools not available"
            ;;
    esac

    log_success "Code quality tools installed"
}

# Install documentation tools
install_doc_tools() {
    log_info "Installing documentation tools..."

    # Python documentation
    pip install --upgrade \
        mkdocs \
        mkdocs-material \
        mkdocstrings \
        mkdocs-mermaid2-plugin \
        sphinx \
        sphinx-rtd-theme

    # Doxygen for C/C++
    local pkg_manager
    pkg_manager=$(detect_pkg_manager)

    case "$pkg_manager" in
        apt)
            sudo apt-get install -y doxygen graphviz 2>/dev/null
            ;;
        dnf|yum)
            sudo $pkg_manager install -y doxygen graphviz 2>/dev/null
            ;;
        brew)
            brew install doxygen graphviz 2>/dev/null
            ;;
    esac

    log_success "Documentation tools installed"
}

# Install testing frameworks
install_test_tools() {
    log_info "Installing testing frameworks..."

    # Python testing
    pip install --upgrade \
        pytest \
        pytest-cov \
        pytest-asyncio \
        pytest-mock \
        pytest-xdist \
        hypothesis \
        faker

    # C/C++ testing (if available)
    local pkg_manager
    pkg_manager=$(detect_pkg_manager)

    case "$pkg_manager" in
        apt)
            sudo apt-get install -y \
                libgtest-dev \
                libgmock-dev \
                2>/dev/null || log_warning "GoogleTest not available via apt"
            ;;
        dnf|yum)
            sudo $pkg_manager install -y \
                gtest-devel \
                gmock-devel \
                2>/dev/null || log_warning "GoogleTest not available"
            ;;
        brew)
            brew install googletest 2>/dev/null
            ;;
    esac

    log_success "Testing frameworks installed"
}

# Install containerization tools
install_container_tools() {
    log_info "Checking containerization tools..."

    if command_exists docker; then
        log_success "Docker installed: $(docker --version)"
    else
        log_info "Docker not found (optional for containerized builds)"
        log_info "Visit https://docs.docker.com/get-docker/"
    fi

    if command_exists podman; then
        log_success "Podman installed: $(podman --version)"
    else
        log_info "Podman not found (optional Docker alternative)"
    fi

    if command_exists docker-compose || command_exists docker compose; then
        log_success "Docker Compose installed"
    else
        log_info "Docker Compose not found (optional)"
    fi
}

# Install monitoring tools
install_monitoring_tools() {
    log_info "Installing monitoring and profiling tools..."

    # Python profiling
    pip install --upgrade \
        py-spy \
        memory-profiler \
        line-profiler \
        scalene

    # System monitoring
    pip install --upgrade \
        psutil \
        gputil

    log_success "Monitoring tools installed"
}

# Verify all installations
verify_tools() {
    log_info "Verifying tool installations..."

    local tools_ok=0
    local tools_total=0

    # Check Python
    ((tools_total++))
    if command_exists python3; then
        log_success "Python 3: $(python3 --version)"
        ((tools_ok++))
    fi

    # Check pip
    ((tools_total++))
    if command_exists pip; then
        log_success "pip: $(pip --version | cut -d' ' -f2)"
        ((tools_ok++))
    fi

    # Check git
    ((tools_total++))
    if command_exists git; then
        log_success "git: $(git --version | cut -d' ' -f3)"
        ((tools_ok++))
    fi

    # Check cmake
    ((tools_total++))
    if command_exists cmake; then
        log_success "cmake: $(cmake --version | head -1 | cut -d' ' -f3)"
        ((tools_ok++))
    fi

    # Check CAN tools
    ((tools_total++))
    if python3 -c "import can" 2>/dev/null; then
        log_success "python-can installed"
        ((tools_ok++))
    fi

    # Check testing
    ((tools_total++))
    if command_exists pytest; then
        log_success "pytest: $(pytest --version | cut -d' ' -f2)"
        ((tools_ok++))
    fi

    echo ""
    log_info "Verification complete: ${tools_ok}/${tools_total} essential tools installed"

    if [[ $tools_ok -eq $tools_total ]]; then
        log_success "All essential tools verified"
        return 0
    else
        log_warning "Some tools missing, but platform may still function"
        return 0
    fi
}

# Main installation
main() {
    echo "=========================================="
    log_info "Automotive Claude Code - Tool Installation"
    echo "=========================================="
    echo ""
    log_info "OS: $(detect_os)"
    log_info "Package Manager: $(detect_pkg_manager)"
    echo ""

    install_system_deps
    install_can_tools
    check_vector_tools
    install_autosar_tools
    install_diagnostic_tools
    install_adas_tools
    install_ros_tools
    install_battery_tools
    install_quality_tools
    install_doc_tools
    install_test_tools
    install_container_tools
    install_monitoring_tools
    verify_tools

    echo ""
    echo "=========================================="
    log_success "Tool installation complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Run: scripts/detect-tools.sh to see all installed tools"
    echo "  2. Configure tools in .env file"
    echo "  3. Run tests: pytest tests/"
    echo ""
}

main "$@"
