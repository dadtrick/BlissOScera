# Architecture

```text
EmulationStation / Ports
         |
         +--> /userdata/system/bliss/start
         |          |
         |          +--> QEMU/KVM
         |                 |
         |                 +--> OVMF
         |                 +--> BlissOS qcow2
         |                 +--> VirGL
         |                 +--> user-mode network
         |                 +--> PipeWire/HDA
         |                 +--> virtio-input-host
         |
         +--> /userdata/system/bliss/gui
                    |
                    +--> YAD
                    +--> X11/XTEST controller bridge
                    +--> qemu-img storage metadata
                    +--> expansion / backup tools
                    +--> diagnostics
```

The short `/userdata/system/bliss` path is a symlink to the canonical
`/userdata/system/blissoscera` installation directory.

## Responsibilities

The shell scripts assemble commands and present YAD dialogs. Python handles QMP
JSON messages, Linux loop-device ioctls, and the X11 controller bridge. These
are existing interfaces provided by QEMU and Linux; the project does not define
a replacement VM protocol or image format.

`start`, `stop`, and `gui` remain the public entry points. Ports shortcuts call
those commands. The GUI calls the same storage and diagnostic tools available
from a terminal, so fixes belong in the tool that performs the work.

## Compatibility contracts

| Interface | Keep compatible |
| --- | --- |
| `/userdata/system/blissoscera` | Canonical installation, runtime, and user data. |
| `/userdata/system/bliss` | Existing convenience shortcut and documented commands. |
| `config/settings.conf` | Existing settings keys; source as trusted shell assignments. |
| `disks/bliss-system.qcow2` | Existing QEMU image; user data survives source upgrades. |
| `run/bliss-qmp.sock` | QMP control endpoint used by the shutdown command. |
| Ports launchers | Existing names and targets used by EmulationStation. |

Resolve script roots with `pwd -P`. QEMU process arguments use physical paths;
comparing them with an unresolved shortcut previously caused false STOPPED
reports and missed running-VM checks. Keep this behavior covered by the alias
regression tests.

Configuration is currently sourced by Bash. It is executable trusted local
configuration, not a file format for untrusted imports. Preserve its keys and
quoting until a separately reviewed migration changes that contract.

## Why these implementation choices?

- `/userdata` is Batocera's persistent data location. Generic desktop XDG paths
  would put these files outside the existing Batocera runtime layout.
- Bash is required for arrays, `mapfile`, and process substitution. The scripts
  use a Bash shebang rather than pretending to support POSIX `sh`.
- QEMU arguments use an array so each argument remains intact, including paths
  with spaces. Use standard QEMU options and document host-specific choices in
  [RUNTIME-NOTES.md](RUNTIME-NOTES.md).
- The YAD controller bridge uses X11/XTEST because the tested YAD session is
  desktop-based. This is a platform constraint; Wayland support is not implied.
- The QMP client stays in `stop` so a shutdown command has one deployable entry
  point. Tests execute that entry point and check response handling, including
  failures; `bash -n` alone cannot validate embedded Python.
- The source package excludes QEMU, firmware, and guest disks. Their versions,
  acquisition, and redistribution terms belong to upstream projects. A fresh
  runtime setup is still a documented limitation, not a completed installer.

Use [QEMU's QMP specification](https://www.qemu.org/docs/master/interop/qmp-spec.html)
and [invocation reference](https://www.qemu.org/docs/master/system/invocation.html)
when changing VM control or launch options. Batocera's Ports and desktop entries
remain the normal way to launch the tools.

