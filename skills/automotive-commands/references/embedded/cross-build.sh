#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Cross Build — Cross-compile automotive embedded software
# ============================================================================
# Usage: cross-build.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -t, --target     Target architecture (arm|arm64|x86_64|riscv)
#   -s, --source     Source directory
#   -b, --build-type Build type (debug|release|relwithdebinfo)
#   --toolchain      CMake toolchain file
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

VERBOSE=false
TARGET_ARCH="arm64"
SOURCE_DIR="."
BUILD_TYPE="release"
TOOLCHAIN_FILE=""
BUILD_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -t, --target     Target arch (arm|arm64|x86_64|riscv)"
            echo "  -s, --source     Source directory"
            echo "  -b, --build-type Build type (debug|release|relwithdebinfo)"
            echo "  --toolchain      CMake toolchain file"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -t|--target) TARGET_ARCH="$2"; shift 2 ;;
        -s|--source) SOURCE_DIR="$2"; shift 2 ;;
        -b|--build-type) BUILD_TYPE="$2"; shift 2 ;;
        --toolchain) TOOLCHAIN_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

BUILD_DIR="build-${TARGET_ARCH}-${BUILD_TYPE}"

detect_toolchain() {
    info "Detecting cross-compilation toolchain for $TARGET_ARCH..."
    local prefix=""
    case "$TARGET_ARCH" in
        arm)    prefix="arm-linux-gnueabihf" ;;
        arm64)  prefix="aarch64-linux-gnu" ;;
        x86_64) prefix="x86_64-linux-gnu" ;;
        riscv)  prefix="riscv64-linux-gnu" ;;
        *) error "Unsupported target: $TARGET_ARCH"; return 1 ;;
    esac

    if command -v "${prefix}-gcc" &>/dev/null; then
        info "Toolchain found: ${prefix}-gcc"
        local version
        version=$("${prefix}-gcc" --version 2>/dev/null | head -1 || echo "unknown")
        $VERBOSE && info "  Version: $version"
    else
        warn "Toolchain ${prefix}-gcc not in PATH"
        info "Checking for SDK environment..."
    fi
}

check_sdk_environment() {
    if [[ -n "${OECORE_TARGET_SYSROOT:-}" ]]; then
        info "Yocto SDK detected: $OECORE_TARGET_SYSROOT"
    elif [[ -n "${SDKTARGETSYSROOT:-}" ]]; then
        info "SDK sysroot: $SDKTARGETSYSROOT"
    else
        warn "No SDK environment detected"
        info "Hint: source /opt/sdk/environment-setup-* before building"
    fi
}

configure_build() {
    info "Configuring CMake build..."
    info "  Source: $SOURCE_DIR"
    info "  Build dir: $BUILD_DIR"
    info "  Type: $BUILD_TYPE"
    info "  Target: $TARGET_ARCH"

    local cmake_cmd="cmake -S $SOURCE_DIR -B $BUILD_DIR"
    cmake_cmd="$cmake_cmd -DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
    [[ -n "$TOOLCHAIN_FILE" ]] && cmake_cmd="$cmake_cmd -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE"

    info "CMake command: $cmake_cmd"
    $VERBOSE && info "  (dry run - not executing)"
}

build_project() {
    info "Building project..."
    local nproc_val
    nproc_val=$(nproc 2>/dev/null || echo 4)
    info "  Build command: cmake --build $BUILD_DIR -j${nproc_val}"
    info "  Build configured (dry run)"
}

generate_build_summary() {
    local summary="./cross-build-summary.json"
    cat > "$summary" <<EOF
{
    "cross_build": {
        "target_arch": "${TARGET_ARCH}",
        "build_type": "${BUILD_TYPE}",
        "source_dir": "${SOURCE_DIR}",
        "build_dir": "${BUILD_DIR}",
        "toolchain": "${TOOLCHAIN_FILE:-auto-detected}",
        "status": "configured",
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Build summary written to: $summary"
}

main() {
    info "Starting cross-build for $TARGET_ARCH..."
    detect_toolchain
    check_sdk_environment
    configure_build
    build_project
    generate_build_summary
    info "Cross-build setup complete"
}

main
