"""Local launcher for the platform-specific Terminal Explorer interface.

Installing this package never runs an installer, downloads remote code, or
modifies system packages. Linux uses the bundled Bash interface.
"""
from __future__ import annotations

from importlib import resources
import shutil
import subprocess
import sys

from . import native, setup


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    if args and args[0] == "--native":
        return native.main(args[1:])
    if not sys.platform.startswith("linux"):
        return native.main(args)

    if args and args[0] == "--setup":
        if args[1:] not in ([], ["--yes"]):
            print("Usage: baska-explorer --setup [--yes]", file=sys.stderr)
            return 2
        return setup.install_dependencies(yes=args[1:] == ["--yes"])

    bash = shutil.which("bash")
    if not bash:
        print("Bash is unavailable; using the portable interface.", file=sys.stderr)
        return native.main(args)
    if (not args or not args[0].startswith("-")) and not shutil.which("fzf"):
        print("fzf is unavailable; using the portable interface. Run baska-explorer --setup for the full Bash interface.", file=sys.stderr)
        return native.main(args)

    try:
        script = resources.files("baska_explorer").joinpath("explorer.sh")
        with resources.as_file(script) as path:
            return subprocess.call([bash, str(path), *args])
    except KeyboardInterrupt:
        return 130
    except OSError as exc:
        print(f"Unable to launch Terminal Explorer: {exc}", file=sys.stderr)
        return 127


if __name__ == "__main__":
    sys.exit(main())
