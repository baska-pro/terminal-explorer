<!-- repo-banner:start -->
<p align="center">
  <img src="https://raw.githubusercontent.com/baska-pro/terminal-explorer/main/assets/banner.png" alt="Terminal Explorer Banner" width="100%">
</p>
<!-- repo-banner:end -->

# Terminal Explorer

[![Release](https://img.shields.io/github/v/release/baska-pro/terminal-explorer?style=flat-square)](https://github.com/baska-pro/terminal-explorer/releases/latest)
[![CI](https://github.com/baska-pro/terminal-explorer/actions/workflows/ci.yml/badge.svg)](https://github.com/baska-pro/terminal-explorer/actions/workflows/ci.yml)
[![License: Baska-Pro Personal Use](https://img.shields.io/badge/License-Baska--Pro%20Personal%20Use%201.0-blue.svg?style=flat-square)](LICENSE)

Interactive **Bash + fzf** file manager for **Termux and Linux**.

Current stable release: **v3.0.2**, with universal support for Termux and Linux.

Supported environments include Termux, Debian/Ubuntu, Fedora/RHEL, Arch/Manjaro, openSUSE, Alpine, Void Linux, and generic Linux systems with the required commands installed.

## Install from PyPI (Linux and Termux)

The `baska-explorer` distribution includes the original Bash script and installs the commands `baska-explorer`, `terminal-explorer`, and `texplorer`. On a fresh install, unpinned `pip install baska-explorer` selects the latest available release. If already installed, use `pip install --upgrade baska-explorer`. Pip does not change OS packages. Run `baska-explorer --setup` afterwards to install missing system packages through the detected package manager, after reviewing and confirming the displayed command. Use `--setup --yes` only when you intentionally want a noninteractive setup.

On Debian, Ubuntu, and WSL with an externally managed system Python (PEP 668), use `pipx`:

```bash
sudo apt update
sudo apt install -y pipx
pipx ensurepath
# Open a new terminal if the command is not yet on PATH.
pipx install baska-explorer
baska-explorer --setup
baska-explorer --doctor
baska-explorer
```

In Termux or an activated Python virtual environment, `pip install baska-explorer` is available. Native Windows PowerShell is unsupported; run the application inside WSL. Do not use `--break-system-packages` to bypass PEP 668.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/baska-pro/terminal-explorer/main/install.sh | bash
```

Run:

```bash
terminal-explorer
```

Alias:

```bash
texplorer
```

Diagnostics:

```bash
texplorer --doctor
```

The installer detects `pkg`, `apt-get`, `dnf`, `yum`, `pacman`, `zypper`, `apk`, and `xbps-install`.

The application automatically supports `bat` or Debian's `batcat`, and system clipboard backends including Termux:API, `wl-copy`, `xclip`, and `xsel`.

See [README.md](README.md) for the Indonesian documentation.
