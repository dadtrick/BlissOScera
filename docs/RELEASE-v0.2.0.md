# BlissOScera v0.2.0

First public development release of BlissOScera — BlissOS for Batocera.

## Highlights

- QEMU/KVM BlissOS launcher for Batocera
- VirGL accelerated graphics
- PipeWire audio
- VirtWifi networking
- controller passthrough to Android
- controller-driven YAD configuration UI using X11/XTEST
- configurable RAM, CPU, fullscreen, ADB, audio, and controller support
- graceful QMP shutdown
- safe qcow2/ext4 storage expansion
- disk backup and restore
- diagnostics
- EmulationStation Ports integration
- BlissOScera branding and scrape artwork in the distribution package

## Important runtime fix

The validated launcher includes:

```text
-nodefaults
-L "$ROOT/share/qemu"
-machine q35,accel=kvm
-device virtio-vga-gl
-display sdl,gl=on
```

On the validated Batocera 43.1/NVIDIA system, omitting `-nodefaults` caused QEMU to create implicit devices/consoles (including `parallel0`), VirGL failed to initialize, and QEMU terminated.

## Tested baseline

- Batocera 43.1 x86_64
- QEMU 9.1.0 portable runtime
- BlissOS x86_64
- KVM
- NVIDIA OpenGL host
- 128 GiB qcow2 guest disk tested after successful in-place expansion

## Download

Attach:

`BlissOScera-v0.2.0-final.zip`

SHA-256:

```text
7850df61e277f1e6849642d6ebd62cdc02b5de0e311e77250a60b6ab5ee26d92
```

Also attach:

`BlissOScera-v0.2.0-final.zip.sha256`

## Packaging note

The source package intentionally does not include BlissOS disk images, the portable QEMU runtime, OVMF firmware, Android Platform Tools/ADB, local settings, logs, or user backups.

The runtime acquisition/bootstrap process is still a development milestone, so this release is best treated as an early public/tester release rather than a one-click installation for a fresh Batocera system.

## License

No open-source license was selected for this original v0.2.0 package. The current source now includes the [MIT license](../LICENSE) for original integration code; this historical release note does not change the contents of the old archive.

