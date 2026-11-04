"""Portable terminal file manager for Windows and other non-Linux systems."""
from __future__ import annotations

import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import zipfile

from . import __version__


HELP = """BASKA Explorer native commands:
  N / cd N          enter directory N or preview file N
  up                go to parent directory
  preview N         preview a file or directory
  open N            open a file with the system default application
  edit N            edit a file with EDITOR or Notepad on Windows
  newfile NAME      create an empty file
  mkdir NAME        create a directory
  rename N NAME     rename an item
  copy N / cut N    select an item for copying or moving
  paste             paste into the current directory
  delete N          delete an item after confirmation
  find TEXT         search file names below the current directory
  grep TEXT         search text files below the current directory
  bookmark          save the current directory
  bookmarks         list saved directories and choose one
  hidden            show or hide dotfiles and hidden Windows files
  sort MODE         name, size, or date
  zip N             create a ZIP archive of an item
  extract N         safely extract a ZIP into a new directory
  help / quit       show help or exit
"""


def _config_dir() -> Path:
    if os.name == "nt":
        return Path(os.environ.get("APPDATA", str(Path.home()))) / "baska-explorer"
    return Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "baska-explorer"


def _hidden(path: Path) -> bool:
    if path.name.startswith("."):
        return True
    if os.name == "nt":
        try:
            return bool(path.stat().st_file_attributes & stat.FILE_ATTRIBUTE_HIDDEN)
        except (AttributeError, OSError):
            pass
    return False


def entries(directory: Path, *, show_hidden: bool = False, sort: str = "name") -> list[Path]:
    items = [p for p in directory.iterdir() if show_hidden or not _hidden(p)]

    def key(path: Path) -> tuple[bool, object, str]:
        try:
            info = path.stat()
            value: object = -info.st_size if sort == "size" else -info.st_mtime if sort == "date" else path.name.casefold()
        except OSError:
            value = 0 if sort != "name" else path.name.casefold()
        return (not path.is_dir(), value, path.name.casefold())

    return sorted(items, key=key)


def preview(path: Path) -> str:
    if path.is_symlink():
        return f"Link → {os.readlink(path)}"
    if path.is_dir():
        return "Directory: " + str(path) + "\n" + "\n".join(p.name for p in list(path.iterdir())[:30])
    if not path.is_file():
        return "This item is unavailable."
    with path.open("rb") as stream:
        data = stream.read(64_001)
    if b"\0" in data:
        return f"Binary file ({path.stat().st_size} bytes)"
    return "\n".join(data[:64_000].decode("utf-8", errors="replace").splitlines()[:60])


def _protected(path: Path) -> bool:
    path = path.resolve()
    home = Path.home().resolve()
    if path in {home, Path(path.anchor).resolve()}:
        return True
    system_dirs = []
    if os.name == "nt":
        for name in ("SystemRoot", "ProgramFiles", "ProgramFiles(x86)"):
            if os.environ.get(name):
                system_dirs.append(Path(os.environ[name]).resolve())
    else:
        system_dirs.extend(Path(name).resolve() for name in ("/etc", "/usr", "/var", "/boot", "/bin", "/sbin"))
    return any(path == directory or directory in path.parents for directory in system_dirs)


def delete(path: Path) -> None:
    if _protected(path):
        raise ValueError(f"Protected path: {path}")
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def transfer(source: Path, directory: Path, *, move: bool = False) -> Path:
    destination = directory / source.name
    if destination.exists() or destination.is_symlink():
        raise FileExistsError(f"Already exists: {destination}")
    if move and _protected(source):
        raise ValueError(f"Protected path: {source}")
    if source.is_dir() and (directory.resolve() == source.resolve() or source.resolve() in directory.resolve().parents):
        raise ValueError("Cannot copy a directory into itself")
    if move:
        return Path(shutil.move(str(source), str(destination)))
    if source.is_dir() and not source.is_symlink():
        shutil.copytree(source, destination, symlinks=True)
    else:
        shutil.copy2(source, destination, follow_symlinks=False)
    return destination


