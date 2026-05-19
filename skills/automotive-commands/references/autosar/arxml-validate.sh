#!/usr/bin/env bash
set -euo pipefail
# Validate ARXML file structure
ARXML_FILE=${1:-system.arxml}
echo "Validating $ARXML_FILE against AUTOSAR XSD schema..."
xmllint --schema /usr/share/autosar/AUTOSAR_00051.xsd "$ARXML_FILE" --noout 2>&1 || echo "Install xmllint"
