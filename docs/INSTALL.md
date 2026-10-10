# Installation

## Development status

The source package installs BlissOScera's management layer, but it does not
yet bootstrap the entire QEMU/BlissOS runtime from scratch.

## Install the source/UI layer

Copy or extract the source package on Batocera and run:

```bash
chmod +x install.sh
./install.sh
```

The installer uses:

```text
/userdata/system/blissoscera
```

and creates the short convenience path:

```text
/userdata/system/bliss
```

## Expected runtime layout

```text
/userdata/system/blissoscera/
├── bin/
│   ├── qemu-system-x86_64
│   └── qemu-img
├── lib/
├── share/qemu/
├── firmware/
│   ├── OVMF_CODE.fd
│   └── OVMF_VARS.fd
├── disks/
│   └── bliss-system.qcow2
└── tools/platform-tools/
    └── adb
```

The tested portable QEMU development runtime is QEMU 9.1.0.

## BlissOS networking

The tested guest installation uses the kernel parameter:

```text
VIRT_WIFI=1
```

so the QEMU virtio network adapter appears to Android as VirtWifi.

## Launch

```bash
/userdata/system/bliss/start
```

Configuration:

```bash
/userdata/system/bliss/gui
```

## Next packaging milestone

Before general release, the project should gain a reproducible runtime setup
flow that acquires compatible QEMU/OVMF components from appropriate upstream
sources and guides the user through creating/installing the BlissOS disk.
