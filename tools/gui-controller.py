#!/usr/bin/env python3
import ctypes
import glob
import os
import re
import select
import signal
import struct
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '/userdata/system/blissoscera'
CONFIG = os.path.join(ROOT, 'config', 'settings.conf')

EV_KEY = 0x01
EV_ABS = 0x03
ABS_HAT0X = 0x10
ABS_HAT0Y = 0x11

BTN_SOUTH = 0x130
BTN_EAST = 0x131
BTN_WEST = 0x134
BTN_TL = 0x136
BTN_TR = 0x137
BTN_SELECT = 0x13A
BTN_START = 0x13B

EVENT_FORMAT = 'llHHi'
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)
running = True


def stop_handler(signum, frame):
    global running
    running = False


signal.signal(signal.SIGTERM, stop_handler)
signal.signal(signal.SIGINT, stop_handler)


def find_controller():
    if os.path.isfile(CONFIG):
        with open(CONFIG, encoding='utf-8', errors='replace') as f:
            text = f.read()
        match = re.search(
            r'^CONTROLLER_EVDEV=["\']?([^"\']*)["\']?$',
            text,
            re.MULTILINE,
        )
        if match and match.group(1).strip():
            return match.group(1).strip()

    choices = sorted(glob.glob('/dev/input/by-id/*-event-joystick'))
    return choices[0] if choices else None


device = find_controller()
if not device or not os.path.exists(device):
    print('No usable controller event device was found.', flush=True)
    sys.exit(0)

os.environ.setdefault('DISPLAY', ':0.0')

try:
    x11 = ctypes.CDLL('libX11.so.6')
    xtst = ctypes.CDLL('libXtst.so.6')
except OSError as e:
    print(f'Could not load X11/XTest: {e}', flush=True)
    sys.exit(1)

x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
x11.XOpenDisplay.restype = ctypes.c_void_p
x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
x11.XStringToKeysym.argtypes = [ctypes.c_char_p]
x11.XStringToKeysym.restype = ctypes.c_ulong
x11.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
x11.XKeysymToKeycode.restype = ctypes.c_ubyte
x11.XFlush.argtypes = [ctypes.c_void_p]

xtst.XTestFakeKeyEvent.argtypes = [
    ctypes.c_void_p,
    ctypes.c_uint,
    ctypes.c_int,
    ctypes.c_ulong,
]
xtst.XTestFakeKeyEvent.restype = ctypes.c_int

display = x11.XOpenDisplay(os.environ['DISPLAY'].encode())
if not display:
    print(f"Could not open X display {os.environ['DISPLAY']}.", flush=True)
    sys.exit(1)


def get_keycode(name):
    keysym = x11.XStringToKeysym(name.encode())
    code = x11.XKeysymToKeycode(display, keysym)
    if not code:
        raise RuntimeError(f'No X keycode for {name}')
    return code


KEYS = {
    'up': get_keycode('Up'),
    'down': get_keycode('Down'),
    'left': get_keycode('Left'),
    'right': get_keycode('Right'),
    'enter': get_keycode('Return'),
    'escape': get_keycode('Escape'),
    'space': get_keycode('space'),
    'pageup': get_keycode('Prior'),
    'pagedown': get_keycode('Next'),
}

BUTTON_MAP = {
    BTN_SOUTH: 'enter',
    BTN_EAST: 'escape',
    BTN_WEST: 'space',
    BTN_TL: 'pageup',
    BTN_TR: 'pagedown',
    BTN_START: 'enter',
    BTN_SELECT: 'escape',
}

pressed = set()
hat_x = 0
hat_y = 0


def send_key(name, down):
    xtst.XTestFakeKeyEvent(display, KEYS[name], 1 if down else 0, 0)
    x11.XFlush(display)
    if down:
        pressed.add(name)
    else:
        pressed.discard(name)


def update_hat(axis, value):
    global hat_x, hat_y

    if axis == ABS_HAT0X:
        old = hat_x
        if old == -1:
            send_key('left', False)
        elif old == 1:
            send_key('right', False)
        hat_x = value
        if value == -1:
            send_key('left', True)
        elif value == 1:
            send_key('right', True)

    elif axis == ABS_HAT0Y:
        old = hat_y
        if old == -1:
            send_key('up', False)
        elif old == 1:
            send_key('down', False)
        hat_y = value
        if value == -1:
            send_key('up', True)
        elif value == 1:
            send_key('down', True)


print('Starting BlissOScera GUI controller support.', flush=True)
print(f'Controller: {device}', flush=True)

fd = None
try:
    fd = os.open(device, os.O_RDONLY | os.O_NONBLOCK)
    while running:
        readable, _, _ = select.select([fd], [], [], 0.25)
        if not readable:
            continue
        try:
            data = os.read(fd, EVENT_SIZE)
        except BlockingIOError:
            continue
        if len(data) != EVENT_SIZE:
            continue

        _, _, ev_type, code, value = struct.unpack(EVENT_FORMAT, data)

        if ev_type == EV_ABS and code in (ABS_HAT0X, ABS_HAT0Y):
            update_hat(code, value)
        elif ev_type == EV_KEY:
            key = BUTTON_MAP.get(code)
            if key is not None:
                if value == 1:
                    send_key(key, True)
                elif value == 0:
                    send_key(key, False)
finally:
    for name in list(pressed):
        try:
            send_key(name, False)
        except Exception:
            pass
    if fd is not None:
        try:
            os.close(fd)
        except OSError:
            pass
    x11.XFlush(display)
    x11.XCloseDisplay(display)
