#!/bin/bash
# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
VERSION="$(cat "$ROOT/VERSION" 2>/dev/null || echo dev)"
OUTROOT="$ROOT/releases"
OUT="$OUTROOT/BlissOScera-v${VERSION}-source"

mkdir -p "$OUTROOT"
rm -rf "$OUT"
mkdir -p "$OUT"

copy_tree_item() {
local item="$1"
[ -e "$ROOT/$item" ] || return 0
cp -a "$ROOT/$item" "$OUT/"
}

for item in \
start stop gui VERSION README.md AI_DISCLOSURE.md CHANGELOG.md NOTICE.md BUILD-MANIFEST.json RELEASE_NOTES.md \
config tools ports docs assets tests install.sh uninstall.sh \
.gitignore .github
do
copy_tree_item "$item"
done

rm -f "$OUT/config/settings.conf"
rm -rf "$OUT/tools/platform-tools" "$OUT/releases"
find "$OUT" -type d -name __pycache__ -prune -exec rm -rf {} +

BAD=0
for NAME in '*.qcow2' '*.raw' '*.iso' 'settings.conf' \
        'adb' 'qemu-system-x86_64' 'qemu-img'; do
FOUND="$(find "$OUT" -type f -name "$NAME" -print)"
if [ -n "$FOUND" ]; then
    echo "$FOUND"
    BAD=1
fi
done

[ "$BAD" -eq 0 ] || {
echo "ERROR: unsafe runtime/local files found in source tree." >&2
exit 1
}

echo "$OUT"


