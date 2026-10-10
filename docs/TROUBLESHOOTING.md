# Troubleshooting

## Generate a diagnostic report

From the GUI choose **Diagnostics**, or run:

```bash
/userdata/system/bliss/tools/diagnostics.sh
```

Reports are written under:

```text
/userdata/system/blissoscera/logs/
```

## VM says the qcow2 is locked

Check for an already-running QEMU instance:

```bash
pgrep -af qemu-system-x86_64
```

BlissOScera intentionally prevents a second instance from using the same disk.

## Internet unavailable in Android

The tested guest uses `VIRT_WIFI=1`.

## GUI shows a GTK pixbuf/check-symbolic warning

Batocera 43 may emit a GTK/Adwaita pixbuf warning when YAD opens. During
development this was cosmetic and did not prevent the Configuration Manager
from operating.

## Controller works in Android but not in the GUI

Check:

```bash
cat /userdata/system/bliss/logs/gui-controller.log
```

and confirm the configured event device exists under `/dev/input/by-id/`.

## Disk information while Android is running

BlissOScera uses `qemu-img info -U` for read-only metadata queries while QEMU
has the disk open. Disk mutation is never allowed while the guest is running.
