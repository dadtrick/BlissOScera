# Contributing

BlissOScera helps people manage an existing BlissOS VM from Batocera. Keep the
management layer small and let QEMU, Android, and Batocera own their respective jobs.

## Find the code

- `start`: QEMU arguments and launch checks.
- `stop`: QMP shutdown request and acknowledgement handling.
- `gui`: YAD dialogs that call the same command-line tools.
- `tools/diagnostics.sh`, `backups.sh`, `expand-disk.sh`: system reports and storage actions.
- `tools/loop.py`: Linux loop-device operations; `gui-controller.py`: the X11 input bridge.
- `install.sh`, `uninstall.sh`, `tools/export-source.sh`, `tools/build-release.sh`:
  deployment and source packaging.
- `tests/`: isolated path, QMP, GUI, installer, and packaging regressions.

Read [ARCHITECTURE.md](docs/ARCHITECTURE.md) and [RUNTIME-NOTES.md](docs/RUNTIME-NOTES.md)
before changing runtime paths or QEMU arguments.

## Code conventions

Use four-space indentation, descriptive function names, and short, direct
control flow. Python follows PEP 8 naming. Bash scripts have a Bash shebang:
arrays, `mapfile`, and process substitution are intentional Bash dependencies.
Quote path expansions and use arrays when building command arguments.

Keep structured JSON/QMP and Linux ioctl operations in Python. Use shell for
command orchestration and YAD. Explain unusual QEMU flags or platform constraints
where they are used, and keep the longer rationale in the architecture notes.
Do not turn each small operation into a framework or introduce runtime packages
only for style checks. `.editorconfig` and `.gitattributes` define whitespace and
LF line endings without adding a runtime dependency.

## Run checks

On Linux with Python 3.12 and Bash:

```bash
python3 -m unittest discover -s tests -v
python3 -m py_compile tools/*.py tests/*.py
for file in start stop gui *.sh ports/*.sh tools/*.sh; do
    bash -n "$file" || exit
done
```

These tests use temporary directories and fake QMP/YAD transports. They do not
boot Android or alter a real guest disk. A shell syntax check alone cannot check
Python embedded in a heredoc; the shutdown regressions execute that entry point.

To build the source ZIP, also install `zip` and standard checksum utilities:

```bash
bash tools/build-release.sh --check-metadata
bash tools/build-release.sh
```

The builder checks version agreement, runs the checks, and writes artifacts to
`dist/`. The source export excludes guest disks, third-party runtime files,
local settings, logs, and backups. Its tests and contributor documentation remain
in the exported source tree.

## Propose a change

Explain the user problem, the change, and what was actually checked. Keep pull
requests focused and preserve the stable entry points described in the architecture
notes. Add regression coverage for behavior changes; reuse existing checks for
formatting and documentation edits. Test storage changes with disposable copies.

Disclose material AI assistance and review generated code. Report hardware,
runtime versions, and limitations separately from automated results. See
[AI_DISCLOSURE.md](AI_DISCLOSURE.md).

The original integration code uses the [MIT license](LICENSE). Keep upstream
credits and notices intact. Third-party runtimes, operating-system images,
firmware, and assets retain their own terms; see [LICENSING.md](docs/LICENSING.md).
