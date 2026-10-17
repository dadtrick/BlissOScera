#!/usr/bin/env python3
# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
"""Attach loop devices and request partition scanning through Linux ioctls."""

import fcntl
import os
import struct
import sys

LOOP_SET_FD = 0x4C00
LOOP_CLR_FD = 0x4C01
LOOP_SET_STATUS64 = 0x4C04
LOOP_CTL_GET_FREE = 0x4C82
LO_FLAGS_PARTSCAN = 8
# Match Linux's struct loop_info64 exactly; these field sizes are part of its ABI.
LOOP_INFO_FORMAT = '=QQQQQIIII64s64s32sQQ'


def attach(image, readonly=False):
    image = os.path.abspath(image)
    if not os.path.isfile(image):
        raise SystemExit(f'Image not found: {image}')

    control_fd = os.open('/dev/loop-control', os.O_RDONLY | os.O_CLOEXEC)
    try:
        device_number = fcntl.ioctl(control_fd, LOOP_CTL_GET_FREE, 0)
    finally:
        os.close(control_fd)

    loop_device = f'/dev/loop{device_number}'
    image_flags = os.O_RDONLY if readonly else os.O_RDWR
    image_fd = os.open(image, image_flags | os.O_CLOEXEC)
    loop_fd = os.open(loop_device, os.O_RDWR | os.O_CLOEXEC)

    try:
        fcntl.ioctl(loop_fd, LOOP_SET_FD, image_fd)
        filename = image.encode()[:63].ljust(64, b'\0')
        loop_info = struct.pack(
            LOOP_INFO_FORMAT,
            0, 0, 0, 0, 0,
            device_number, 0, 0, LO_FLAGS_PARTSCAN,
            filename,
            b'\0' * 64,
            b'\0' * 32,
            0, 0,
        )
        fcntl.ioctl(loop_fd, LOOP_SET_STATUS64, loop_info)
    except Exception:
        try:
            fcntl.ioctl(loop_fd, LOOP_CLR_FD, 0)
        except Exception:
            pass
        raise
    finally:
        os.close(loop_fd)
        os.close(image_fd)

    print(loop_device)


def detach(loop_device):
    loop_device = os.path.abspath(loop_device)

    with open('/proc/mounts', 'r', encoding='utf-8') as mounts:
        for line in mounts:
            mounted_device = line.split()[0]
            if mounted_device == loop_device or mounted_device.startswith(loop_device + 'p'):
                raise SystemExit(f'Refusing to detach mounted device: {mounted_device}')

    loop_fd = os.open(loop_device, os.O_RDONLY | os.O_CLOEXEC)
    try:
        fcntl.ioctl(loop_fd, LOOP_CLR_FD, 0)
    finally:
        os.close(loop_fd)

    print(f'Detached {loop_device}')


def main():
    if len(sys.argv) < 3:
        raise SystemExit(
            'Usage:\n'
            '  loop.py attach IMAGE [--read-only]\n'
            '  loop.py detach /dev/loopN'
        )

    if sys.argv[1] == 'attach':
        attach(sys.argv[2], '--read-only' in sys.argv[3:])
    elif sys.argv[1] == 'detach':
        detach(sys.argv[2])
    else:
        raise SystemExit(f'Unknown command: {sys.argv[1]}')


if __name__ == '__main__':
    main()
