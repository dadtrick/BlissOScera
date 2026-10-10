#!/bin/bash
# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DISKDIR="$ROOT/disks"
DISK="$DISKDIR/bliss-system.qcow2"
QEMU_IMG="$ROOT/bin/qemu-img"
TMPDIR="$ROOT/tmp"

export LD_LIBRARY_PATH="$ROOT/lib"
mkdir -p "$TMPDIR"

fail() {
echo "ERROR: $*" >&2
exit 1
}

is_running() {
pgrep -af qemu-system-x86_64 2>/dev/null |
    grep -F "$DISK" >/dev/null 2>&1
}

resolve_backup() {
local base
base="$(basename "$1")"
case "$base" in
    bliss-system.qcow2.backup-*|bliss-system.qcow2.pre-restore-*) ;;
    *) fail "Invalid BlissOScera backup filename." ;;
esac
printf '%s/%s\n' "$DISKDIR" "$base"
}

list_backups() {
shopt -s nullglob
local files=(
    "$DISKDIR"/bliss-system.qcow2.backup-*
    "$DISKDIR"/bliss-system.qcow2.pre-restore-*
)

for file in "${files[@]}"; do
    [ -f "$file" ] || continue
    hostsize="$(du -h "$file" | awk '{print $1}')"
    bytes="$(
        "$QEMU_IMG" info -U --output=json "$file" 2>/dev/null |
        python3 -c '
import json,sys
try: print(int(json.load(sys.stdin)["virtual-size"]))
except Exception: print(0)
'
    )"
    if [ "$bytes" -gt 0 ]; then
        virtual="$((bytes / 1024 / 1024 / 1024)) GiB"
    else
        virtual="Unknown"
    fi
    printf '%s|%s|%s\n' "$file" "$hostsize" "$virtual"
done
}

restore_backup() {
local source
source="$(resolve_backup "$1")"
[ -f "$source" ] || fail "Backup does not exist."
is_running && fail "Shut down BlissOScera before restoring a disk."

"$QEMU_IMG" check "$source" || fail "Selected backup failed validation."

stamp="$(date +%Y%m%d-%H%M%S)"
new="$TMPDIR/bliss-restore-$stamp.qcow2"
previous="$DISKDIR/bliss-system.qcow2.pre-restore-$stamp"

old_uid="$(stat -c '%u' "$DISK")"
old_gid="$(stat -c '%g' "$DISK")"
old_mode="$(stat -c '%a' "$DISK")"

rm -f "$new"
"$QEMU_IMG" convert -f qcow2 -O qcow2 -S 4k "$source" "$new" ||
    fail "Could not prepare restored disk."
"$QEMU_IMG" check "$new" || fail "Restored qcow2 failed verification."

mv "$DISK" "$previous" || fail "Could not preserve active disk."
if ! mv "$new" "$DISK"; then
    mv "$previous" "$DISK" >/dev/null 2>&1 || true
    fail "Restore failed; the previous active disk was put back."
fi

chown "$old_uid:$old_gid" "$DISK"
chmod "$old_mode" "$DISK"
sync

echo "Restore completed successfully."
echo "Restored from: $source"
echo "Previous active disk preserved as: $previous"
}

delete_backup() {
local source
source="$(resolve_backup "$1")"
[ -f "$source" ] || fail "Backup does not exist."
rm -f "$source" || fail "Could not delete backup."
echo "Deleted: $source"
}

case "${1:-}" in
list) list_backups ;;
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
