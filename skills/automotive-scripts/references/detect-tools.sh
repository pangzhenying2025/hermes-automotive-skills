#!/usr/bin/env bash
# Detect and display all automotive development tools
# Provides comprehensive tool inventory for the platform

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

python_module_exists() {
    python3 -c "import $1" 2>/dev/null
}

# Print table header
print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

# Print tool status
print_tool() {
    local name="$1"
    local status="$2"
    local version="${3:-}"

    printf "  %-30s " "$name"
    if [[ "$status" == "installed" ]]; then
        echo -e "${GREEN}[INSTALLED]${NC} $version"
    elif [[ "$status" == "optional" ]]; then
        echo -e "${YELLOW}[OPTIONAL]${NC} $version"
    else
        echo -e "${RED}[NOT FOUND]${NC}"
    fi
}

# Detect system information
detect_system() {
    print_header "SYSTEM INFORMATION"

    echo "  OS:            $(uname -s)"
    echo "  Kernel:        $(uname -r)"
    echo "  Architecture:  $(uname -m)"
    echo "  Hostname:      $(hostname)"

    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "  Distribution:  $NAME $VERSION"
    fi
}

# Detect core development tools
detect_core_tools() {
    print_header "CORE DEVELOPMENT TOOLS"

    if command_exists python3; then
        print_tool "Python 3" "installed" "$(python3 --version | cut -d' ' -f2)"
    else
        print_tool "Python 3" "missing"
    fi

    if command_exists pip || command_exists pip3; then
        local pip_cmd
        pip_cmd=$(command_exists pip3 && echo "pip3" || echo "pip")
        print_tool "pip" "installed" "$($pip_cmd --version | cut -d' ' -f2)"
    else
        print_tool "pip" "missing"
    fi

    if command_exists git; then
        print_tool "git" "installed" "$(git --version | cut -d' ' -f3)"
    else
        print_tool "git" "missing"
    fi

    if command_exists cmake; then
        print_tool "cmake" "installed" "$(cmake --version | head -1 | cut -d' ' -f3)"
    else
        print_tool "cmake" "optional"
    fi

    if command_exists gcc; then
        print_tool "gcc" "installed" "$(gcc --version | head -1 | cut -d' ' -f4)"
    else
        print_tool "gcc" "optional"
    fi

    if command_exists g++; then
        print_tool "g++" "installed" "$(g++ --version | head -1 | cut -d' ' -f4)"
    else
        print_tool "g++" "optional"
    fi

    if command_exists clang; then
        print_tool "clang" "installed" "$(clang --version | head -1 | cut -d' ' -f3)"
    else
        print_tool "clang" "optional"
    fi
}

# Detect Python packages
detect_python_packages() {
    print_header "PYTHON PACKAGES"

    local packages=(
        "anthropic:Anthropic API"
        "openai:OpenAI API"
        "yaml:PyYAML"
        "dotenv:python-dotenv"
        "can:python-can"
        "cantools:cantools"
        "pytest:pytest"
        "black:black"
        "ruff:ruff"
        "mypy:mypy"
    )

    for pkg in "${packages[@]}"; do
        IFS=':' read -r module name <<< "$pkg"
        if python_module_exists "$module"; then
            local version
            version=$(python3 -c "import $module; print(getattr($module, '__version__', 'unknown'))" 2>/dev/null || echo "unknown")
            print_tool "$name" "installed" "$version"
        else
            print_tool "$name" "missing"
        fi
    done
}

# Detect CAN tools
detect_can_tools() {
    print_header "CAN BUS TOOLS"

    if command_exists candump; then
        print_tool "can-utils (candump)" "installed" "$(candump --version 2>&1 | head -1 || echo 'available')"
    else
        print_tool "can-utils" "missing"
    fi

    if command_exists cansend; then
        print_tool "can-utils (cansend)" "installed"
    else
        print_tool "can-utils (cansend)" "missing"
    fi

    if python_module_exists "can"; then
        print_tool "python-can" "installed"
    else
        print_tool "python-can" "missing"
    fi

    if python_module_exists "cantools"; then
        print_tool "cantools (DBC parser)" "installed"
    else
        print_tool "cantools" "missing"
    fi
}

