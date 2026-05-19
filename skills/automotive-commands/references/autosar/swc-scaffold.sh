#!/usr/bin/env bash
set -euo pipefail
# Scaffold AUTOSAR SWC project structure
SWC_NAME=${1:-MySWC}
mkdir -p "$SWC_NAME"/{include,src,arxml,test}
echo "Created AUTOSAR SWC scaffold: $SWC_NAME"
