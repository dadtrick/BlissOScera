# Developed with ChatGPT / Codex AI assistance, directed by dadtrick.
# See AI_DISCLOSURE.md at the repository root for attribution and test limits.
"""Exercise release preflight without building archives or requiring Batocera."""

import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]


class ReleaseMetadataTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="bliss-release-metadata-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "tools").mkdir()
        self.builder = self.root / "tools/build-release.sh"
        shutil.copyfile(SOURCE / "tools/build-release.sh", self.builder)
        (self.root / "VERSION").write_text("0.2.1\n", encoding="utf-8")
        self.manifest = self.root / "BUILD-MANIFEST.json"
        self.manifest.write_text(json.dumps({"version": "0.2.1"}), encoding="utf-8")

        # A metadata error must stop the normal build before test discovery.
        (self.root / "tests").mkdir()
        self.marker = self.root / "tests-started"
        (self.root / "tests/test_must_not_run.py").write_text(
            "from pathlib import Path\n"
            "Path(__file__).resolve().parents[1].joinpath('tests-started').touch()\n",
            encoding="utf-8",
        )

    def run_builder(self, *arguments):
        return subprocess.run(
            ["bash", str(self.builder), *arguments],
            capture_output=True,
            text=True,
            timeout=5,
        )

    def assert_no_build_started(self):
        self.assertFalse(self.marker.exists())
        self.assertFalse((self.root / "dist").exists())
        self.assertFalse((self.root / "releases").exists())

    def test_matching_metadata_can_be_checked_without_building(self):
        result = self.run_builder("--check-metadata")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Release metadata agrees: 0.2.1", result.stdout)
        self.assert_no_build_started()

    def test_manifest_version_mismatch_stops_normal_build_before_tests(self):
        self.manifest.write_text(json.dumps({"version": "0.2.0"}), encoding="utf-8")
        result = self.run_builder()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("VERSION and BUILD-MANIFEST.json version do not agree", result.stderr)
        self.assert_no_build_started()

    def test_invalid_version_stops_normal_build_before_tests(self):
        (self.root / "VERSION").write_text("development\n", encoding="utf-8")
        result = self.run_builder()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("VERSION must have the form X.Y.Z", result.stderr)
        self.assert_no_build_started()

    def test_malformed_manifest_stops_normal_build_before_tests(self):
        self.manifest.write_text("{invalid json", encoding="utf-8")
        result = self.run_builder()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Invalid release metadata", result.stderr)
        self.assert_no_build_started()

    def test_missing_manifest_stops_normal_build_before_tests(self):
        self.manifest.unlink()
        result = self.run_builder()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("BUILD-MANIFEST.json", result.stderr)
        self.assert_no_build_started()


if __name__ == "__main__":
    unittest.main()
