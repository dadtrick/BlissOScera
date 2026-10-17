#!/bin/bash
# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
set -u

DEST="/userdata/system/blissoscera"
SHORT="/userdata/system/bliss"
PORTS="/userdata/roms/ports"
DISK="$DEST/disks/bliss-system.qcow2"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

# Require a stopped guest before removing its management commands.
[ "$(id -u)" -eq 0 ] || fail "Run this uninstaller as root."

if pgrep -af qemu-system-x86_64 2>/dev/null | grep -F "$DISK" >/dev/null; then
    fail "Shut down BlissOScera before uninstalling."
fi

# Remove the integration files and program files, leaving runtime data intact.
rm -f "$PORTS/BlissOScera.sh"
rm -f "$PORTS/BlissOScera - Configuration.sh"

rm -f "$DEST/start" "$DEST/stop" "$DEST/gui"
rm -f "$DEST/VERSION" "$DEST/README.md" "$DEST/CHANGELOG.md" "$DEST/NOTICE.md"
rm -f "$DEST/LICENSE" "$DEST/AI_DISCLOSURE.md" "$DEST/BUILD-MANIFEST.json"
rm -f "$DEST/CONTRIBUTING.md"
rm -f "$DEST/config/settings.conf.example"
rm -f "$DEST/tools/loop.py" "$DEST/tools/expand-disk.sh" \
    "$DEST/tools/backups.sh" "$DEST/tools/diagnostics.sh" \
    "$DEST/tools/export-source.sh" \
    "$DEST/tools/gui-controller.py" "$DEST/tools/gui-controller.sh"
rm -rf "$DEST/docs" "$DEST/assets"

if [ -L "$SHORT" ] && [ "$(readlink "$SHORT")" = "$DEST" ]; then
    rm -f "$SHORT"
fi

echo "BlissOScera program files removed."
echo
echo "Preserved intentionally:"
echo "  $DEST/disks"
echo "  $DEST/config/settings.conf"
echo "  $DEST/bin"
echo "  $DEST/lib"
echo "  $DEST/share"
echo "  $DEST/firmware"
echo "  $DEST/tools/platform-tools"
echo "  $DEST/logs"
