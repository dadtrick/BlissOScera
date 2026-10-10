# Storage management

BlissOScera's tested BlissOS layout is:

```text
EFI      512 MiB   FAT
BlissOS  remainder ext4
```

Android mounts the BlissOS ext4 partition directly as `/data`.

The storage expander:

1. refuses to run while the VM is active;
2. validates the current qcow2;
3. creates a sparse raw working copy;
4. expands the raw image;
5. preserves the BlissOS partition's starting sector and GUID;
6. extends the GPT partition;
7. runs `e2fsck`;
8. grows ext4 with `resize2fs`;
9. mounts the result read-only for verification;
10. converts it back to qcow2;
11. validates the new qcow2;
12. preserves the old active qcow2 as a timestamped backup.

Disk shrinking is intentionally unsupported.

The development system was successfully expanded from 64 GiB to 128 GiB,
with Android reporting roughly 125 GiB on `/data`.
