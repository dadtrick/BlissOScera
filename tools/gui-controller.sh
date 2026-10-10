#!/bin/bash
# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
exec python3 "$ROOT/tools/gui-controller.py" "$ROOT"
