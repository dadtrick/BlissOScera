# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1]


class PackagingTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.source = self.root / 'source'
        shutil.copytree(SOURCE, self.source,
                        ignore=shutil.ignore_patterns('releases', 'dist', '__pycache__'))

    def test_export_preserves_disclosure_tests_and_manifest_without_local_data(self):
        (self.source / 'config/settings.conf').write_text('private settings')
        (self.source / 'tests/__pycache__').mkdir()
        (self.source / 'tests/__pycache__/local.pyc').touch()
        platform = self.source / 'tools/platform-tools'
        platform.mkdir()
        (platform / 'adb').touch()
        result = subprocess.run(['bash', str(self.source / 'tools/export-source.sh')],
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        exported = Path(result.stdout.strip())
        for file in ('AI_DISCLOSURE.md', 'BUILD-MANIFEST.json',
                     'tests/test_packaging.py', '.github/workflows/ci.yml'):
            self.assertTrue((exported / file).is_file(), file)
        self.assertFalse((exported / 'config/settings.conf').exists())
        self.assertFalse((exported / 'tools/platform-tools').exists())
        self.assertFalse(list(exported.rglob('__pycache__')))

    def test_install_preserves_runtime_and_settings_and_copies_disclosure(self):
        userdata = self.root / 'userdata'
        destination = userdata / 'system/blissoscera'
        (destination / 'disks').mkdir(parents=True)
        (destination / 'bin').mkdir()
        (destination / 'config').mkdir()
        disk = destination / 'disks/bliss-system.qcow2'
        disk.write_text('existing guest data')
        binary = destination / 'bin/qemu-system-x86_64'
        binary.write_text('existing runtime')
        config = destination / 'config/settings.conf'
        config.write_text('RAM_MB=8192\n')
        installer = self.source / 'install.sh'
        # Map only fixed deployment paths into a temporary sandbox.
        installer.write_text(installer.read_text().replace('/userdata', str(userdata)))
        mockbin = self.root / 'mockbin'
        mockbin.mkdir()
        mockid = mockbin / 'id'
        mockid.write_text('#!/bin/sh\necho 0\n')
        mockid.chmod(0o755)
        env = dict(os.environ, PATH=str(mockbin) + os.pathsep + os.environ['PATH'])
        result = subprocess.run(['bash', str(installer)], env=env,
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(disk.read_text(), 'existing guest data')
        self.assertEqual(binary.read_text(), 'existing runtime')
        self.assertEqual(config.read_text(), 'RAM_MB=8192\n')
        self.assertTrue((destination / 'AI_DISCLOSURE.md').is_file())
        self.assertTrue((destination / 'tools/diagnostics.sh').is_file())
        self.assertTrue((userdata / 'system/bliss').is_symlink())
        # An existing but non-executable QEMU binary must not be called ready.
        self.assertNotIn('BlissOScera is ready.', result.stdout)

    def test_conflicting_shortcut_is_rejected_before_installing(self):
        userdata = self.root / 'userdata'
        (userdata / 'system').mkdir(parents=True)
        foreign = self.root / 'foreign'
        foreign.mkdir()
        (userdata / 'system/bliss').symlink_to(foreign, target_is_directory=True)
        installer = self.source / 'install.sh'
        installer.write_text(installer.read_text().replace('/userdata', str(userdata)))
        mockbin = self.root / 'mockbin'
        mockbin.mkdir()
        command = mockbin / 'id'
        command.write_text('#!/bin/sh\necho 0\n')
        command.chmod(0o755)
        env = dict(os.environ, PATH=str(mockbin) + os.pathsep + os.environ['PATH'])
        result = subprocess.run(['bash', str(installer)], env=env,
                                capture_output=True, text=True, timeout=15)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('another installation', result.stderr)
        self.assertFalse((userdata / 'system/blissoscera').exists())

    def test_failed_copy_does_not_report_successful_install(self):
        userdata = self.root / 'userdata'
        userdata.mkdir()
        installer = self.source / 'install.sh'
        installer.write_text(installer.read_text().replace('/userdata', str(userdata)))
        mockbin = self.root / 'mockbin'
        mockbin.mkdir()
        for name, body in {'id': 'echo 0', 'cp': 'echo simulated-copy-error >&2; exit 1'}.items():
            command = mockbin / name
            command.write_text('#!/bin/sh\n' + body + '\n')
            command.chmod(0o755)
        env = dict(os.environ, PATH=str(mockbin) + os.pathsep + os.environ['PATH'])
        result = subprocess.run(['bash', str(installer)], env=env,
                                capture_output=True, text=True, timeout=15)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('simulated-copy-error', result.stderr)
        self.assertNotIn('installation complete', result.stdout)
        self.assertNotIn('BlissOScera is ready.', result.stdout)


if __name__ == '__main__':
    unittest.main()
