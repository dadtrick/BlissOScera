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
