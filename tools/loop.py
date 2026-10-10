#!/usr/bin/env python3
import fcntl
import os
import struct
import sys

LOOP_SET_FD = 0x4C00
LOOP_CLR_FD = 0x4C01
LOOP_SET_STATUS64 = 0x4C04
LOOP_CTL_GET_FREE = 0x4C82
LO_FLAGS_PARTSCAN = 8
INFO_FMT = '=QQQQQIIII64s64s32sQQ'


def attach(image, readonly=False):
    image = os.path.abspath(image)
    if not os.path.isfile(image):
        raise SystemExit(f'Image not found: {image}')

    ctl = os.open('/dev/loop-control', os.O_RDONLY | os.O_CLOEXEC)
    try:
        number = fcntl.ioctl(ctl, LOOP_CTL_GET_FREE, 0)
    finally:
        os.close(ctl)

    loopdev = f'/dev/loop{number}'
    backing_flags = os.O_RDONLY if readonly else os.O_RDWR
    backing = os.open(image, backing_flags | os.O_CLOEXEC)
    loopfd = os.open(loopdev, os.O_RDWR | os.O_CLOEXEC)

    try:
        fcntl.ioctl(loopfd, LOOP_SET_FD, backing)
        filename = image.encode()[:63].ljust(64, b'\0')
        info = struct.pack(
            INFO_FMT,
            0, 0, 0, 0, 0,
            number, 0, 0, LO_FLAGS_PARTSCAN,
            filename,
            b'\0' * 64,
            b'\0' * 32,
            0, 0,
        )
        fcntl.ioctl(loopfd, LOOP_SET_STATUS64, info)
    except Exception:
        try:
            fcntl.ioctl(loopfd, LOOP_CLR_FD, 0)
        except Exception:
            pass
        raise
    finally:
        os.close(loopfd)
        os.close(backing)

    print(loopdev)


def detach(loopdev):
    loopdev = os.path.abspath(loopdev)

    with open('/proc/mounts', 'r', encoding='utf-8') as f:
        for line in f:
            dev = line.split()[0]
            if dev == loopdev or dev.startswith(loopdev + 'p'):
                raise SystemExit(f'Refusing to detach mounted device: {dev}')

    fd = os.open(loopdev, os.O_RDONLY | os.O_CLOEXEC)
    try:
        fcntl.ioctl(fd, LOOP_CLR_FD, 0)
    finally:
        os.close(fd)

    print(f'Detached {loopdev}')


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