def make_zip(source: Path) -> Path:
    if source.is_symlink():
        raise ValueError("ZIP creation does not follow symbolic links")
    output = source.with_name(source.name + ".zip")
    if output.exists():
        raise FileExistsError(f"Already exists: {output}")
    with zipfile.ZipFile(output, "x", compression=zipfile.ZIP_DEFLATED) as archive:
        paths = source.rglob("*") if source.is_dir() else (source,)
        for path in paths:
            if path.is_symlink() or not path.is_file():
                continue
            archive.write(path, path.relative_to(source) if source.is_dir() else source.name)
    return output


def extract_zip(source: Path) -> Path:
    if not zipfile.is_zipfile(source):
        raise ValueError("Select a ZIP archive")
    output = source.with_name(source.stem + "-extracted")
    if output.exists():
        raise FileExistsError(f"Already exists: {output}")
    with zipfile.ZipFile(source) as archive:
        for member in archive.infolist():
            name = Path(member.filename)
            if name.is_absolute() or ".." in name.parts or stat.S_ISLNK(member.external_attr >> 16):
                raise ValueError(f"Unsafe ZIP entry: {member.filename}")
            target = (output / name).resolve()
            if not target.is_relative_to(output.resolve()):
                raise ValueError(f"Unsafe ZIP entry: {member.filename}")
        output.mkdir()
        try:
            for member in archive.infolist():
                target = output / member.filename
                if member.is_dir():
                    target.mkdir(parents=True, exist_ok=True)
                else:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with archive.open(member) as src, target.open("xb") as dst:
                        shutil.copyfileobj(src, dst)
        except Exception:
            shutil.rmtree(output)
            raise
    return output


def _search(directory: Path, phrase: str, *, content: bool = False) -> list[str]:
    found = []
    for root, dirs, files in os.walk(directory):
        dirs[:] = [name for name in dirs if not name.startswith(".")]
        names = files if content else dirs + files
        for name in names:
            path = Path(root) / name
            try:
                if content:
                    if path.stat().st_size > 1_000_000:
                        continue
                    with path.open("rb") as stream:
                        data = stream.read(1_000_001)
                    if b"\0" in data or phrase.casefold() not in data.decode("utf-8", errors="replace").casefold():
                        continue
                elif phrase.casefold() not in name.casefold():
                    continue
                found.append(str(path))
            except (OSError, UnicodeError):
                continue
            if len(found) >= 100:
                return found
    return found


def _open(path: Path, *, edit: bool = False) -> None:
    if edit and os.environ.get("EDITOR"):
        subprocess.run([os.environ["EDITOR"], str(path)], check=False)
    elif os.name == "nt":
        if edit:
            subprocess.run(["notepad.exe", str(path)], check=False)
        else:
            os.startfile(path)  # type: ignore[attr-defined]
    else:
        subprocess.run(["open" if sys.platform == "darwin" else "xdg-open", str(path)], check=False)


