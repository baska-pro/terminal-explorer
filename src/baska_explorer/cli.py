"""Local launcher for the bundled Terminal Explorer Bash script.

Installing this package never runs an installer, downloads remote code, or
modifies system packages. External Bash/fzf dependencies remain user-managed.
"""
from __future__ import annotations

from importlib import resources
import shutil
import subprocess
import sys


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    if not sys.platform.startswith("linux"):
        print("Terminal Explorer supports Linux and Termux only; Windows is not supported.", file=sys.stderr)
        return 2

    bash = shutil.which("bash")
    if not bash:
        print("Bash is required. Install bash with your system package manager.", file=sys.stderr)
        return 127

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
