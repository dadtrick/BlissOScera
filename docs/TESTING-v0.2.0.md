# BlissOScera: dadtrick's system tests

## Patch shutdown recheck

After the v0.2.1 release, dadtrick reported that the requested shutdown recheck
worked on their existing system. This closes the previously pending hardware
smoke check as a maintainer-reported functional result. No new shutdown log or
installed Git commit identifier was supplied. It does not establish every
shutdown error case or GUI entry point.

## Diagnostic result

The diagnostic report collected **October 10, 2026 at 9:04 AM MDT** reports
**VM Status: RUNNING**, a local ADB endpoint in **device** state, and successful
guest queries returning **Android 13**. The disk path is the physical
`/userdata/system/blissoscera/disks/bliss-system.qcow2` installation path.
This confirms that VM detection and ADB queries worked together in the new
report, consistent with the installed path-resolution fix.

The requested recheck command was:

```bash
bash /userdata/system/bliss/tools/diagnostics.sh
```

The report does not embed the invocation command or installed Git commit, so
it does not independently establish either of those details.

## System evidence

The supplied October 9 and October 10 diagnostics record:

- BlissOScera **0.2.0**, Batocera **43.1 x86_64**, and QEMU **9.1.0**.
- ADB **37.0.1** installed.
- VM configuration: **8,192 MiB RAM**, **4 virtual CPUs**, audio and controller enabled.
- A **GameSir** joystick event-device symlink present.
- A **128 GiB qcow2** virtual disk; the latest host allocation is about **6.1 GiB**.
- Successful guest queries showing approximately **125 GiB total**, **5.4 GiB used**,
  and **113 GiB available** at `/data/user/0`.
- An **Intel HDA** audio device exposed inside Android.
- `qemu-img info` reported `corrupt: false`; this is not a full filesystem integrity test.

## Hands-on results reported by dadtrick

- Controller use worked.
- A YouTube video played without issues, including audio.

The controller's exact scope (Android, the Configuration Manager, or both) was
not specified. These functional observations are separate from the configuration
and guest responses recorded by diagnostics.

## Test history

| Report time (MDT) | VM status label | ADB and guest evidence |
| --- | --- | --- |
| October 9, 2026, 9:52 PM | STOPPED | ADB offline; no guest query results |
| October 9, 2026, 9:59 PM | STOPPED (incorrect) | ADB device; Android 13, guest filesystem, and audio device queried |
| October 10, 2026, 9:04 AM | RUNNING | ADB device; Android 13, guest filesystem, and audio device queried |

The supplied QEMU process arguments used the physical `/blissoscera` disk path,
while the earlier diagnostics compared the `/bliss` shortcut path. That mismatch
explains the earlier false STOPPED label. The process arguments also showed KVM,
virtio-vga-gl, PipeWire audio, and VirtIO controller passthrough configured;
launch options alone do not establish their performance.

The source scripts now resolve their installation root with `pwd -P` so shortcut
and real-path invocations agree. The launcher checks for an existing VM before
removing its QMP endpoint. Four isolated regression tests reproduced the old
failures and pass with the fix: running/stopped diagnostics through both paths,
duplicate-launch refusal with endpoint preservation, and live-disk
restore/expansion refusal through the shortcut. GitHub CI runs these tests,
Python compilation, and shell syntax checks.

The October 10 report is the subsequent hardware recheck of diagnostics.
Duplicate-launch and live-disk guards were covered by isolated tests and were
not exercised on the real guest disk in these reports.

## Scope and limits

These results cover dadtrick's existing installation on one system. They do not
verify a fresh runtime installation, disk expansion, backup/restore, all GUI
actions, every shutdown scenario, GPU performance, or other hardware. The previously
documented storage migration remains a reported development result; the reports
confirm current capacity, not the migration procedure.

The recent QEMU log contains startup messages without recorded errors in the
captured tail. That tail is not evidence that the full log is error-free.

Raw diagnostics are not committed here. This summary omits device identifiers
and unrelated host storage details. Evidence was reviewed from the supplied
reports; the reviewer did not independently boot or operate the VM.
