#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Kernel Config — Configure Linux kernel for automotive targets
# ============================================================================
# Usage: kernel-config.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -p, --preset     Preset config (minimal|automotive|realtime|debug)
#   -k, --kernel     Kernel source directory
#   --enable         Enable specific config option (e.g., CONFIG_CAN)
#   --disable        Disable specific config option
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
PRESET="automotive"
KERNEL_DIR=""
ENABLE_OPTS=()
DISABLE_OPTS=()
OUTPUT_DIR="./kernel-config-output"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -p, --preset     Config preset (minimal|automotive|realtime|debug)"
            echo "  -k, --kernel     Kernel source directory"
            echo "  --enable         Enable config option"
            echo "  --disable        Disable config option"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -p|--preset) PRESET="$2"; shift 2 ;;
        -k|--kernel) KERNEL_DIR="$2"; shift 2 ;;
        --enable) ENABLE_OPTS+=("$2"); shift 2 ;;
        --disable) DISABLE_OPTS+=("$2"); shift 2 ;;
        *) shift ;;
    esac
done

get_automotive_configs() {
    info "Automotive kernel configuration options:"
    local configs=(
        "CONFIG_CAN=y"
        "CONFIG_CAN_RAW=y"
        "CONFIG_CAN_GW=y"
        "CONFIG_CAN_VCAN=m"
        "CONFIG_NET_SCHED=y"
        "CONFIG_PREEMPT=y"
        "CONFIG_HIGH_RES_TIMERS=y"
        "CONFIG_GPIOLIB=y"
        "CONFIG_SPI=y"
        "CONFIG_I2C=y"
        "CONFIG_USB_GADGET=y"
        "CONFIG_CRYPTO_AES=y"
        "CONFIG_SECURITY=y"
        "CONFIG_IMA=y"
    )
    for cfg in "${configs[@]}"; do
        $VERBOSE && info "  $cfg"
    done
    info "  ${#configs[@]} automotive-specific options"
}

get_realtime_configs() {
    if [[ "$PRESET" == "realtime" ]]; then
        info "PREEMPT_RT kernel configuration:"
        info "  CONFIG_PREEMPT_RT=y"
        info "  CONFIG_HZ_1000=y"
        info "  CONFIG_NO_HZ_FULL=y"
        warn "  RT kernel requires PREEMPT_RT patch series"
    fi
}

generate_config_fragment() {
    mkdir -p "$OUTPUT_DIR"
    local fragment="$OUTPUT_DIR/automotive.cfg"
    info "Generating kernel config fragment..."

    cat > "$fragment" <<'KCFG'
# Automotive Kernel Configuration Fragment
# CAN Bus Support
CONFIG_CAN=y
CONFIG_CAN_RAW=y
CONFIG_CAN_BCM=y
CONFIG_CAN_GW=y
CONFIG_CAN_VCAN=m

# Automotive Networking
CONFIG_NET_SCHED=y
CONFIG_NET_CLS=y
CONFIG_TSN=y

# Real-time
CONFIG_PREEMPT=y
CONFIG_HIGH_RES_TIMERS=y

# Security
CONFIG_SECURITY=y
CONFIG_INTEGRITY=y
CONFIG_IMA=y
CONFIG_EVM=y

# Hardware interfaces
CONFIG_GPIOLIB=y
CONFIG_SPI=y
CONFIG_I2C=y
CONFIG_WATCHDOG=y
KCFG

    for opt in "${ENABLE_OPTS[@]}"; do
        echo "${opt}=y" >> "$fragment"
    done
    for opt in "${DISABLE_OPTS[@]}"; do
        echo "# ${opt} is not set" >> "$fragment"
    done

    info "Config fragment written to: $fragment"
}

generate_report() {
    local report="$OUTPUT_DIR/kernel-config.json"
    cat > "$report" <<EOF
{
    "kernel_config": {
        "preset": "${PRESET}",
        "kernel_dir": "${KERNEL_DIR:-not specified}",
        "enabled_options": ${#ENABLE_OPTS[@]},
        "disabled_options": ${#DISABLE_OPTS[@]},
        "fragment": "${OUTPUT_DIR}/automotive.cfg",
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "Report written to: $report"
}

main() {
    info "Starting kernel configuration (preset: $PRESET)..."
    get_automotive_configs
    get_realtime_configs
    generate_config_fragment
    generate_report
    info "Kernel configuration complete"
}

main
