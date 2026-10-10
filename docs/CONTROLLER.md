# Controller support

BlissOScera has two separate controller paths.

## Android passthrough

QEMU passes the selected Linux event device to Android using:

```text
virtio-input-host
```

`CONTROLLER_EVDEV` can be configured in `config/settings.conf`.

## Configuration Manager navigation

The GUI reads the controller directly and injects keyboard events into X11
through XTEST. This avoids relying on Xorg hot-plugging a virtual keyboard.

Default navigation:

| Controller | GUI action |
|---|---|
| D-pad | Arrow keys |
| A | Enter / Select |
| B | Escape / Back |
| X | Space / Toggle |
| L1 | Page Up |
| R1 | Page Down |
| Start | Enter |
| Select/Back | Escape |

If `CONTROLLER_EVDEV` is blank, the GUI bridge attempts to use the first
`/dev/input/by-id/*-event-joystick` device.