def main(args: list[str]) -> int:
    if args == ["--version"] or args == ["-V"]:
        print(f"Terminal Explorer v{__version__}")
        return 0
    if args == ["--help"] or args == ["-h"]:
        print(HELP)
        return 0
    if args == ["--doctor"]:
        print(f"BASKA Explorer {__version__} | Python {sys.version.split()[0]} | {sys.platform}")
        print("Native backend: no Bash/fzf/system package dependency")
        return 0
    if args in (["--setup"], ["--setup", "--yes"]):
        print("Native backend is ready; no system packages to install.")
        return 0
    if args and (len(args) != 1 or args[0].startswith("-")):
        print("Use --help for supported options.", file=sys.stderr)
        return 2

    current = Path(args[0] if args else Path.home()).expanduser()
    if current.is_file():
        current = current.parent
    if not current.is_dir():
        print(f"Directory not found: {current}", file=sys.stderr)
        return 2
    current = current.resolve()
    show_hidden = False
    sort = "name"
    clipboard: tuple[Path, bool] | None = None
    bookmarks_file = _config_dir() / "bookmarks.txt"
    print(HELP)
    while True:
        try:
            listing = entries(current, show_hidden=show_hidden, sort=sort)
            print(f"\n{current}  [{len(listing)} items]  hidden={'on' if show_hidden else 'off'}  sort={sort}")
            for index, path in enumerate(listing, 1):
                print(f" {index:>3} {'[D]' if path.is_dir() else '[F]'} {path.name}")
            raw = input("explorer> ").strip()
            if not raw:
                continue
            command, _, value = raw.partition(" ")
            command = command.lower()
            if command in ("quit", "q", "exit"):
                return 0
            if command in ("help", "?"):
                print(HELP)
                continue
            if command == "up":
                current = current.parent
                continue
            if command == "hidden":
                show_hidden = not show_hidden
                continue
            if command == "sort" and value in ("name", "size", "date"):
                sort = value
                continue
            if command == "bookmark":
                bookmarks_file.parent.mkdir(parents=True, exist_ok=True)
                saved = bookmarks_file.read_text(encoding="utf-8").splitlines() if bookmarks_file.exists() else []
                if str(current) not in saved:
                    bookmarks_file.write_text("\n".join([*saved, str(current)]) + "\n", encoding="utf-8")
                print("Bookmarked:", current)
                continue
            if command == "bookmarks":
                saved = bookmarks_file.read_text(encoding="utf-8").splitlines() if bookmarks_file.exists() else []
                for index, item in enumerate(saved, 1):
                    print(index, item)
                choice = input("Bookmark number (Enter to cancel): ").strip()
                if choice.isdigit() and 1 <= int(choice) <= len(saved) and Path(saved[int(choice)-1]).is_dir():
                    current = Path(saved[int(choice)-1]).resolve()
                continue
            if command in ("newfile", "mkdir") and value:
                if Path(value).name != value or value in (".", ".."):
                    raise ValueError("Provide one valid name")
                target = current / value
                if target.exists():
                    raise FileExistsError(target)
                target.touch(exist_ok=False) if command == "newfile" else target.mkdir()
                continue
            if command in ("find", "grep") and value:
                for result in _search(current, value, content=command == "grep"):
                    print(result)
                continue
            if command == "paste" and clipboard:
                print("Created:", transfer(clipboard[0], current, move=clipboard[1]))
                if clipboard[1]:
                    clipboard = None
                continue
            number, _, name = value.partition(" ")
            if command.isdigit():
                number = command
                command = "cd"
            if not number.isdigit() or not 1 <= int(number) <= len(listing):
                print("Choose an item number. Type help for commands.")
                continue
            path = listing[int(number)-1]
            if command == "cd":
                if path.is_dir():
                    current = path.resolve()
                else:
                    print(preview(path))
            elif command == "preview":
                print(preview(path))
            elif command in ("open", "edit"):
                _open(path, edit=command == "edit")
            elif command == "rename" and name:
                if Path(name).name != name or name in (".", ".."):
                    raise ValueError("Provide one valid new name")
                if _protected(path):
                    raise ValueError(f"Protected path: {path}")
                destination = path.with_name(name)
                if destination.exists():
                    raise FileExistsError(destination)
                path.rename(destination)
            elif command in ("copy", "cut"):
                clipboard = (path, command == "cut")
                print("Selected:", path)
            elif command == "delete":
                if input(f"Delete {path}? Type DELETE: ").strip() == "DELETE":
                    delete(path)
                else:
                    print("Cancelled.")
            elif command == "zip":
                print("Created:", make_zip(path))
            elif command == "extract":
                print("Extracted:", extract_zip(path))
            else:
                print("Unknown command. Type help.")
        except (EOFError, KeyboardInterrupt):
            print()
            return 0
        except (OSError, ValueError, zipfile.BadZipFile) as exc:
            print(f"Error: {exc}", file=sys.stderr)
