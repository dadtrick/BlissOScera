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
