#!/usr/bin/env bash
# ARM Cross-Compilation Command
# Build embedded firmware for ARM targets

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] SOURCE_FILES...

Cross-compile C/C++ code for ARM microcontrollers

OPTIONS:
    -t, --target TARGET     ARM target (cortex-m4, cortex-m7, etc.)
    -O, --optimize LEVEL    Optimization level (0, 1, 2, 3, s)
    -D, --define MACRO      Define preprocessor macro
    -I, --include PATH      Add include path
    -L, --libpath PATH      Add library path
    -l, --library LIB       Link library
    -o, --output FILE       Output file name
    -f, --fpu               Enable FPU
    -g, --debug             Include debug symbols
    -l, --linker SCRIPT     Linker script
    -h, --help              Show this help message

EXAMPLES:
    # Compile single file for Cortex-M4 with FPU
    $(basename "$0") -t cortex-m4 -f -O2 main.c -o firmware.elf

    # Compile multiple files with debug symbols
    $(basename "$0") -t cortex-m7 -g main.c uart.c gpio.c -l linker.ld

    # Full build with includes and libraries
    $(basename "$0") -t cortex-m4 -f -O2 -I./include -L./lib -lcmsis main.c

EOF
    exit 1
}

TARGET="cortex-m4"
OPTIMIZATION="2"
DEFINES=()
INCLUDES=()
LIBPATHS=()
LIBRARIES=()
OUTPUT="firmware.elf"
USE_FPU=false
DEBUG=false
LINKER_SCRIPT=""
SOURCE_FILES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -O|--optimize)
            OPTIMIZATION="$2"
            shift 2
            ;;
        -D|--define)
            DEFINES+=("$2")
            shift 2
            ;;
        -I|--include)
            INCLUDES+=("$2")
            shift 2
            ;;
        -L|--libpath)
            LIBPATHS+=("$2")
            shift 2
            ;;
        -l|--library)
            LIBRARIES+=("$2")
            shift 2
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        -f|--fpu)
            USE_FPU=true
            shift
            ;;
        -g|--debug)
            DEBUG=true
            shift
            ;;
        --linker)
            LINKER_SCRIPT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Error: Unknown option $1"
            usage
            ;;
        *)
            SOURCE_FILES+=("$1")
            shift
            ;;
    esac
done

if [[ ${#SOURCE_FILES[@]} -eq 0 ]]; then
    echo "Error: No source files specified"
    usage
fi

echo "ARM Cross-Compilation"
echo "Target: $TARGET"
echo "Optimization: -O$OPTIMIZATION"
echo "FPU: $USE_FPU"
echo "Debug: $DEBUG"
echo "Source files: ${SOURCE_FILES[*]}"

python3 - "${TARGET}" "${OPTIMIZATION}" "${USE_FPU}" "${DEBUG}" "${OUTPUT}" "${LINKER_SCRIPT}" "${SOURCE_FILES[@]}" <<'PYTHON_EOF'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from tools.adapters.embedded.gcc_arm_adapter import (
    GCCArmAdapter,
    ARMArchitecture,
    OptimizationLevel,
    BuildConfig
)

def main():
    target_str = sys.argv[1]
    opt_level = sys.argv[2]
    use_fpu = sys.argv[3] == "True"
    debug = sys.argv[4] == "True"
    output_file = sys.argv[5]
    linker_script = sys.argv[6] if sys.argv[6] else None
    source_files = [Path(f) for f in sys.argv[7:]]

    target_map = {
        "cortex-m0": ARMArchitecture.CORTEX_M0,
        "cortex-m3": ARMArchitecture.CORTEX_M3,
        "cortex-m4": ARMArchitecture.CORTEX_M4,
        "cortex-m7": ARMArchitecture.CORTEX_M7,
        "cortex-r5": ARMArchitecture.CORTEX_R5,
    }

    opt_map = {
        "0": OptimizationLevel.O0,
        "1": OptimizationLevel.O1,
        "2": OptimizationLevel.O2,
        "3": OptimizationLevel.O3,
        "s": OptimizationLevel.Os,
    }

    target = target_map.get(target_str, ARMArchitecture.CORTEX_M4)
    optimization = opt_map.get(opt_level, OptimizationLevel.O2)

    config = BuildConfig(
        target=target,
        optimization=optimization,
        use_fpu=use_fpu,
        debug_symbols=debug,
        warnings_as_errors=False,
        defines=["USE_HAL_DRIVER"],
        include_paths=[Path("./include")],
        library_paths=[Path("./lib")],
        libraries=[]
    )

    adapter = GCCArmAdapter()

    print(f"\nBuilding {len(source_files)} source files...")

    linker_path = Path(linker_script) if linker_script else None
    result = adapter.build_project(
        source_files,
        config,
        linker_path,
        Path("./build")
    )

    if result.success:
        print(f"\n✓ Build successful: {result.output_file}")

        if result.warnings:
            print(f"\nWarnings ({len(result.warnings)}):")
            for warning in result.warnings[:5]:
                print(f"  {warning}")

        sizes = adapter.analyze_size(result.output_file)
        total = sum(sizes.values())
        print(f"\nMemory usage:")
        print(f"  .text: {sizes.get('.text', 0)} bytes")
        print(f"  .data: {sizes.get('.data', 0)} bytes")
        print(f"  .bss:  {sizes.get('.bss', 0)} bytes")
        print(f"  Total: {total} bytes")

        bin_file = adapter.generate_binary(result.output_file, "bin")
        hex_file = adapter.generate_binary(result.output_file, "hex")
        print(f"\nGenerated binaries:")
        print(f"  {bin_file}")
        print(f"  {hex_file}")

        sys.exit(0)
    else:
        print(f"\n✗ Build failed")
        if result.errors:
            print("\nErrors:")
            for error in result.errors[:10]:
                print(f"  {error}")
        sys.exit(1)

if __name__ == "__main__":
    main()
PYTHON_EOF

echo "✓ Compilation completed"