# Detect Vector tools
detect_vector_tools() {
    print_header "VECTOR TOOLS (COMMERCIAL)"

    if command_exists CANoe; then
        print_tool "CANoe" "installed" "$(CANoe --version 2>/dev/null || echo 'detected')"
    else
        print_tool "CANoe" "optional" "not found"
    fi

    if command_exists CANalyzer; then
        print_tool "CANalyzer" "installed"
    else
        print_tool "CANalyzer" "optional" "not found"
    fi

    if command_exists CANape; then
        print_tool "CANape" "installed"
    else
        print_tool "CANape" "optional" "not found"
    fi
}

# Detect AUTOSAR tools
detect_autosar_tools() {
    print_header "AUTOSAR TOOLS"

    if [[ -d "/opt/EB/tresos" ]]; then
        print_tool "EB tresos Studio" "installed" "$(cat /opt/EB/tresos/version.txt 2>/dev/null || echo 'detected')"
    elif [[ -d "$HOME/EB/tresos" ]]; then
        print_tool "EB tresos Studio" "installed" "detected in home"
    else
        print_tool "EB tresos Studio" "optional" "not found"
    fi

    if python_module_exists "lxml"; then
        print_tool "lxml (ARXML parser)" "installed"
    else
        print_tool "lxml" "missing"
    fi

    if python_module_exists "xmlschema"; then
        print_tool "xmlschema" "installed"
    else
        print_tool "xmlschema" "optional"
    fi
}

# Detect diagnostic tools
detect_diagnostic_tools() {
    print_header "DIAGNOSTIC TOOLS (UDS, DoIP, XCP)"

    if python_module_exists "udsoncan"; then
        print_tool "udsoncan (UDS)" "installed"
    else
        print_tool "udsoncan" "optional"
    fi

    if python_module_exists "doip"; then
        print_tool "doip (DoIP)" "installed"
    else
        print_tool "doip" "optional"
    fi

    if command_exists socat; then
        print_tool "socat" "installed"
    else
        print_tool "socat" "optional"
    fi
}

# Detect ADAS tools
detect_adas_tools() {
    print_header "ADAS & PERCEPTION TOOLS"

    if python_module_exists "cv2"; then
        local cv_version
        cv_version=$(python3 -c "import cv2; print(cv2.__version__)" 2>/dev/null)
        print_tool "OpenCV" "installed" "$cv_version"
    else
        print_tool "OpenCV" "optional"
    fi

    if python_module_exists "numpy"; then
        print_tool "NumPy" "installed"
    else
        print_tool "NumPy" "missing"
    fi

    if python_module_exists "open3d"; then
        print_tool "Open3D (point clouds)" "installed"
    else
        print_tool "Open3D" "optional"
    fi

    if python_module_exists "torch"; then
        print_tool "PyTorch" "installed"
    else
        print_tool "PyTorch" "optional"
    fi
}

# Detect ROS tools
detect_ros_tools() {
    print_header "ROS TOOLS"

    if [[ -f /opt/ros/humble/setup.bash ]]; then
        print_tool "ROS 2 Humble" "installed"
    elif [[ -f /opt/ros/foxy/setup.bash ]]; then
        print_tool "ROS 2 Foxy" "installed"
    elif [[ -f /opt/ros/noetic/setup.bash ]]; then
        print_tool "ROS Noetic" "installed"
    else
        print_tool "ROS" "optional" "not found"
    fi

    if command_exists ros2; then
        print_tool "ros2 CLI" "installed"
    else
        print_tool "ros2 CLI" "optional"
    fi
}

# Detect code quality tools
detect_quality_tools() {
    print_header "CODE QUALITY TOOLS"

    if command_exists black; then
        print_tool "black" "installed" "$(black --version | cut -d' ' -f3)"
    else
        print_tool "black" "missing"
    fi

    if command_exists ruff; then
        print_tool "ruff" "installed" "$(ruff --version | cut -d' ' -f2)"
    else
        print_tool "ruff" "missing"
    fi

    if command_exists mypy; then
        print_tool "mypy" "installed" "$(mypy --version | cut -d' ' -f2)"
    else
        print_tool "mypy" "optional"
    fi

    if command_exists clang-format; then
        print_tool "clang-format" "installed" "$(clang-format --version | cut -d' ' -f3)"
    else
        print_tool "clang-format" "optional"
    fi

    if command_exists cppcheck; then
        print_tool "cppcheck" "installed" "$(cppcheck --version | cut -d' ' -f2)"
    else
        print_tool "cppcheck" "optional"
    fi

    if command_exists pre-commit; then
        print_tool "pre-commit" "installed" "$(pre-commit --version | cut -d' ' -f2)"
    else
        print_tool "pre-commit" "optional"
    fi
}

