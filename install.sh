#!/bin/bash
# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
set -u

SRC="$(cd "$(dirname "$0")" && pwd)"
DEST="/userdata/system/blissoscera"
SHORT="/userdata/system/bliss"
PORTS="/userdata/roms/ports"

fail() {
echo "ERROR: $*" >&2
exit 1
}

[ "$(id -u)" -eq 0 ] || fail "Run this installer as root on Batocera."
[ -d /userdata ] || fail "This does not appear to be a Batocera system."

echo "Installing BlissOScera source components..."

mkdir -p \
"$DEST/config" "$DEST/tools" "$DEST/logs" "$DEST/run" "$DEST/tmp" \
"$DEST/docs" "$DEST/assets" "$PORTS"

for FILE in start stop gui VERSION README.md CHANGELOG.md NOTICE.md; do
[ -f "$SRC/$FILE" ] && cp -f "$SRC/$FILE" "$DEST/$FILE"
done

cp -f "$SRC"/tools/* "$DEST/tools/" 2>/dev/null || true
cp -f "$SRC"/docs/* "$DEST/docs/" 2>/dev/null || true
cp -f "$SRC"/assets/* "$DEST/assets/" 2>/dev/null || true

if [ ! -f "$DEST/config/settings.conf" ]; then
cp "$SRC/config/settings.conf.example" "$DEST/config/settings.conf"
fi
cp -f "$SRC/config/settings.conf.example" "$DEST/config/settings.conf.example"

for FILE in "$SRC"/ports/*.sh; do
[ -f "$FILE" ] || continue
cp -f "$FILE" "$PORTS/$(basename "$FILE")"
done

chmod +x "$DEST/start" "$DEST/stop" "$DEST/gui"
chmod +x "$DEST"/tools/*.sh "$DEST"/tools/*.py 2>/dev/null || true
chmod +x "$PORTS/BlissOScera.sh" "$PORTS/BlissOScera - Configuration.sh" 2>/dev/null || true

if [ -L "$SHORT" ]; then
[ "$(readlink "$SHORT")" = "$DEST" ] || {
    echo "WARNING: $SHORT points somewhere else."
}
elif [ -e "$SHORT" ]; then
echo "WARNING: $SHORT already exists and is not a symlink."
else
ln -s "$DEST" "$SHORT"
fi

echo
echo "Source/UI installation complete."
echo

MISSING=0
for FILE in \
"$DEST/bin/qemu-system-x86_64" \
"$DEST/bin/qemu-img" \
"$DEST/firmware/OVMF_CODE.fd" \
"$DEST/firmware/OVMF_VARS.fd" \
"$DEST/disks/bliss-system.qcow2"
do
if [ ! -e "$FILE" ]; then
    echo "Runtime component not present: $FILE"
    MISSING=1
fi
done

echo
if [ "$MISSING" -eq 0 ]; then
echo "BlissOScera is ready."
echo "Start: /userdata/system/bliss/start"
echo "GUI:   /userdata/system/bliss/gui"
else
echo "The public source package intentionally does not bundle the QEMU/BlissOS runtime."
echo "See docs/INSTALL.md."
fi
