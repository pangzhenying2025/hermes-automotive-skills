#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Yocto Build — Build Yocto/OpenEmbedded images for automotive targets
# ============================================================================
# Usage: yocto-build.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -m, --machine    Target machine configuration
#   -i, --image      Image recipe name (default: core-image-minimal)
#   -l, --layer      Additional layer to include
#   --sdk            Build SDK instead of image
#   --clean          Clean build artifacts first
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
MACHINE="qemuarm64"
IMAGE="core-image-minimal"
EXTRA_LAYERS=()
BUILD_SDK=false
CLEAN_BUILD=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -m, --machine    Target machine"
            echo "  -i, --image      Image recipe name"
            echo "  -l, --layer      Additional layer"
            echo "  --sdk            Build SDK"
            echo "  --clean          Clean first"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -m|--machine) MACHINE="$2"; shift 2 ;;
        -i|--image) IMAGE="$2"; shift 2 ;;
        -l|--layer) EXTRA_LAYERS+=("$2"); shift 2 ;;
        --sdk) BUILD_SDK=true; shift ;;
        --clean) CLEAN_BUILD=true; shift ;;
        *) shift ;;
    esac
done

check_yocto_environment() {
    info "Checking Yocto build environment..."
    if [[ -f "oe-init-build-env" ]]; then
        info "Build environment script found"
    else
        warn "oe-init-build-env not found in current directory"
    fi
    if command -v bitbake &>/dev/null; then
        info "BitBake found: $(bitbake --version 2>&1 | head -1 || echo 'available')"
    else
        warn "BitBake not in PATH (source oe-init-build-env first)"
    fi
}

check_disk_space() {
    info "Checking disk space..."
    local available_gb
    available_gb=$(df -BG . 2>/dev/null | awk 'NR==2{print $4}' | tr -d 'G' || echo "0")
    if (( available_gb < 50 )); then
        warn "Low disk space: ${available_gb}GB available (50GB+ recommended)"
    else
        info "Disk space: ${available_gb}GB available"
    fi
}

configure_build() {
    info "Build configuration:"
    info "  MACHINE: $MACHINE"
    info "  IMAGE: $IMAGE"
    info "  SDK: $BUILD_SDK"
    for layer in "${EXTRA_LAYERS[@]}"; do
        info "  Extra layer: $layer"
    done
}

show_build_command() {
    info "Build commands to execute:"
    echo ""
    if $CLEAN_BUILD; then
        info "  bitbake -c cleanall $IMAGE"
    fi
    if $BUILD_SDK; then
        info "  MACHINE=$MACHINE bitbake -c populate_sdk $IMAGE"
    else
        info "  MACHINE=$MACHINE bitbake $IMAGE"
    fi
    echo ""
    info "(Dry run - commands not executed)"
}

generate_build_config() {
    local config_file="./yocto-build-config.json"
    cat > "$config_file" <<EOF
{
    "yocto_build": {
        "machine": "${MACHINE}",
        "image": "${IMAGE}",
        "build_sdk": ${BUILD_SDK},
        "clean_build": ${CLEAN_BUILD},
        "extra_layers": $(printf '%s\n' "${EXTRA_LAYERS[@]:-}" | jq -Rn '[inputs | select(length>0)]' 2>/dev/null || echo '[]'),
        "estimated_time_hours": $(${BUILD_SDK} && echo 4 || echo 2),
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Build config written to: $config_file"
}

main() {
    info "Starting Yocto build preparation..."
    check_yocto_environment
    check_disk_space
    configure_build
    show_build_command
    generate_build_config
    info "Yocto build preparation complete"
}

main
