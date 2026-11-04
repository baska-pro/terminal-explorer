"""Tests for PyPI distribution of Terminal Explorer."""
import hashlib
from pathlib import Path
import sys
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))
from baska_explorer import __version__, cli


class PackagingTests(unittest.TestCase):
    def test_version_metadata(self):
        version = (ROOT / "VERSION").read_text().strip()
        self.assertEqual(version, __version__)
        self.assertIn('version = "' + version + '"', (ROOT / "pyproject.toml").read_text())
        self.assertIn('VERSION="' + version + '"', (ROOT / "explorer.sh").read_text())

    def test_embedded_shell_matches_source(self):
        source = (ROOT / "explorer.sh").read_bytes()
        bundled = (ROOT / "src/baska_explorer/explorer.sh").read_bytes()
        self.assertEqual(hashlib.sha256(source).digest(), hashlib.sha256(bundled).digest())

    def test_non_linux_rejected_without_execution(self):
        with mock.patch.object(cli.sys, "platform", "win32"), mock.patch.object(cli.subprocess, "call") as run:
            self.assertEqual(cli.main(["--version"]), 2)
            run.assert_not_called()

    def test_missing_bash_fails_cleanly(self):
        with mock.patch.object(cli.sys, "platform", "linux"), mock.patch.object(cli.shutil, "which", return_value=None):
            self.assertEqual(cli.main(["--doctor"]), 127)

    def test_launch_forwards_arguments_without_network(self):
        with mock.patch.object(cli.sys, "platform", "linux"), mock.patch.object(cli.shutil, "which", return_value="/usr/bin/bash"), mock.patch.object(cli.subprocess, "call", return_value=17) as run:
            self.assertEqual(cli.main(["--help"]), 17)
            args = run.call_args.args[0]
            self.assertEqual(args[0], "/usr/bin/bash")
            self.assertEqual(Path(args[1]).name, "explorer.sh")
            self.assertEqual(args[2:], ["--help"])


if __name__ == "__main__":
    unittest.main()
