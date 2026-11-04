"""Optional, explicit installation of operating-system dependencies."""
from __future__ import annotations

import os
import shutil
import subprocess
import sys


REQUIREMENTS = (
    (("bash",), "bash"),
    (("fzf",), "fzf"),
    (("tree",), "tree"),
    (("file",), "file"),
    (("find",), "findutils"),
    (("stat", "du", "sort", "cut", "wc", "df"), "coreutils"),
    (("awk",), "gawk"),
    (("grep",), "grep"),
    (("sed",), "sed"),
    (("bat", "batcat"), "bat"),
)


def _termux() -> bool:
    return bool(os.environ.get("TERMUX_VERSION") or "com.termux" in os.environ.get("PREFIX", ""))


def _missing_packages() -> list[str]:
    packages = []
    for commands, package in REQUIREMENTS:
        # bat and batcat are alternatives; the other command groups need every tool.
        present = any(shutil.which(command) for command in commands) if package == "bat" else all(
            shutil.which(command) for command in commands
        )
        if not present:
            packages.append(package)
    return packages


def _package_manager() -> str | None:
    if _termux():
        return "pkg" if shutil.which("pkg") else None
    return next((pm for pm in ("apt-get", "dnf", "yum", "pacman", "zypper", "apk", "xbps-install") if shutil.which(pm)), None)


def install_dependencies(*, yes: bool = False) -> int:
    packages = _missing_packages()
    if not packages:
        print("All required system commands are available.")
        return 0

    pm = _package_manager()
    if not pm:
        print("No supported system package manager found. Install: " + " ".join(packages), file=sys.stderr)
        return 1

    prefix: list[str] = []
    if pm != "pkg" and os.geteuid() != 0:
        privilege = shutil.which("sudo") or shutil.which("doas")
        if not privilege:
            print("Administrator access is needed. Install manually: " + " ".join(packages), file=sys.stderr)
            return 1
        prefix = [privilege]

    arguments = {
        "pkg": ["install", "-y"],
        "apt-get": ["install", "-y"],
        "dnf": ["install", "-y"],
        "yum": ["install", "-y"],
        "pacman": ["-S", "--needed", "--noconfirm"],
        "zypper": ["--non-interactive", "install"],
        "apk": ["add"],
        "xbps-install": ["-Sy"],
    }
    command = [*prefix, pm, *arguments[pm], *packages]
    print("Missing system packages: " + ", ".join(packages))
    print("Will run: " + " ".join(command))
    if not yes:
        try:
            if input("Install these packages? [y/N] ").strip().lower() not in ("y", "yes"):
                print("Cancelled.")
                return 1
        except EOFError:
            print("Cancelled. Run --setup --yes to confirm noninteractively.", file=sys.stderr)
            return 1

    if pm == "apt-get":
        result = subprocess.call([*prefix, pm, "update"])
        if result:
            return result
    result = subprocess.call(command)
    if result:
        return result
    remaining = _missing_packages()
    if remaining:
        print("Still missing: " + ", ".join(remaining), file=sys.stderr)
        return 1
    print("System dependencies are ready. Run baska-explorer --doctor to check optional tools.")
    return 0
