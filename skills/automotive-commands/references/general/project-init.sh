#!/usr/bin/env bash
set -euo pipefail
# Initialize new automotive project
PROJECT_NAME=${1:-my-automotive-project}
mkdir -p "$PROJECT_NAME"/{src,include,test,docs,scripts}
echo "Initialized automotive project: $PROJECT_NAME"
