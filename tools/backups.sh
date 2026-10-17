#!/bin/bash
# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
DISK_DIR="$ROOT/disks"
DISK="$DISK_DIR/bliss-system.qcow2"
QEMU_IMG="$ROOT/bin/qemu-img"
WORK_DIR="$ROOT/tmp"

export LD_LIBRARY_PATH="$ROOT/lib"
mkdir -p "$WORK_DIR"

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

is_running() {
    pgrep -af qemu-system-x86_64 2>/dev/null |
        grep -F "$DISK" >/dev/null 2>&1
}

resolve_backup() {
    local filename
    filename="$(basename "$1")"
    case "$filename" in
        bliss-system.qcow2.backup-*|bliss-system.qcow2.pre-restore-*) ;;
        *) fail "Invalid BlissOScera backup filename." ;;
    esac
    printf '%s/%s\n' "$DISK_DIR" "$filename"
}

list_backups() {
    shopt -s nullglob
    local files=(
        "$DISK_DIR"/bliss-system.qcow2.backup-*
        "$DISK_DIR"/bliss-system.qcow2.pre-restore-*
    )
    local file host_size virtual_bytes virtual_size

    for file in "${files[@]}"; do
        [ -f "$file" ] || continue
        host_size="$(du -h "$file" | awk '{print $1}')"
        virtual_bytes="$(
            "$QEMU_IMG" info -U --output=json "$file" 2>/dev/null |
                python3 -c '
import json
import sys

try:
    print(int(json.load(sys.stdin)["virtual-size"]))
except Exception:
    print(0)
'
        )"
        if [ "$virtual_bytes" -gt 0 ]; then
            virtual_size="$((virtual_bytes / 1024 / 1024 / 1024)) GiB"
        else
            virtual_size="Unknown"
        fi
        printf '%s|%s|%s\n' "$file" "$host_size" "$virtual_size"
    done
}

restore_backup() {
    local backup_path timestamp restore_image previous_disk
    local old_uid old_gid old_mode
    backup_path="$(resolve_backup "$1")"
    [ -f "$backup_path" ] || fail "Backup does not exist."
    is_running && fail "Shut down BlissOScera before restoring a disk."

    "$QEMU_IMG" check "$backup_path" || fail "Selected backup failed validation."

    timestamp="$(date +%Y%m%d-%H%M%S)"
    restore_image="$WORK_DIR/bliss-restore-$timestamp.qcow2"
    previous_disk="$DISK_DIR/bliss-system.qcow2.pre-restore-$timestamp"

    old_uid="$(stat -c '%u' "$DISK")"
    old_gid="$(stat -c '%g' "$DISK")"
    old_mode="$(stat -c '%a' "$DISK")"

    rm -f "$restore_image"
    "$QEMU_IMG" convert -f qcow2 -O qcow2 -S 4k "$backup_path" "$restore_image" ||
        fail "Could not prepare restored disk."
    "$QEMU_IMG" check "$restore_image" || fail "Restored qcow2 failed verification."

    # Preserve the active disk before replacing it with the verified working copy.
    mv "$DISK" "$previous_disk" || fail "Could not preserve active disk."
    if ! mv "$restore_image" "$DISK"; then
        mv "$previous_disk" "$DISK" >/dev/null 2>&1 || true
        fail "Restore failed; the previous active disk was put back."
    fi

    chown "$old_uid:$old_gid" "$DISK"
    chmod "$old_mode" "$DISK"
    sync

    echo "Restore completed successfully."
    echo "Restored from: $backup_path"
    echo "Previous active disk preserved as: $previous_disk"
}

delete_backup() {
    local backup_path
    backup_path="$(resolve_backup "$1")"
    [ -f "$backup_path" ] || fail "Backup does not exist."
    rm -f "$backup_path" || fail "Could not delete backup."
    echo "Deleted: $backup_path"
}

case "${1:-}" in
    list)
        list_backups
        ;;
    restore)
        [ $# -ge 2 ] || fail "Usage: backups.sh restore BACKUP"
        restore_backup "$2"
        ;;
    delete)
        [ $# -ge 2 ] || fail "Usage: backups.sh delete BACKUP"
        delete_backup "$2"
        ;;
    *)
        echo "Usage:"
        echo "  backups.sh list"
        echo "  backups.sh restore BACKUP"
        echo "  backups.sh delete BACKUP"
        exit 1
        ;;
esac
