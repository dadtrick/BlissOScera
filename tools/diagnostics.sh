#!/bin/bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DISK="$ROOT/disks/bliss-system.qcow2"
CONFIG="$ROOT/config/settings.conf"
QEMU="$ROOT/bin/qemu-system-x86_64"
QEMU_IMG="$ROOT/bin/qemu-img"
ADB="$ROOT/tools/platform-tools/adb"
LOG="$ROOT/logs/bliss-qemu.log"

export LD_LIBRARY_PATH="$ROOT/lib"

ADB_PORT=4444
[ -f "$CONFIG" ] && . "$CONFIG"

STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/logs/diagnostics-$STAMP.txt"
mkdir -p "$ROOT/logs"

{
echo "============================================================"
echo "BLISSOSCERA DIAGNOSTIC REPORT"
echo "============================================================"
echo
echo "Timestamp:"
date
echo
echo "BlissOScera version:"
cat "$ROOT/VERSION" 2>/dev/null || echo "Unknown"
echo
echo "Kernel:"
uname -a
echo
echo "Batocera:"
cat /usr/share/batocera/batocera.version 2>/dev/null || echo "Unknown"
echo
echo "CPU / MEMORY"
echo "------------------------------------------------------------"
nproc 2>/dev/null || true
grep -E 'MemTotal|MemAvailable' /proc/meminfo
echo
echo "CONFIGURATION"
echo "------------------------------------------------------------"
cat "$CONFIG" 2>/dev/null || echo "Configuration file missing."
echo
echo "QEMU"
echo "------------------------------------------------------------"
"$QEMU" --version 2>&1 | head -3
if pgrep -af qemu-system-x86_64 | grep -F "$DISK" >/dev/null 2>&1; then
    echo "VM Status: RUNNING"
else
    echo "VM Status: STOPPED"
fi
echo
echo "VIRTUAL DISK"
echo "------------------------------------------------------------"
"$QEMU_IMG" info -U "$DISK" 2>&1
du -h "$DISK" 2>/dev/null
df -h /userdata
echo
echo "CONTROLLER"
echo "------------------------------------------------------------"
echo "${CONTROLLER_EVDEV:-Auto-detect}"
[ -n "${CONTROLLER_EVDEV:-}" ] && ls -l "$CONTROLLER_EVDEV" 2>/dev/null || true
echo
echo "ADB"
echo "------------------------------------------------------------"
if [ -x "$ADB" ]; then
    "$ADB" version | head -3
    if command -v ss >/dev/null 2>&1 &&
       ss -lnt 2>/dev/null | grep -q ":$ADB_PORT"; then
        "$ADB" connect "127.0.0.1:$ADB_PORT" >/dev/null 2>&1 || true
        "$ADB" devices
        if "$ADB" devices | grep -q "127.0.0.1:$ADB_PORT.*device"; then
            echo
            "$ADB" -s "127.0.0.1:$ADB_PORT" shell getprop ro.build.version.release
            "$ADB" -s "127.0.0.1:$ADB_PORT" shell df -h /data
            "$ADB" -s "127.0.0.1:$ADB_PORT" shell cat /proc/asound/cards 2>/dev/null
        fi
    fi
else
    echo "ADB binary missing."
fi
echo
echo "RECENT QEMU LOG"
echo "------------------------------------------------------------"
tail -80 "$LOG" 2>/dev/null || echo "No QEMU log available."
echo
echo "============================================================"
} > "$REPORT" 2>&1

echo "$REPORT"
