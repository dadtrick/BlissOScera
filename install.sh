#!/bin/bash
# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
set -eu

SRC="$(cd "$(dirname "$0")" && pwd -P)"
DEST="/userdata/system/blissoscera"
SHORT="/userdata/system/bliss"
PORTS="/userdata/roms/ports"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

# Check the host, source package, and installation shortcut before writing files.
[ "$(id -u)" -eq 0 ] || fail "Run this installer as root on Batocera."
[ -d /userdata ] || fail "This does not appear to be a Batocera system."

for FILE in start stop gui VERSION AI_DISCLOSURE.md config/settings.conf.example \
    tools/diagnostics.sh tools/backups.sh tools/expand-disk.sh \
    tools/gui-controller.sh tools/gui-controller.py tools/loop.py; do
    [ -f "$SRC/$FILE" ] || fail "Source package is incomplete: $SRC/$FILE"
done

if [ -L "$SHORT" ]; then
    [ "$(readlink -f "$SHORT")" = "$DEST" ] || fail "$SHORT points to another installation."
elif [ -e "$SHORT" ]; then
    fail "$SHORT exists and is not the expected installation shortcut."
fi

echo "Installing BlissOScera source components..."

# Copy the management scripts without replacing the prepared runtime.
mkdir -p \
    "$DEST/config" "$DEST/tools" "$DEST/logs" "$DEST/run" "$DEST/tmp" \
    "$DEST/docs" "$DEST/assets" "$PORTS"

for FILE in start stop gui VERSION README.md CONTRIBUTING.md AI_DISCLOSURE.md LICENSE CHANGELOG.md NOTICE.md BUILD-MANIFEST.json; do
    [ -f "$SRC/$FILE" ] || continue
    cp -f "$SRC/$FILE" "$DEST/$FILE"
done

for DIR in tools docs assets; do
    for FILE in "$SRC/$DIR"/*; do
        [ -f "$FILE" ] || continue
        cp -f "$FILE" "$DEST/$DIR/"
    done
done

# Keep existing settings; refresh the example for reference.
if [ ! -f "$DEST/config/settings.conf" ]; then
    cp "$SRC/config/settings.conf.example" "$DEST/config/settings.conf"
fi
cp -f "$SRC/config/settings.conf.example" "$DEST/config/settings.conf.example"

# Register the EmulationStation launchers and the validated shortcut.
for FILE in "$SRC"/ports/*.sh; do
    [ -f "$FILE" ] || continue
    cp -f "$FILE" "$PORTS/$(basename "$FILE")"
done

chmod +x "$DEST/start" "$DEST/stop" "$DEST/gui"
chmod +x "$DEST"/tools/*.sh "$DEST"/tools/*.py 2>/dev/null || true
chmod +x "$PORTS/BlissOScera.sh" "$PORTS/BlissOScera - Configuration.sh" 2>/dev/null || true

if [ ! -L "$SHORT" ]; then
    ln -s "$DEST" "$SHORT"
fi

echo
echo "Source/UI installation complete."
echo

# The source package can be installed before its external runtime is prepared.
MISSING=0
for FILE in \
    "$DEST/bin/qemu-system-x86_64" \
    "$DEST/bin/qemu-img" \
    "$DEST/firmware/OVMF_CODE.fd" \
    "$DEST/firmware/OVMF_VARS.fd" \
    "$DEST/disks/bliss-system.qcow2"; do
    case "$FILE" in
        "$DEST/bin/"*) [ -x "$FILE" ] && continue ;;
        *) [ -f "$FILE" ] && continue ;;
    esac
    echo "Runtime component not present: $FILE"
    MISSING=1
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
