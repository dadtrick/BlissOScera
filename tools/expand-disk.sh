#!/bin/bash
# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
DISK="$ROOT/disks/bliss-system.qcow2"
QEMU_IMG="$ROOT/bin/qemu-img"
LOOP_TOOL="$ROOT/tools/loop.py"
TMP="$ROOT/tmp"

export LD_LIBRARY_PATH="$ROOT/lib"

TARGET_GIB="${1:-}"
RAW="$TMP/bliss-expand.raw"
NEW="$TMP/bliss-expanded.qcow2"
VERIFY_MNT="/mnt/blissoscera-expand-verify"
LOOP=""

mkdir -p "$TMP" "$VERIFY_MNT"

fail() {
echo "ERROR: $*" >&2
exit 1
}

cleanup() {
grep -qs " $VERIFY_MNT " /proc/mounts &&
    umount "$VERIFY_MNT" >/dev/null 2>&1 || true

if [ -n "$LOOP" ]; then
    "$LOOP_TOOL" detach "$LOOP" >/dev/null 2>&1 || true
fi
}

trap cleanup EXIT INT TERM

if pgrep -af qemu-system-x86_64 2>/dev/null | grep -F "$DISK" >/dev/null; then
fail "BlissOScera must be shut down before expanding the disk."
fi

[ -x "$QEMU_IMG" ] || fail "qemu-img not found."
[ -x "$LOOP_TOOL" ] || fail "Loop helper not found."
[ -f "$DISK" ] || fail "BlissOS disk not found."

case "$TARGET_GIB" in
''|*[!0-9]*) fail "Usage: expand-disk.sh TARGET_GIB" ;;
esac

CURRENT_BYTES="$(
"$QEMU_IMG" info --output=json "$DISK" |
python3 -c 'import json,sys; print(int(json.load(sys.stdin)["virtual-size"]))'
)" || fail "Could not read current disk size."

CURRENT_GIB=$((CURRENT_BYTES / 1024 / 1024 / 1024))

[ "$TARGET_GIB" -gt "$CURRENT_GIB" ] ||
fail "Target must be larger than ${CURRENT_GIB} GiB."

[ "$TARGET_GIB" -le 2048 ] ||
fail "Maximum supported expansion is 2048 GiB."

echo "Current virtual size: ${CURRENT_GIB} GiB"
echo "Target virtual size:  ${TARGET_GIB} GiB"

echo "[1/10] Checking original qcow2..."
"$QEMU_IMG" check "$DISK" || fail "Original qcow2 failed validation."

ALLOC_KB="$(du -k "$DISK" | awk '{print $1}')"
FREE_KB="$(df -Pk /userdata | awk 'NR==2 {print $4}')"
NEEDED_KB=$((ALLOC_KB * 3 + 2097152))
[ "$FREE_KB" -ge "$NEEDED_KB" ] ||
fail "Not enough free host storage for a safe conversion."

rm -f "$RAW" "$NEW"

echo "[2/10] Creating sparse raw working copy..."
"$QEMU_IMG" convert -f qcow2 -O raw -S 4k "$DISK" "$RAW" ||
fail "Could not create raw working copy."

echo "[3/10] Growing working disk..."
truncate -s "${TARGET_GIB}G" "$RAW" || fail "truncate failed."

echo "[4/10] Attaching working image..."
LOOP="$("$LOOP_TOOL" attach "$RAW")" || fail "Loop attach failed."
sleep 2

P2="$(
lsblk -nrpo NAME,FSTYPE,LABEL "$LOOP" |
awk '$2=="ext4" && tolower($3)=="blissos" {print $1; exit}'
)"
[ -n "$P2" ] || fail "Could not locate the BlissOS ext4 partition."

PARTNUM="${P2#${LOOP}p}"
PINFO="$(sgdisk -i "$PARTNUM" "$LOOP")" ||
fail "Could not read GPT partition information."

