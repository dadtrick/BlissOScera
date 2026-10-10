# Runtime notes

The tested BlissOScera v0.2.0 launcher intentionally uses:

```text
-nodefaults
-L "$ROOT/share/qemu"
-machine q35,accel=kvm
-device virtio-vga-gl
-display sdl,gl=on
```

`-nodefaults` is required on the validated Batocera 43.1 system. Without it,
QEMU created implicit devices/consoles (including a visible `parallel0`
console) and the VirGL renderer failed to initialize, followed by a QEMU
segmentation fault.

The portable QEMU data directory is also supplied explicitly with `-L` so
QEMU uses the runtime's packaged ROM/data directory.

This behavior was validated against the live known-good launcher before the
final v0.2.0 source package was rebuilt.
