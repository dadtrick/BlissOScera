# BlissOScera

**BlissOS for Batocera**

BlissOScera is a managed BlissOS Android environment for Batocera built around
QEMU/KVM. It turns a working BlissOS VM into a controller-friendly Batocera
experience with launch, configuration, storage management, backup/restore,
diagnostics, ADB access, audio, networking and controller passthrough.

## AI development disclosure

This project was developed with **ChatGPT / Codex, OpenAI's AI tools**, for
software design, code generation, debugging, and documentation.
**dadtrick** supplied the original need and idea, directed the project, invested
the time, and performed hands-on testing. The code is presented openly as
AI-developed work; the repository owner's name does not mean every line was
written by hand.

See [AI_DISCLOSURE.md](AI_DISCLOSURE.md) for attribution and validation limits.

## Current development release

**Version:** 0.2.1

Reported development baseline (one system; not independently reproduced in this review):

- Batocera 43.1 x86_64
- QEMU 9.1.0 portable runtime
- BlissOS x86_64 installation
- KVM acceleration
- VirGL / `virtio-vga-gl`
- PipeWire audio
- VirtWifi networking
- VirtIO input-host controller passthrough

### Hands-on test evidence

Diagnostics supplied by dadtrick confirm the v0.2.0 installation on Batocera
43.1 / QEMU 9.1.0, a detected GameSir controller, and a 128 GiB virtual disk.
dadtrick reports successful controller use and YouTube video playback with audio.
The October 10 recheck reports **VM Status: RUNNING**, working ADB access to
**Android 13**, a roughly **125 GiB** guest `/data` filesystem, and an Intel HDA
audio device. Diagnostics now reports the physical `/blissoscera` disk path,
consistent with the fix for the earlier false `STOPPED` label. Four isolated
regression tests and GitHub CI also pass. Existing installations using the old
scripts need updating.

See [the test report](docs/TESTING-v0.2.0.md) for evidence and limits.

The v0.2.1 patch fixes shutdown requests and GUI error reporting, tightens installer checks, and includes the AI disclosure and regression tests in source exports. Its automated tests pass. Following the release, dadtrick reported that the requested shutdown recheck worked on their existing Batocera guest. No new shutdown log or installed commit identifier was supplied for that recheck.

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

This repository is public, but an open-source license has not yet been selected.
Public visibility alone does not grant open-source reuse rights. See
[docs/LICENSE-TODO.md](docs/LICENSE-TODO.md).

