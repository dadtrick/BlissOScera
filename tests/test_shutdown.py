# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]
GREETING = {"QMP": {"version": {}, "capabilities": []}}

# Inject a fake socket transport into the real stop subprocess. This exercises
# the Bash entry point and QMP protocol without requiring a VM or socket access.
FAKE_SOCKET = r'''
import json
import os

AF_UNIX = 1
SOCK_STREAM = 1
scenario = json.loads(os.environ["TEST_QMP_SCENARIO"])


class Reader:
    def __init__(self, connection):
        self.connection = connection

    def __enter__(self):
        return self

    def __exit__(self, *args):
        pass

    def readline(self):
        buffer = self.connection.buffer
        if not buffer:
            if scenario.get("eof"):
                return ""
            raise TimeoutError("QMP response timed out")
        line, separator, rest = buffer.partition("\n")
        self.connection.buffer = rest
        return line + separator


class socket:
    def __init__(self, *args):
        messages = scenario.get("greeting", [{"QMP": {}}])
        self.buffer = "".join(json.dumps(message) + "\n" for message in messages)

    def __enter__(self):
        return self

    def __exit__(self, *args):
        pass

    def settimeout(self, seconds):
        pass

    def connect(self, path):
        if scenario.get("connect_error"):
            raise ConnectionRefusedError("QMP connection refused")

    def makefile(self, mode, encoding=None):
        return Reader(self)

    def sendall(self, payload):
        request = json.loads(payload)
        with open(os.environ["TEST_QMP_COMMANDS"], "a", encoding="utf-8") as output:
            output.write(json.dumps(request) + "\n")
        default = [{"return": {}, "id": request["id"]}]
        responses = scenario.get("responses", {}).get(request["execute"], default)
        self.buffer += "".join(json.dumps(message) + "\n" for message in responses)
'''


class ShutdownTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bliss-shutdown-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / "blissoscera"
        self.root.mkdir()
        self.alias = self.base / "bliss"
        self.alias.symlink_to(self.root, target_is_directory=True)
        (self.root / "run").mkdir()
        shutil.copyfile(SOURCE / "stop", self.root / "stop")
        (self.root / "stop").chmod(0o755)
        self.endpoint = self.root / "run/bliss-qmp.sock"
        self.endpoint.touch()
        self.commands = self.base / "commands.jsonl"
        self.modules = self.base / "modules"
        self.modules.mkdir()
        (self.modules / "socket.py").write_text(FAKE_SOCKET)
        # Only the socket-file predicate is replaced for this fake endpoint.
        bash_env = self.base / "bash-env"
        bash_env.write_text('''function [ {
    if [[ $# -eq 3 && "$1" == -S ]]; then
        builtin [ -f "$2" ]
    else
        builtin [ "$@"
    fi
}
''')
        self.env = dict(os.environ, BASH_ENV=str(bash_env),
                        PYTHONPATH=str(self.modules), TEST_QMP_COMMANDS=str(self.commands))

    def run_stop(self, scenario=None, root=None):
        self.env["TEST_QMP_SCENARIO"] = json.dumps(scenario or {})
        return subprocess.run(["bash", str((root or self.root) / "stop")],
                              env=self.env, capture_output=True, text=True, timeout=5)

    def sent_commands(self):
        if not self.commands.exists():
            return []
        return [json.loads(line)["execute"] for line in self.commands.read_text().splitlines()]

    def test_shutdown_acknowledged_through_alias_with_interleaved_events(self):
        scenario = {
            "greeting": [GREETING, {"event": "RESUME"}],
            "responses": {
                "qmp_capabilities": [{"event": "RTC_CHANGE"},
                                     {"return": {}, "id": "qmp_capabilities"}],
                "system_powerdown": [{"event": "POWERDOWN"},
                                     {"return": {}, "id": "system_powerdown"}],
            },
        }
        result = self.run_stop(scenario, self.alias)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Shutdown request sent", result.stdout)
        self.assertEqual(self.sent_commands(), ["qmp_capabilities", "system_powerdown"])

    def test_capabilities_error_prevents_powerdown(self):
        result = self.run_stop({"responses": {"qmp_capabilities": [
            {"error": {"desc": "Capabilities denied"}, "id": "qmp_capabilities"},
        ]}})
        self.assertEqual(result.returncode, 1)
        self.assertIn("Capabilities denied", result.stderr)
        self.assertNotIn("Shutdown request sent", result.stdout)
        self.assertEqual(self.sent_commands(), ["qmp_capabilities"])

    def test_powerdown_error_is_reported_as_failure(self):
        result = self.run_stop({"responses": {"system_powerdown": [
            {"error": {"desc": "Powerdown rejected"}, "id": "system_powerdown"},
        ]}})
        self.assertEqual(result.returncode, 1)
        self.assertIn("Powerdown rejected", result.stderr)
        self.assertNotIn("Shutdown request sent", result.stdout)

    def test_unacknowledged_powerdown_fails_on_timeout_or_closed_connection(self):
        for eof in (False, True):
            with self.subTest(eof=eof):
                result = self.run_stop({"responses": {"system_powerdown": []}, "eof": eof})
                self.assertEqual(result.returncode, 1)
                self.assertIn("shutdown failed", result.stderr)
                self.assertNotIn("Shutdown request sent", result.stdout)

    def test_connection_failure_is_reported(self):
        result = self.run_stop({"connect_error": True})
        self.assertEqual(result.returncode, 1)
        self.assertIn("connection refused", result.stderr)
        self.assertEqual(self.sent_commands(), [])

    def test_invalid_greeting_sends_no_commands(self):
        result = self.run_stop({"greeting": [{"event": "POWERDOWN"}]})
        self.assertEqual(result.returncode, 1)
        self.assertIn("greeting is missing", result.stderr)
        self.assertEqual(self.sent_commands(), [])

    def test_missing_socket_is_reported_without_connecting(self):
        self.endpoint.unlink()
        result = self.run_stop()
        self.assertEqual(result.returncode, 1)
        self.assertIn("does not appear to be running", result.stdout)
        self.assertEqual(self.sent_commands(), [])

    def test_gui_reports_failed_shutdown_without_success_dialog(self):
        for directory in ("logs", "config", "bin", "tools", "disks"):
            (self.root / directory).mkdir()
        shutil.copyfile(SOURCE / "gui", self.root / "gui")
        commands = self.base / "mock-bin"
        commands.mkdir()
        pgrep = commands / "pgrep"
        pgrep.write_text('#!/bin/bash\nprintf "123 qemu-system-x86_64 -drive file=%s\\n" "$TEST_QEMU_DISK"\n')
        pgrep.chmod(0o755)
        qemu_img = self.root / "bin/qemu-img"
        qemu_img.write_text('#!/bin/bash\necho \'{"virtual-size": 137438953472}\'\n')
        qemu_img.chmod(0o755)
        dialogs = self.base / "dialogs.jsonl"
        yad = commands / "yad"
        yad.write_text('''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
path = Path(os.environ["TEST_GUI_DIALOGS"])
previous = path.read_text() if path.exists() else ""
with path.open("a") as output:
    output.write(json.dumps(sys.argv[1:]) + "\\n")
if "--title=BlissOScera Configuration Manager" in sys.argv:
    if "--title=BlissOScera Configuration Manager" in previous:
        sys.exit(1)
    print("3")
''')
        yad.chmod(0o755)
        env = dict(self.env, PATH=str(commands) + os.pathsep + os.environ["PATH"],
                   TEST_QEMU_DISK=str(self.root / "disks/bliss-system.qcow2"),
                   TEST_GUI_DIALOGS=str(dialogs),
                   TEST_QMP_SCENARIO=json.dumps({"responses": {"system_powerdown": [
                       {"error": {"desc": "Powerdown rejected"}, "id": "system_powerdown"},
                   ]}}))
        result = subprocess.run(["bash", str(self.root / "gui")], env=env,
                                capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        invocations = [json.loads(line) for line in dialogs.read_text().splitlines()]
        errors = [args for args in invocations if "--error" in args]
        self.assertEqual(len(errors), 1)
        self.assertTrue(any("Powerdown rejected" in arg for arg in errors[0]))
        self.assertNotIn("--text=Shutdown request sent.", dialogs.read_text())


if __name__ == "__main__":
    unittest.main()
