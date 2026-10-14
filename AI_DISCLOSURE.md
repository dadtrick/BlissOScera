# AI development and attribution

BlissOScera was developed by dadtrick working with ChatGPT / Codex (OpenAI).
This disclosure records the maintainer's account of how the project was made;
it does not provide a line-by-line history of every earlier commit.

- **dadtrick:** original need and idea, project direction, time invested, and hands-on testing.
- **ChatGPT / Codex:** AI assistance with software design, generated code, debugging, tests, and documentation.

ChatGPT / Codex is an AI tool, not a human developer or a project maintainer.
dadtrick maintains the repository and decides what to publish. AI-generated
code can contain mistakes; attribution is separate from evidence that a feature
works. No OpenAI endorsement or independent certification is implied.

## Scope

The disclosure applies to this project's integration scripts, supporting tools,
tests, and documentation. It does not claim authorship of upstream software,
external dependencies, or every asset. Preserve third-party credits and license
notices. Existing license terms are unchanged by these credits.

## Validation

The repository documents development testing on one Batocera 43.1 x86_64 system with QEMU 9.1.0. Diagnostics supplied by dadtrick confirm the host/runtime versions, controller device, and 128 GiB virtual disk. dadtrick also reports controller use and YouTube playback with audio. A follow-up report confirmed ADB access to Android 13 and a roughly 125 GiB guest `/data` filesystem. Process arguments subsequently confirmed a shortcut-path mismatch causing the false `STOPPED` label. The source fix passes four isolated regression tests and GitHub CI. dadtrick's October 10 diagnostic recheck reports RUNNING alongside working ADB queries to Android 13 and the physical installation path, consistent with the fix. Live-disk restore/expansion and duplicate-launch refusal were tested in isolation, not on the real guest disk. The reports do not independently prove the storage migration procedure. See [the test report](docs/TESTING-v0.2.0.md). The source package excludes the runtime and guest disk, and setup is not yet reproducible for a fresh installation. GitHub CI now runs the path-alias regression tests, Python compilation, and shell syntax checks.

After the v0.2.1 release and its 16 passing automated tests, dadtrick reported
that the requested hardware shutdown recheck worked. This is a user-reported
functional result; it adds to the earlier diagnostic evidence without claiming
that all GUI actions or other hardware were tested.

## Future changes

When adding AI-generated work, keep this disclosure visible and identify material
AI assistance in pull requests. Record checks actually performed and distinguish
reported results from independently reproduced tests. Avoid claiming untested
hardware support, complete correctness, or authorship of upstream components.
