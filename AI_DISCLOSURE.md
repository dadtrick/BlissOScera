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

The repository documents development testing on one Batocera 43.1 x86_64 system with QEMU 9.1.0. Those are reported development results; this attribution review did not independently run the VM or verify the documented storage migration. The source package excludes the runtime and guest disk, and setup is not yet reproducible for a fresh installation. No automated CI workflow is present at the time of this review.

## Future changes

When adding AI-generated work, keep this disclosure visible and identify material
AI assistance in pull requests. Record checks actually performed and distinguish
reported results from independently reproduced tests. Avoid claiming untested
hardware support, complete correctness, or authorship of upstream components.