PART_START="$(printf '%s\n' "$PINFO" | awk -F': ' '/First sector/ {print $2}' | awk '{print $1}')"
PART_GUID="$(printf '%s\n' "$PINFO" | awk -F': ' '/Partition unique GUID/ {print $2}')"
PART_TYPE="$(printf '%s\n' "$PINFO" | awk -F': ' '/Partition GUID code/ {print $2}' | awk '{print $1}')"

[ -n "$PART_START" ] || fail "Missing partition start."
[ -n "$PART_GUID" ] || fail "Missing partition GUID."
[ -n "$PART_TYPE" ] || fail "Missing partition type."

echo "[5/10] Extending GPT and BlissOS partition..."
sgdisk -e "$LOOP" || fail "Could not relocate backup GPT."
sgdisk \
-d "$PARTNUM" \
-n "$PARTNUM":"$PART_START":0 \
-t "$PARTNUM":"$PART_TYPE" \
-u "$PARTNUM":"$PART_GUID" \
"$LOOP" || fail "Could not extend BlissOS partition."

"$LOOP_TOOL" detach "$LOOP" || fail "Could not detach working image."
LOOP=""

echo "[6/10] Reloading expanded partition table..."
LOOP="$("$LOOP_TOOL" attach "$RAW")" || fail "Could not reattach image."
sleep 2
P2="${LOOP}p${PARTNUM}"
[ -b "$P2" ] || fail "Expanded partition did not appear."

echo "[7/10] Checking filesystem..."
set +e
e2fsck -f -y "$P2"
RC=$?
set -e
[ "$RC" -le 1 ] || fail "e2fsck failed with code $RC."

echo "[8/10] Expanding ext4 filesystem..."
resize2fs -p "$P2" || fail "resize2fs failed."

set +e
e2fsck -f -n "$P2"
RC=$?
set -e
[ "$RC" -le 1 ] || fail "Final filesystem verification failed."

echo "[9/10] Verifying BlissOS filesystem..."
mount -t ext4 -o ro "$P2" "$VERIFY_MNT" || fail "Verification mount failed."
[ -d "$VERIFY_MNT/boot" ] || fail "Expanded filesystem does not contain /boot."
find "$VERIFY_MNT" -maxdepth 1 -type d -name 'android-*' | grep -q . ||
fail "Android installation directory not found."
umount "$VERIFY_MNT" || fail "Verification unmount failed."

"$LOOP_TOOL" detach "$LOOP" || fail "Could not detach expanded image."
LOOP=""

echo "[10/10] Creating verified qcow2 replacement..."
"$QEMU_IMG" convert -f raw -O qcow2 -S 4k "$RAW" "$NEW" ||
fail "Could not create expanded qcow2."
"$QEMU_IMG" check "$NEW" || fail "Expanded qcow2 failed validation."

NEW_BYTES="$(
"$QEMU_IMG" info --output=json "$NEW" |
python3 -c 'import json,sys; print(int(json.load(sys.stdin)["virtual-size"]))'
)"
EXPECTED_BYTES=$((TARGET_GIB * 1024 * 1024 * 1024))
[ "$NEW_BYTES" -eq "$EXPECTED_BYTES" ] ||
fail "Expanded qcow2 has the wrong virtual size."

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/disks/bliss-system.qcow2.backup-$STAMP"
OLD_UID="$(stat -c '%u' "$DISK")"
OLD_GID="$(stat -c '%g' "$DISK")"
OLD_MODE="$(stat -c '%a' "$DISK")"

mv "$DISK" "$BACKUP" || fail "Could not preserve the original disk."

if ! mv "$NEW" "$DISK"; then
mv "$BACKUP" "$DISK" >/dev/null 2>&1 || true
fail "Install failed; original active disk was restored."
fi

chown "$OLD_UID:$OLD_GID" "$DISK"
chmod "$OLD_MODE" "$DISK"
sync
rm -f "$RAW"

echo
echo "SUCCESS: BlissOScera disk expanded to ${TARGET_GIB} GiB."
echo "Previous disk: $BACKUP"

