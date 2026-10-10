#!/bin/bash
ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
exec python3 "$ROOT/tools/gui-controller.py" "$ROOT"
