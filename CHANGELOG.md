# Changelog

## 0.2.1

- Fix embedded shutdown Python and require successful QMP acknowledgement.
- GUI reports shutdown failures instead of claiming success.
- Installer fails on incomplete packages or failed copies, rejects conflicting shortcuts, and checks runtime executability.
- Source exports and installs retain AI attribution; exports include tests and the build manifest without private settings/runtime files.
- Add shutdown and packaging regressions and automated source release builds.
- Prior 0.2.0 diagnostics and guest checks were verified on dadtrick's Batocera system; 0.2.1 shutdown is validated with a fake QMP transport, pending a hardware recheck.

## 0.2.0

### Rename and packaging

- Renamed the project from IAB to **BlissOScera**
- Standardized install root at `/userdata/system/blissoscera`
- Added `/userdata/system/bliss` convenience symlink
- Simplified commands to `start`, `gui`, and `stop`
- Added GitHub-safe source packaging
- Added branded artwork suite
- Added installer and conservative uninstaller

### Runtime fix

- Added `-nodefaults` to the QEMU launcher to prevent implicit QEMU devices/consoles from interfering with the explicit VirGL display path.
- Restored the portable QEMU data path with `-L "$ROOT/share/qemu"`.
- Fixes the observed `parallel0` console, `Unable to create OpenGL context >= 3.0`, VirGL initialization failure, and launch-time segmentation fault on the tested Batocera 43.1/NVIDIA system.

### Configuration Manager

- Controller-driven YAD navigation through X11/XTEST
- RAM and CPU settings
- audio, ADB, fullscreen and controller options
- storage manager
- backup/restore manager
- diagnostics
- About screen

### Storage

- Verified qcow2 expansion
- GPT growth
- ext4 `/data` growth
- original disk automatically preserved as backup
- verified 64 GiB -> 128 GiB development migration

## 0.1.0

Initial working Android-on-Batocera prototype.

