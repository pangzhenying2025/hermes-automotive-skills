#!/usr/bin/env bash
set -euo pipefail
# Generate BSW module configuration template
MODULE=${1:-Can}
echo "BSW Configuration Template - $MODULE"
echo "Generate CanIf_Cfg.h, Can_PBcfg.c..."
