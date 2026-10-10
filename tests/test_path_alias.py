# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1]


class PathAliasTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / 'blissoscera'
        self.alias = self.base / 'bliss'
        self.root.mkdir()
        self.alias.symlink_to(self.root, target_is_directory=True)
        for folder in ('tools', 'bin', 'disks', 'firmware', 'run', 'logs', 'config', 'tmp'):
            (self.root / folder).mkdir()
        for script in ('start', 'tools/diagnostics.sh', 'tools/backups.sh', 'tools/expand-disk.sh'):
            shutil.copyfile(SOURCE / script, self.root / script)
        self.disk = self.root / 'disks/bliss-system.qcow2'
        self.disk.write_text('original disk')
        self.backup = self.root / 'disks/bliss-system.qcow2.backup-test'
        self.backup.write_text('backup disk')
        for file in ('OVMF_CODE.fd', 'OVMF_VARS.fd'):
            (self.root / 'firmware' / file).touch()
        self.mockbin = self.base / 'commands'
        self.mockbin.mkdir()
        self.env = dict(os.environ, PATH=str(self.mockbin) + os.pathsep + os.environ['PATH'])
        self.env['TEST_QEMU_DISK'] = str(self.disk)
        self.env['TEST_RUNNING'] = '1'
        self.write_executable(self.mockbin / 'pgrep',
            '#!/bin/bash\n[ "$TEST_RUNNING" = 1 ] || exit 1\nprintf "123 qemu-system-x86_64 -drive file=%s\\n" "$TEST_QEMU_DISK"\n')
        # Never create the expander's real /mnt directory in this isolated test.
        self.write_executable(self.mockbin / 'mkdir', '#!/bin/bash\nexit 0\n')
        self.write_executable(self.root / 'bin/qemu-system-x86_64',
            '#!/bin/bash\n[ "$1" = --version ] && echo "QEMU test runtime" && exit 0\nexit 99\n')
        self.write_executable(self.root / 'bin/qemu-img', '#!/bin/bash\necho "test image"\n')

    def write_executable(self, path, text):
        path.write_text(text)
        path.chmod(0o755)

    def run_script(self, root, script, *args):
        return subprocess.run(['bash', str(root / script), *args], env=self.env,
                              capture_output=True, text=True, timeout=10)

    def test_diagnostics_detects_running_and_stopped_through_both_paths(self):
        for running, expected in (('1', 'RUNNING'), ('0', 'STOPPED')):
            self.env['TEST_RUNNING'] = running
            for root in (self.root, self.alias):
                with self.subTest(running=running, path=root.name):
                    result = self.run_script(root, 'tools/diagnostics.sh')
                    self.assertEqual(result.returncode, 0, result.stderr)
                    report = Path(result.stdout.strip()).read_text()
                    self.assertIn('VM Status: ' + expected, report)

    def test_start_refuses_duplicate_without_removing_qmp_socket_path(self):
        qmp = self.root / 'run/bliss-qmp.sock'
        qmp.write_text('existing endpoint')
        for root in (self.root, self.alias):
            result = self.run_script(root, 'start')
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertIn('already running', result.stderr)
            self.assertEqual(qmp.read_text(), 'existing endpoint')

    def test_restore_refuses_live_disk_through_alias(self):
        result = self.run_script(self.alias, 'tools/backups.sh', 'restore', self.backup.name)
        self.assertEqual(result.returncode, 1)
        self.assertIn('Shut down BlissOScera', result.stderr)
        self.assertEqual(self.disk.read_text(), 'original disk')
        self.assertEqual(self.backup.read_text(), 'backup disk')

    def test_expand_refuses_live_disk_through_alias(self):
        result = self.run_script(self.alias, 'tools/expand-disk.sh', '256')
        self.assertEqual(result.returncode, 1)
        self.assertIn('must be shut down', result.stderr)
        self.assertEqual(self.disk.read_text(), 'original disk')


if __name__ == '__main__':
    unittest.main()