# Detect testing tools
detect_test_tools() {
    print_header "TESTING FRAMEWORKS"

    if command_exists pytest; then
        print_tool "pytest" "installed" "$(pytest --version | cut -d' ' -f2)"
    else
        print_tool "pytest" "missing"
    fi

    if python_module_exists "pytest_cov"; then
        print_tool "pytest-cov" "installed"
    else
        print_tool "pytest-cov" "optional"
    fi

    if python_module_exists "hypothesis"; then
        print_tool "hypothesis" "installed"
    else
        print_tool "hypothesis" "optional"
    fi
}

# Detect documentation tools
detect_doc_tools() {
    print_header "DOCUMENTATION TOOLS"

    if command_exists mkdocs; then
        print_tool "mkdocs" "installed" "$(mkdocs --version | cut -d' ' -f3)"
    else
        print_tool "mkdocs" "optional"
    fi

    if command_exists doxygen; then
        print_tool "doxygen" "installed" "$(doxygen --version)"
    else
        print_tool "doxygen" "optional"
    fi

    if command_exists sphinx-build; then
        print_tool "sphinx" "installed"
    else
        print_tool "sphinx" "optional"
    fi

    if command_exists dot; then
        print_tool "graphviz (dot)" "installed" "$(dot -V 2>&1 | cut -d' ' -f5)"
    else
        print_tool "graphviz" "optional"
    fi
}

# Detect container tools
detect_container_tools() {
    print_header "CONTAINERIZATION TOOLS"

    if command_exists docker; then
        print_tool "docker" "installed" "$(docker --version | cut -d' ' -f3 | tr -d ',')"
    else
        print_tool "docker" "optional"
    fi

    if command_exists podman; then
        print_tool "podman" "installed" "$(podman --version | cut -d' ' -f3)"
    else
        print_tool "podman" "optional"
    fi

    if command_exists docker-compose; then
        print_tool "docker-compose" "installed" "$(docker-compose --version | cut -d' ' -f3 | tr -d ',')"
    elif docker compose version >/dev/null 2>&1; then
        print_tool "docker compose" "installed" "$(docker compose version --short)"
    else
        print_tool "docker-compose" "optional"
    fi
}

# Summary
print_summary() {
    print_header "SUMMARY"

    local essential_ok=true

    # Check essential tools
    if ! command_exists python3; then essential_ok=false; fi
    if ! command_exists git; then essential_ok=false; fi
    if ! python_module_exists "yaml"; then essential_ok=false; fi

    if $essential_ok; then
        echo -e "  ${GREEN}Essential tools: All present${NC}"
    else
        echo -e "  ${RED}Essential tools: MISSING${NC}"
        echo "  Run: scripts/install-tools.sh"
    fi

    # Count optional tools
    local optional_count=0
    if command_exists cmake; then ((optional_count++)); fi
    if python_module_exists "can"; then ((optional_count++)); fi
    if command_exists pytest; then ((optional_count++)); fi
    if command_exists docker; then ((optional_count++)); fi

    echo "  Optional tools:  ${optional_count} detected"
    echo ""
    echo "  For full installation: scripts/install-tools.sh"
}

# Main
main() {
    clear
    echo "Automotive Claude Code - Tool Detection"
    echo "========================================"

    detect_system
    detect_core_tools
    detect_python_packages
    detect_can_tools
    detect_vector_tools
    detect_autosar_tools
    detect_diagnostic_tools
    detect_adas_tools
    detect_ros_tools
    detect_quality_tools
    detect_test_tools
    detect_doc_tools
    detect_container_tools
    print_summary

    echo ""
}

main "$@"
