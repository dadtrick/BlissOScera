# BlissOScera 0.2.0: dadtrick's system test

## Evidence

Diagnostics collected on October 9, 2026 at 9:52 PM MDT confirm:

- BlissOScera 0.2.0 on Batocera 43.1 x86_64.
- QEMU 9.1.0 and ADB 37.0.1 installed.
- VM configuration: 8,192 MiB RAM, 4 virtual CPUs, audio and controller enabled.
- A GameSir joystick event-device symlink was present.
- A 128 GiB qcow2 virtual disk using approximately 5.5 GiB on the host.
- `qemu-img info` reported `corrupt: false`; this is not a full filesystem integrity test.

## Hands-on results reported by dadtrick

- Controller use worked.
- A YouTube video played without issues, including audio.

The controller's exact scope (Android, the Configuration Manager, or both) was
not specified. These are user-reported functional results, separate from the
configuration captured by diagnostics.

## Limits and follow-up

The diagnostic snapshot reported `VM Status: STOPPED` and the local ADB endpoint
as `offline`. Its recent QEMU log contained startup messages without a recorded
error, but did not prove a running Android session. ADB connectivity and guest
Android version remain unverified by this report. A stopped VM is consistent
with collecting diagnostics after the functional test; the shutdown sequence
was not recorded.

This snapshot does not verify disk expansion, backup/restore, all GUI actions,
GPU acceleration, other controllers, or other systems. The previously documented
storage migration remains a reported development result.

Raw diagnostics are not committed here; this summary omits device identifiers
and unrelated host storage details. Collect another report while Android is
running if ADB and guest details need validation.

## Follow-up live guest diagnostics

A second report collected October 9, 2026 at 9:59 PM MDT confirmed:

- The local ADB endpoint was in `device` state, and guest shell commands succeeded.
- Android reported version **13**.
- The guest `/data` query returned approximately **125 GiB total**, **5.1 GiB used**, and **114 GiB available** (mounted at `/data/user/0`).
- The guest exposed an **Intel HDA** audio device.

These results supersede the earlier snapshot's offline ADB limitation and provide
evidence of a responding Android guest. They support the reported playback test
without proving all networking, audio, or controller scenarios.

The report still printed `VM Status: STOPPED`, contradicting the successful ADB
queries. The diagnostics process check compares command-line text with an exact
disk path; use of the `/bliss` shortcut versus `/blissoscera` installation path
is a possible explanation, not yet confirmed by process arguments. Do not treat
that status label as reliable until investigated. The report confirms the guest's
current filesystem capacity, not the earlier disk-growth procedure.

## Confirmed path mismatch and regression fix

The supplied QEMU process arguments used `/userdata/system/blissoscera/disks/bliss-system.qcow2`, while diagnostics invoked through the `/bliss` shortcut compared `/userdata/system/bliss/disks/bliss-system.qcow2`. This confirms why that report incorrectly labeled the running VM as stopped. The process arguments also show KVM, virtio-vga-gl, PipeWire audio, and VirtIO controller passthrough configured; this confirms launch options, not their performance.

Source scripts now resolve their installation root with `pwd -P` so both entry paths use the same physical disk path. The launcher checks for an existing VM before removing the QMP endpoint. Four isolated regression tests reproduced the old failures and pass with the fix: running/stopped diagnostics through both paths, duplicate-launch refusal with endpoint preservation, and live-disk restore/expansion refusal through the shortcut. A GitHub CI workflow runs these tests and syntax checks. This fix still needs installation and a fresh diagnostic check on dadtrick's Batocera system; earlier runtime files and ZIPs are unchanged.
