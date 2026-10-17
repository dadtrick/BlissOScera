#!/bin/bash
# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
DISK="$ROOT/disks/bliss-system.qcow2"
QEMU_IMG="$ROOT/bin/qemu-img"
LOOP_TOOL="$ROOT/tools/loop.py"
WORK_DIR="$ROOT/tmp"

export LD_LIBRARY_PATH="$ROOT/lib"

TARGET_GIB="${1:-}"
RAW_IMAGE="$WORK_DIR/bliss-expand.raw"
EXPANDED_IMAGE="$WORK_DIR/bliss-expanded.qcow2"
VERIFY_MOUNT="/mnt/blissoscera-expand-verify"
LOOP_DEVICE=""

mkdir -p "$WORK_DIR" "$VERIFY_MOUNT"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

cleanup() {
    grep -qs " $VERIFY_MOUNT " /proc/mounts &&
        umount "$VERIFY_MOUNT" >/dev/null 2>&1 || true

    if [ -n "$LOOP_DEVICE" ]; then
        "$LOOP_TOOL" detach "$LOOP_DEVICE" >/dev/null 2>&1 || true
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
        python3 -c 'import json, sys; print(int(json.load(sys.stdin)["virtual-size"]))'
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

ALLOCATED_KB="$(du -k "$DISK" | awk '{print $1}')"
FREE_KB="$(df -Pk /userdata | awk 'NR==2 {print $4}')"
NEEDED_KB=$((ALLOCATED_KB * 3 + 2097152))
[ "$FREE_KB" -ge "$NEEDED_KB" ] ||
    fail "Not enough free host storage for a safe conversion."

rm -f "$RAW_IMAGE" "$EXPANDED_IMAGE"

echo "[2/10] Creating sparse raw working copy..."
# Grow and verify a working copy before replacing the active disk.
"$QEMU_IMG" convert -f qcow2 -O raw -S 4k "$DISK" "$RAW_IMAGE" ||
    fail "Could not create raw working copy."

echo "[3/10] Growing working disk..."
truncate -s "${TARGET_GIB}G" "$RAW_IMAGE" || fail "truncate failed."

echo "[4/10] Attaching working image..."
LOOP_DEVICE="$("$LOOP_TOOL" attach "$RAW_IMAGE")" || fail "Loop attach failed."
# Allow the kernel's partition scan to create device nodes.
sleep 2

BLISS_PARTITION="$(
    lsblk -nrpo NAME,FSTYPE,LABEL "$LOOP_DEVICE" |
        awk '$2=="ext4" && tolower($3)=="blissos" {print $1; exit}'
)"
[ -n "$BLISS_PARTITION" ] || fail "Could not locate the BlissOS ext4 partition."

PARTITION_NUMBER="${BLISS_PARTITION#${LOOP_DEVICE}p}"
PARTITION_INFO="$(sgdisk -i "$PARTITION_NUMBER" "$LOOP_DEVICE")" ||
    fail "Could not read GPT partition information."

PARTITION_START="$(printf '%s\n' "$PARTITION_INFO" | awk -F': ' '/First sector/ {print $2}' | awk '{print $1}')"
PARTITION_GUID="$(printf '%s\n' "$PARTITION_INFO" | awk -F': ' '/Partition unique GUID/ {print $2}')"
PARTITION_TYPE="$(printf '%s\n' "$PARTITION_INFO" | awk -F': ' '/Partition GUID code/ {print $2}' | awk '{print $1}')"

[ -n "$PARTITION_START" ] || fail "Missing partition start."
[ -n "$PARTITION_GUID" ] || fail "Missing partition GUID."
[ -n "$PARTITION_TYPE" ] || fail "Missing partition type."

