# BlissOScera

**BlissOS for Batocera**

BlissOScera is a managed BlissOS Android environment for Batocera built around
QEMU/KVM. It turns a working BlissOS VM into a controller-friendly Batocera
experience with launch, configuration, storage management, backup/restore,
diagnostics, ADB access, audio, networking and controller passthrough.

## Current development release

**Version:** 0.2.0

Tested development baseline:

- Batocera 43.1 x86_64
- QEMU 9.1.0 portable runtime
- BlissOS x86_64 installation
- KVM acceleration
- VirGL / `virtio-vga-gl`
- PipeWire audio
- VirtWifi networking
- VirtIO input-host controller passthrough

## Quick launch

Once installed:

```bash
/userdata/system/bliss/start
```

Configuration Manager:

```bash
/userdata/system/bliss/gui
```

Graceful shutdown:

```bash
/userdata/system/bliss/stop
```

## Features

- BlissOS boot through QEMU/KVM
- VirGL accelerated graphics
- persistent Android networking via `VIRT_WIFI=1`
- PipeWire + Intel HDA audio
- controller passthrough to Android
- controller navigation inside the Configuration Manager
- configurable RAM, CPU, fullscreen, ADB and controller settings
- QMP graceful shutdown
- safe qcow2 expansion with ext4 `/data` growth
- timestamped disk backup and restore
- diagnostics report
- EmulationStation Ports launchers
- short `/userdata/system/bliss` convenience path

## Important: source package vs runtime

This repository/package intentionally does **not** include:

- BlissOS disk images
- QEMU binaries or libraries
- OVMF firmware
- Android Platform Tools / ADB
- local `settings.conf`
- user backups or logs

Those are runtime or user-specific components and should not be committed to
GitHub. See [docs/INSTALL.md](docs/INSTALL.md).

## Project layout

```text
BlissOScera/
├── start
├── stop
├── gui
├── install.sh
├── uninstall.sh
├── config/
├── tools/
├── ports/
├── assets/
└── docs/
```

## Branding

The approved BlissOScera visual suite is included in the v0.2.0 distribution package. Binary artwork can also be added to the repository under `assets/`.

**Tagline:** `PLAY MORE. MANAGE LESS.`

## Development status

BlissOScera is currently a development project built and validated on one
Batocera system. The source package is being prepared for broader testing;
the portable-runtime acquisition/install workflow still needs to be made
reproducible before a general-public release.

## License

A public open-source license has not yet been selected. See
`docs/LICENSE-TODO.md` before publishing the repository.
