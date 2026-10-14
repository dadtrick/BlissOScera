# BlissOScera v0.2.1 — development source release

- Fix the shutdown script's embedded Python and wait for QMP acknowledgement before reporting success.
- Report shutdown failures in the GUI.
- Fail installation on incomplete source packages or copy errors; reject conflicting shortcut paths and avoid calling non-executable QEMU binaries ready.
- Preserve AI attribution in installed files and source exports; include tests and the build manifest, excluding runtime files and local settings.

Validation: 16 automated tests pass, including alias detection, fake QMP shutdown and errors, and isolated source-export/installer tests. Python and shell checks pass. Prior v0.2.0 hardware reports confirmed VM detection, ADB access to Android 13, and guest disk capacity; dadtrick reported controller use and YouTube playback with audio. Following the v0.2.1 release, dadtrick reported that the requested shutdown recheck worked on their existing system. This is a maintainer-reported functional result; no new shutdown log or installed commit identifier was supplied.

This is a source-only development patch for an existing prepared runtime. It excludes BlissOS disks, QEMU, firmware, and ADB. Fresh runtime setup is not automated, and an open-source license has not yet been selected. No broader hardware support or complete correctness is claimed.

Shut Android down normally, extract the source ZIP, and run `bash install.sh`. Existing guest disk, runtime files, and settings are preserved by the installer; preservation is covered by isolated tests.

Design and generated code: ChatGPT / Codex (OpenAI AI tools). Original idea, direction, time invested, and hands-on testing: dadtrick. See AI_DISCLOSURE.md for scope and limits.
