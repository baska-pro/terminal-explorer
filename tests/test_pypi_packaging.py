"""Tests for PyPI distribution of Terminal Explorer."""
import hashlib
from pathlib import Path
import sys
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))
from baska_explorer import __version__, cli, setup


class PackagingTests(unittest.TestCase):
    def test_version_metadata(self):
        version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        self.assertEqual(version, __version__)
        self.assertIn('version = "' + version + '"', (ROOT / "pyproject.toml").read_text(encoding="utf-8"))
        self.assertIn('VERSION="' + version + '"', (ROOT / "explorer.sh").read_text(encoding="utf-8"))

    def test_embedded_shell_matches_source(self):
        source = (ROOT / "explorer.sh").read_bytes()
        bundled = (ROOT / "src/baska_explorer/explorer.sh").read_bytes()
        self.assertEqual(hashlib.sha256(source).digest(), hashlib.sha256(bundled).digest())

    def test_non_linux_uses_native_backend(self):
        with mock.patch.object(cli.sys, "platform", "win32"), \
             mock.patch.object(cli.native, "main", return_value=0) as native_main, \
             mock.patch.object(cli.subprocess, "call") as run:
            self.assertEqual(cli.main(["--version"]), 0)
            native_main.assert_called_once_with(["--version"])
            run.assert_not_called()

    def test_missing_bash_uses_portable_interface(self):
        with mock.patch.object(cli.sys, "platform", "linux"), \
             mock.patch.object(cli.shutil, "which", return_value=None), \
             mock.patch.object(cli.native, "main", return_value=0) as portable:
            self.assertEqual(cli.main([]), 0)
            portable.assert_called_once_with([])

    def test_missing_fzf_uses_portable_interface(self):
        def available(command):
            return "/usr/bin/bash" if command == "bash" else None
        with mock.patch.object(cli.sys, "platform", "linux"), \
             mock.patch.object(cli.shutil, "which", side_effect=available), \
             mock.patch.object(cli.native, "main", return_value=0) as portable:
            self.assertEqual(cli.main(["/tmp"]), 0)
            portable.assert_called_once_with(["/tmp"])

    def test_explicit_native_mode(self):
        with mock.patch.object(cli.native, "main", return_value=0) as portable:
            self.assertEqual(cli.main(["--native", "--help"]), 0)
            portable.assert_called_once_with(["--help"])

    def test_launch_forwards_arguments_without_network(self):
        with mock.patch.object(cli.sys, "platform", "linux"), mock.patch.object(cli.shutil, "which", return_value="/usr/bin/bash"), mock.patch.object(cli.subprocess, "call", return_value=17) as run:
            self.assertEqual(cli.main(["--help"]), 17)
            args = run.call_args.args[0]
            self.assertEqual(args[0], "/usr/bin/bash")
            self.assertEqual(Path(args[1]).name, "explorer.sh")
            self.assertEqual(args[2:], ["--help"])

    def test_setup_requires_explicit_confirmation(self):
        with mock.patch.object(setup, "_missing_packages", return_value=["fzf"]), \
             mock.patch.object(setup, "_package_manager", return_value="apt-get"), \
             mock.patch.object(setup.os, "geteuid", return_value=0, create=True), \
             mock.patch("builtins.input", return_value="n"), \
             mock.patch.object(setup.subprocess, "call") as run:
            self.assertEqual(setup.install_dependencies(), 1)
            run.assert_not_called()

    def test_setup_installs_only_missing_packages_after_yes(self):
        with mock.patch.object(setup, "_missing_packages", side_effect=[["fzf"], []]), \
             mock.patch.object(setup, "_package_manager", return_value="apt-get"), \
             mock.patch.object(setup.os, "geteuid", return_value=0, create=True), \
             mock.patch.object(setup.subprocess, "call", return_value=0) as run:
            self.assertEqual(setup.install_dependencies(yes=True), 0)
            self.assertEqual(run.call_args_list, [
                mock.call(["apt-get", "update"]),
                mock.call(["apt-get", "install", "-y", "fzf"]),
            ])

    def test_cli_setup_does_not_launch_bash(self):
        with mock.patch.object(cli.sys, "platform", "linux"), \
             mock.patch.object(cli.setup, "install_dependencies", return_value=0) as install, \
             mock.patch.object(cli.subprocess, "call") as run:
            self.assertEqual(cli.main(["--setup"]), 0)
            install.assert_called_once_with(yes=False)
            run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
