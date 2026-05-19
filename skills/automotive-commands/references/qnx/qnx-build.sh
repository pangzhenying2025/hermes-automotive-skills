#!/bin/bash
# QNX Build Automation Script
# Compiles QNX projects for multiple architectures with optimized settings

set -e

# Default configuration
PROJECT_NAME=""
SOURCE_DIR="src"
OUTPUT_DIR="build"
ARCHITECTURE="aarch64le"
BUILD_TYPE="release"
VERBOSE=0

# QNX Environment
: ${QNX_HOST:=/opt/qnx710/host/linux/x86_64}
: ${QNX_TARGET:=/opt/qnx710/target/qnx7}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

QNX build automation for automotive projects.

OPTIONS:
    -n, --name NAME         Project name (required)
    -s, --source DIR        Source directory (default: src)
    -o, --output DIR        Output directory (default: build)
    -a, --arch ARCH         Target architecture: x86_64, aarch64le, armv7le (default: aarch64le)
    -t, --type TYPE         Build type: debug, release (default: release)
    -v, --verbose           Verbose output
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    QNX_HOST                QNX host tools path
    QNX_TARGET              QNX target files path

EXAMPLES:
    # Build for ARM64
    $0 --name can_service --arch aarch64le --type release

    # Debug build with verbose output
    $0 -n my_app -t debug -v

    # Build for x86_64 (simulation)
    $0 -n test_app -a x86_64

EOF
    exit 0
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_qnx_environment() {
    if [ ! -d "$QNX_HOST" ]; then
        log_error "QNX_HOST not found: $QNX_HOST"
        log_error "Please source QNX environment or set QNX_HOST"
        exit 1
    fi

    if [ ! -d "$QNX_TARGET" ]; then
        log_error "QNX_TARGET not found: $QNX_TARGET"
        exit 1
    fi

    local QCC="$QNX_HOST/usr/bin/qcc"
    if [ ! -x "$QCC" ]; then
        log_error "qcc compiler not found: $QCC"
        exit 1
    fi

    log_info "QNX Environment:"
    log_info "  QNX_HOST: $QNX_HOST"
    log_info "  QNX_TARGET: $QNX_TARGET"
    log_info "  Compiler: $QCC"
}

build_project() {
    local project_name="$1"
    local arch="$2"
    local build_type="$3"

    log_info "Building project: $project_name"
    log_info "Architecture: $arch"
    log_info "Build type: $build_type"

    # Create output directory
    local output_path="$OUTPUT_DIR/$arch/$build_type"
    mkdir -p "$output_path"

    # Find source files
    local sources=$(find "$SOURCE_DIR" -name "*.c" -o -name "*.cpp" 2>/dev/null)
    if [ -z "$sources" ]; then
        log_error "No source files found in $SOURCE_DIR"
        exit 1
    fi

    log_info "Source files:"
    for src in $sources; do
        log_info "  - $src"
    done

    # Determine compiler
    local compiler="$QNX_HOST/usr/bin/qcc"
    if echo "$sources" | grep -q "\.cpp$"; then
        compiler="$QNX_HOST/usr/bin/q++"
    fi

    # Build compiler command
    local cmd="$compiler"
    cmd="$cmd -V gcc_nto${arch}"

    # Build type specific flags
    if [ "$build_type" = "debug" ]; then
        cmd="$cmd -g -O0 -DDEBUG"
    else
        cmd="$cmd -O2 -DNDEBUG"
    fi

    # Common flags
    cmd="$cmd -Wall -Wextra"

    # Output
    cmd="$cmd -o $output_path/$project_name"

    # Add sources
    cmd="$cmd $sources"

    # Execute build
    log_info "Executing: $cmd"
    if [ $VERBOSE -eq 1 ]; then
        eval $cmd
    else
        eval $cmd 2>&1 | grep -v "^$" || true
    fi

    if [ $? -eq 0 ]; then
        local binary="$output_path/$project_name"
        local size=$(stat -c%s "$binary" 2>/dev/null || echo "unknown")
        log_info "Build successful!"
        log_info "Binary: $binary"
        log_info "Size: $size bytes"
    else
        log_error "Build failed"
        exit 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -s|--source)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -a|--arch)
            ARCHITECTURE="$2"
            shift 2
            ;;
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$PROJECT_NAME" ]; then
    log_error "Project name is required (-n/--name)"
    usage
fi

# Check QNX environment
check_qnx_environment

# Build project
build_project "$PROJECT_NAME" "$ARCHITECTURE" "$BUILD_TYPE"

log_info "Build complete!"
