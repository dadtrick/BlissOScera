#!/bin/bash
# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$ROOT"

if [ "$#" -gt 1 ]; then
    echo "Usage: bash tools/build-release.sh [--check-metadata]" >&2
    exit 2
fi
case "${1:-}" in
    ''|--check-metadata) ;;
    *)
        echo "Usage: bash tools/build-release.sh [--check-metadata]" >&2
        exit 2
        ;;
esac

# Reject inconsistent release names before tests or output directories are made.
VERSION=$(python3 - "$ROOT" <<'PY'
import json
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
try:
    version = (root / "VERSION").read_text(encoding="utf-8").strip()
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise ValueError("VERSION must have the form X.Y.Z")
    manifest = json.loads((root / "BUILD-MANIFEST.json").read_text(encoding="utf-8"))
    if not isinstance(manifest, dict):
        raise ValueError("BUILD-MANIFEST.json must be a JSON object")
    if manifest.get("version") != version:
        raise ValueError("VERSION and BUILD-MANIFEST.json version do not agree")
except (OSError, UnicodeError, ValueError) as exc:
    raise SystemExit(f"ERROR: Invalid release metadata: {exc}")

print(version)
PY
)

if [ "${1:-}" = --check-metadata ]; then
    echo "Release metadata agrees: $VERSION"
    exit 0
fi

NAME="BlissOScera-v${VERSION}-source"

# Validate the source before creating an archive.
python3 -m unittest discover -s tests -v
python3 -m py_compile tools/*.py tests/*.py
for file in start stop gui *.sh ports/*.sh tools/*.sh; do
    bash -n "$file"
done

# Export the source, record its checksums, then package the checked export.
OUT=$(bash tools/export-source.sh)
(
    cd "$OUT"
    find . -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS.txt
    sha256sum -c SHA256SUMS.txt >/dev/null
)

mkdir -p "$ROOT/dist"
rm -f "$ROOT/dist/$NAME.zip" "$ROOT/dist/$NAME.zip.sha256"
(
    cd "$(dirname "$OUT")"
    zip -qr "$ROOT/dist/$NAME.zip" "$NAME"
)
(
    cd "$ROOT/dist"
    sha256sum "$NAME.zip" > "$NAME.zip.sha256"
    sha256sum -c "$NAME.zip.sha256"
)

