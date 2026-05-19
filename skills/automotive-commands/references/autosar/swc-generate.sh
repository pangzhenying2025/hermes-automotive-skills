#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# SWC Generate — Generate AUTOSAR Software Component skeletons
# ============================================================================
# Usage: swc-generate.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -n, --name       SWC name (PascalCase)
#   -t, --type       SWC type (application|sensor-actuator|service|complex)
#   -p, --platform   Platform (classic|adaptive)
#   -o, --output     Output directory
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
SWC_NAME="MySwc"
SWC_TYPE="application"
PLATFORM="classic"
OUTPUT_DIR="./generated-swc"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -n, --name       SWC name (PascalCase)"
            echo "  -t, --type       SWC type (application|sensor-actuator|service|complex)"
            echo "  -p, --platform   Platform (classic|adaptive)"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -n|--name) SWC_NAME="$2"; shift 2 ;;
        -t|--type) SWC_TYPE="$2"; shift 2 ;;
        -p|--platform) PLATFORM="$2"; shift 2 ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        *) shift ;;
    esac
done

generate_classic_swc() {
    local swc_dir="$OUTPUT_DIR/$SWC_NAME"
    mkdir -p "$swc_dir/src" "$swc_dir/include" "$swc_dir/config"

    cat > "$swc_dir/src/${SWC_NAME}.c" <<SRCEOF
/* AUTOSAR SWC: ${SWC_NAME} (${SWC_TYPE}) */
#include "${SWC_NAME}.h"
#include "Rte_${SWC_NAME}.h"

#define ${SWC_NAME^^}_START_SEC_CODE
#include "MemMap.h"

void ${SWC_NAME}_Init(void)
{
    /* Initialize ${SWC_NAME} */
}

void ${SWC_NAME}_MainFunction(void)
{
    /* Cyclic runnable */
    Std_ReturnType status;
    /* Read input port */
    /* Process data */
    /* Write output port */
}

#define ${SWC_NAME^^}_STOP_SEC_CODE
#include "MemMap.h"
SRCEOF

    cat > "$swc_dir/include/${SWC_NAME}.h" <<HDREOF
#ifndef ${SWC_NAME^^}_H
#define ${SWC_NAME^^}_H

#include "Std_Types.h"

void ${SWC_NAME}_Init(void);
void ${SWC_NAME}_MainFunction(void);

#endif /* ${SWC_NAME^^}_H */
HDREOF

    info "Classic SWC generated: $swc_dir"
}

generate_adaptive_swc() {
    local swc_dir="$OUTPUT_DIR/$SWC_NAME"
    mkdir -p "$swc_dir/src" "$swc_dir/include" "$swc_dir/model"

    cat > "$swc_dir/src/${SWC_NAME}.cpp" <<CPPEOF
// AUTOSAR Adaptive SWC: ${SWC_NAME}
#include "${SWC_NAME}.h"
#include <ara/core/initialization.h>
#include <ara/log/logging.h>

namespace autosar {
namespace ${SWC_NAME,,} {

${SWC_NAME}::${SWC_NAME}() : logger_(ara::log::CreateLogger("${SWC_NAME:0:4}", "${SWC_NAME}")) {}

bool ${SWC_NAME}::Initialize() {
    logger_.LogInfo() << "${SWC_NAME} initializing";
    return true;
}

void ${SWC_NAME}::Run() {
    logger_.LogInfo() << "${SWC_NAME} running";
}

void ${SWC_NAME}::Shutdown() {
    logger_.LogInfo() << "${SWC_NAME} shutting down";
}

} // namespace ${SWC_NAME,,}
} // namespace autosar
CPPEOF

    cat > "$swc_dir/include/${SWC_NAME}.h" <<AHDREOF
#pragma once
#include <ara/log/logger.h>

namespace autosar {
namespace ${SWC_NAME,,} {

class ${SWC_NAME} {
public:
    ${SWC_NAME}();
    bool Initialize();
    void Run();
    void Shutdown();
private:
    ara::log::Logger& logger_;
};

} // namespace ${SWC_NAME,,}
} // namespace autosar
AHDREOF

    info "Adaptive SWC generated: $swc_dir"
}

generate_swc_description() {
    local desc_file="$OUTPUT_DIR/$SWC_NAME/config/${SWC_NAME}.arxml"
    mkdir -p "$(dirname "$desc_file")"
    info "SWC description ARXML written to: $desc_file"
    echo "<!-- AUTOSAR SWC Description for ${SWC_NAME} -->" > "$desc_file"
}

main() {
    info "Generating AUTOSAR SWC: $SWC_NAME ($SWC_TYPE, $PLATFORM)..."
    case "$PLATFORM" in
        classic) generate_classic_swc ;;
        adaptive) generate_adaptive_swc ;;
        *) error "Invalid platform: $PLATFORM"; exit 1 ;;
    esac
    generate_swc_description
    info "SWC generation complete: $OUTPUT_DIR/$SWC_NAME"
}

main
