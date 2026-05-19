#!/usr/bin/env bash
#
# Tool Installation Command
#
# Installs opensource automotive development tools with automatic
# dependency resolution.
#
# Usage:
#   tool-install [options] <tool_name>
#
# Options:
#   --force                Force reinstallation
#   --no-deps              Skip dependency installation
#   --no-sudo              Don't use sudo (user installation)
#   --prefix PATH          Installation prefix (default: /usr/local)
#   --dry-run              Show what would be installed
#   --report FILE          Save installation report
#   --verbose              Show detailed installation steps
#
# Examples:
#   tool-install cantools                    # Install cantools
#   tool-install --force python-can          # Reinstall python-can
#   tool-install --no-sudo qemu              # User installation
#   tool-install --dry-run arctic-core       # Preview installation
#   tool-install --report report.json googletest

set -euo pipefail

# Default configuration
TOOL_NAME=""
FORCE=false
INSTALL_DEPS=true
USE_SUDO=true
PREFIX=""
DRY_RUN=false
REPORT=""
VERBOSE=false

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --no-deps)
            INSTALL_DEPS=false
            shift
            ;;
        --no-sudo)
            USE_SUDO=false
            shift
            ;;
        --prefix)
            PREFIX="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --report)
            REPORT="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            grep '^#' "$0" | grep -v '#!/usr/bin/env' | sed 's/^# //'
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            if [[ -z "$TOOL_NAME" ]]; then
                TOOL_NAME="$1"
            else
                echo "Error: Multiple tool names specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate tool name
if [[ -z "$TOOL_NAME" ]]; then
    echo "Error: Tool name required"
    echo "Use --help for usage information"
    exit 1
fi

# Set report file
if [[ -z "$REPORT" ]]; then
    REPORT="/tmp/install_${TOOL_NAME}_$(date +%Y%m%d_%H%M%S).json"
fi

# Create Python installer script
TMP_SCRIPT=$(mktemp)
cat > "$TMP_SCRIPT" <<'PYTHON_EOF'
import sys
import os
import json
import logging

sys.path.insert(0, os.environ.get('PROJECT_ROOT'))

from tools.installers.opensource_installer import OpensourceInstaller
from tools.installers.dependency_resolver import DependencyResolver

# Configure logging
log_level = logging.DEBUG if os.environ.get('VERBOSE') == 'true' else logging.INFO
logging.basicConfig(level=log_level, format='%(levelname)s: %(message)s')

def main():
    tool_name = os.environ.get('TOOL_NAME')
    force = os.environ.get('FORCE') == 'true'
    use_sudo = os.environ.get('USE_SUDO') == 'true'
    install_deps = os.environ.get('INSTALL_DEPS') == 'true'
    prefix = os.environ.get('PREFIX', None)
    dry_run = os.environ.get('DRY_RUN') == 'true'
    report_file = os.environ.get('REPORT')

    print(f"Installing {tool_name}...")

    # Create installer
    installer = OpensourceInstaller(install_prefix=prefix, sudo=use_sudo)

    # Check if tool is supported
    if tool_name not in installer.INSTALL_SPECS:
        print(f"Error: Unknown tool '{tool_name}'")
        print(f"\nSupported tools:")
        for name in sorted(installer.INSTALL_SPECS.keys()):
            print(f"  - {name}")
        sys.exit(1)

    # Dry run: show what would be installed
    if dry_run:
        spec = installer.INSTALL_SPECS[tool_name]
        print(f"\nDry run for {tool_name}:")
        print(f"  Installation method: {installer._get_installation_method(spec)}")

        if install_deps and spec.get('dependencies'):
            print(f"  Dependencies: {', '.join(spec['dependencies'])}")

        if 'package_managers' in spec:
            pm = installer.package_manager
            if pm and pm in spec['package_managers']:
                pm_spec = spec['package_managers'][pm]
                package = pm_spec.get('package', tool_name)
                print(f"  Package manager: {pm}")
                print(f"  Package name: {package}")

        if 'git' in spec:
            git_spec = spec['git']
            print(f"  Git repository: {git_spec['url']}")

        print("\nNo installation performed (dry run)")
        return

    # Install tool
    result = installer.install_tool(tool_name, force=force)

    # Print result
    if result.success:
        print(f"\n✓ Successfully installed {tool_name}")
        if result.version:
            print(f"  Version: {result.version}")
        if result.install_path:
            print(f"  Path: {result.install_path}")
        print(f"  Method: {result.method}")
        print(f"  Duration: {result.duration_seconds:.1f}s")
    else:
        print(f"\n✗ Failed to install {tool_name}")
        print(f"  Error: {result.error_message}")
        sys.exit(1)

    # Export report
    results = {tool_name: result}
    installer.export_report(results, report_file)
    print(f"\n✓ Installation report: {report_file}")

if __name__ == '__main__':
    main()
PYTHON_EOF

# Export environment variables
export PROJECT_ROOT
export TOOL_NAME
export FORCE
export USE_SUDO
export INSTALL_DEPS
export PREFIX
export DRY_RUN
export REPORT
export VERBOSE

# Run installer
echo ""
echo "=== Opensource Tool Installer ==="
echo ""

python3 "$TMP_SCRIPT"
EXIT_CODE=$?

# Cleanup
rm -f "$TMP_SCRIPT"

# Display report summary if successful
if [[ $EXIT_CODE -eq 0 ]] && [[ -f "$REPORT" ]]; then
    echo ""
    echo "Installation complete!"
fi

exit $EXIT_CODE
