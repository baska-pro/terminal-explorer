"""Safety and basic behavior of the portable file manager."""
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))
from baska_explorer import native


class NativeTests(unittest.TestCase):
    def test_entries_and_preview(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "folder").mkdir()
            (root / "a.txt").write_text("hello\nworld", encoding="utf-8")
            (root / ".hidden").write_text("secret", encoding="utf-8")
            self.assertEqual([p.name for p in native.entries(root)], ["folder", "a.txt"])
            self.assertEqual(len(native.entries(root, show_hidden=True)), 3)
            self.assertIn("hello", native.preview(root / "a.txt"))

    def test_transfer_never_overwrites_or_recurses(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "source"
            source.mkdir()
            (source / "note.txt").write_text("safe", encoding="utf-8")
            destination = root / "destination"
            destination.mkdir()
            copied = native.transfer(source, destination)
            self.assertEqual((copied / "note.txt").read_text(encoding="utf-8"), "safe")
            with self.assertRaises(FileExistsError):
                native.transfer(source, destination)
            with self.assertRaises(ValueError):
                native.transfer(source, source)

    def test_delete_rejects_protected_path(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "keep.txt"
            path.write_text("keep", encoding="utf-8")
            with mock.patch.object(native, "_protected", return_value=True):
                with self.assertRaises(ValueError):
                    native.delete(path)
            self.assertTrue(path.exists())

    def test_zip_rejects_parent_traversal(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / "bad.zip"
            with zipfile.ZipFile(archive, "w") as output:
                output.writestr("../outside.txt", "bad")
            with self.assertRaises(ValueError):
                native.extract_zip(archive)
            self.assertFalse((root / "outside.txt").exists())
            self.assertFalse((root / "bad").exists())

    def test_native_cli_quits_without_file_changes(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with mock.patch("builtins.input", return_value="quit"):
                self.assertEqual(native.main([str(root)]), 0)
            self.assertEqual(list(root.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
