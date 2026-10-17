# GitHub release checklist

Before the first public release:

- [x] Select an open-source license (MIT for original integration code).
- [ ] Verify the project name/branding one final time.
- [ ] Remove any user-specific controller paths.
- [ ] Confirm no qcow2, raw image, firmware or proprietary runtime is tracked.
- [ ] Confirm no local `settings.conf` is tracked.
- [ ] Run shell syntax checks.
- [ ] Run Python compile checks.
- [ ] Test a clean source export.
- [ ] Test install over a prepared runtime.
- [ ] Test uninstall and confirm Android data is preserved.
- [ ] Document the reproducible runtime acquisition/setup process.
- [ ] Verify redistribution terms for any future bundled third-party files.
- [ ] Create release notes from `CHANGELOG.md`.