echo "[5/10] Extending GPT and BlissOS partition..."
sgdisk -e "$LOOP_DEVICE" || fail "Could not relocate backup GPT."
sgdisk \
    -d "$PARTITION_NUMBER" \
    -n "$PARTITION_NUMBER":"$PARTITION_START":0 \
    -t "$PARTITION_NUMBER":"$PARTITION_TYPE" \
    -u "$PARTITION_NUMBER":"$PARTITION_GUID" \
    "$LOOP_DEVICE" || fail "Could not extend BlissOS partition."

"$LOOP_TOOL" detach "$LOOP_DEVICE" || fail "Could not detach working image."
LOOP_DEVICE=""

echo "[6/10] Reloading expanded partition table..."
LOOP_DEVICE="$("$LOOP_TOOL" attach "$RAW_IMAGE")" || fail "Could not reattach image."
sleep 2
BLISS_PARTITION="${LOOP_DEVICE}p${PARTITION_NUMBER}"
[ -b "$BLISS_PARTITION" ] || fail "Expanded partition did not appear."

echo "[7/10] Checking filesystem..."
# e2fsck returns 1 when repairs succeeded; both 0 and 1 are acceptable here.
set +e
e2fsck -f -y "$BLISS_PARTITION"
FSCK_STATUS=$?
set -e
[ "$FSCK_STATUS" -le 1 ] || fail "e2fsck failed with code $FSCK_STATUS."

echo "[8/10] Expanding ext4 filesystem..."
resize2fs -p "$BLISS_PARTITION" || fail "resize2fs failed."

set +e
e2fsck -f -n "$BLISS_PARTITION"
FSCK_STATUS=$?
set -e
[ "$FSCK_STATUS" -le 1 ] || fail "Final filesystem verification failed."

echo "[9/10] Verifying BlissOS filesystem..."
mount -t ext4 -o ro "$BLISS_PARTITION" "$VERIFY_MOUNT" || fail "Verification mount failed."
[ -d "$VERIFY_MOUNT/boot" ] || fail "Expanded filesystem does not contain /boot."
find "$VERIFY_MOUNT" -maxdepth 1 -type d -name 'android-*' | grep -q . ||
    fail "Android installation directory not found."
umount "$VERIFY_MOUNT" || fail "Verification unmount failed."

"$LOOP_TOOL" detach "$LOOP_DEVICE" || fail "Could not detach expanded image."
LOOP_DEVICE=""

echo "[10/10] Creating verified qcow2 replacement..."
"$QEMU_IMG" convert -f raw -O qcow2 -S 4k "$RAW_IMAGE" "$EXPANDED_IMAGE" ||
    fail "Could not create expanded qcow2."
"$QEMU_IMG" check "$EXPANDED_IMAGE" || fail "Expanded qcow2 failed validation."

NEW_BYTES="$(
    "$QEMU_IMG" info --output=json "$EXPANDED_IMAGE" |
        python3 -c 'import json, sys; print(int(json.load(sys.stdin)["virtual-size"]))'
)"
EXPECTED_BYTES=$((TARGET_GIB * 1024 * 1024 * 1024))
[ "$NEW_BYTES" -eq "$EXPECTED_BYTES" ] ||
    fail "Expanded qcow2 has the wrong virtual size."

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DISK="$ROOT/disks/bliss-system.qcow2.backup-$TIMESTAMP"
OLD_UID="$(stat -c '%u' "$DISK")"
OLD_GID="$(stat -c '%g' "$DISK")"
OLD_MODE="$(stat -c '%a' "$DISK")"

mv "$DISK" "$BACKUP_DISK" || fail "Could not preserve the original disk."

if ! mv "$EXPANDED_IMAGE" "$DISK"; then
    mv "$BACKUP_DISK" "$DISK" >/dev/null 2>&1 || true
    fail "Install failed; original active disk was restored."
fi

chown "$OLD_UID:$OLD_GID" "$DISK"
chmod "$OLD_MODE" "$DISK"
sync
rm -f "$RAW_IMAGE"

echo
echo "SUCCESS: BlissOScera disk expanded to ${TARGET_GIB} GiB."
echo "Previous disk: $BACKUP_DISK"
