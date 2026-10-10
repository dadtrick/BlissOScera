#!/bin/bash
# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$ROOT"
VERSION=$(cat VERSION)
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 1
NAME="BlissOScera-v${VERSION}-source"
python3 -m unittest discover -s tests -v
python3 -m py_compile tools/*.py tests/*.py
for file in start stop gui *.sh ports/*.sh tools/*.sh; do
    bash -n "$file"
done
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
