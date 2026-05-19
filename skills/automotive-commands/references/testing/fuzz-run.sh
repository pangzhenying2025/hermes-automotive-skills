#!/usr/bin/env bash
set -euo pipefail
# Run fuzzing campaign
FUZZER=${1:-afl-fuzz}
echo "Starting fuzzing with $FUZZER"
echo "Input corpus: ./seeds/"
echo "Run: afl-fuzz -i seeds/ -o findings/ ./target"
