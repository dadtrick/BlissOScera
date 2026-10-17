# BlissOScera

**BlissOS for Batocera**

BlissOScera adds launch, configuration, and maintenance tools for a BlissOS
virtual machine on Batocera. It uses QEMU/KVM, YAD, and EmulationStation Ports.
The source package requires an existing QEMU runtime and BlissOS installation;
see [installation](docs/INSTALL.md) before downloading it.

## AI development disclosure

Developed by dadtrick using **ChatGPT / Codex (OpenAI AI tools)** for software
design, generated code, debugging, and documentation. dadtrick provided the
idea, requirements, project direction, and hands-on testing.

See [AI_DISCLOSURE.md](AI_DISCLOSURE.md) for attribution and test limits.

## Current development release

**Version:** 0.2.1

Development baseline: one Batocera system with the following components:

- Batocera 43.1 x86_64
- QEMU 9.1.0 portable runtime
- BlissOS x86_64 installation
- KVM acceleration
- VirGL / `virtio-vga-gl`
- PipeWire audio
- VirtWifi networking
- VirtIO input-host controller passthrough

### Tested behavior

On dadtrick's system, diagnostics confirmed a running VM, ADB access to Android
13, and a 128 GiB virtual disk. dadtrick reported working controller input,
YouTube playback with audio, and a successful shutdown recheck after v0.2.1.
See [the test record](docs/TESTING-v0.2.0.md) for versions, evidence, and limits.
These results do not establish support for other systems or every storage action.

## How it fits into Batocera

Ports entries call the same `start` and `gui` commands available in a terminal.
QEMU owns the VM, QMP handles shutdown, and the storage tools use `qemu-img` and
standard Linux filesystem tools. The controller helper adapts input for YAD;
Android receives controller events through QEMU.

The [architecture notes](docs/ARCHITECTURE.md) describe these boundaries and
stable paths. See [CONTRIBUTING.md](CONTRIBUTING.md) to build or change the project.

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
- qcow2 expansion with backups and ext4 `/data` growth
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

The BlissOScera artwork is included under `assets/`.

**Tagline:** `PLAY MORE. MANAGE LESS.`

## Development status

BlissOScera is currently a development project built and validated on one
Batocera system. The source package is being prepared for broader testing;
the portable-runtime acquisition/install workflow still needs to be made
reproducible before a general-public release.

## License

The original BlissOScera integration code is available under the [MIT license](LICENSE).
Third-party runtimes and assets retain their own terms; see
[the licensing notes](docs/LICENSING.md) and [NOTICE.md](NOTICE.md).
