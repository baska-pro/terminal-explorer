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

Current stable release: **v3.0.1**, with universal support for Termux and Linux.

Supported environments include Termux, Debian/Ubuntu, Fedora/RHEL, Arch/Manjaro, openSUSE, Alpine, Void Linux, and generic Linux systems with the required commands installed.

## Install from PyPI (Linux and Termux)

The separately packaged `baska-explorer` distribution includes the original Bash script and installs the commands `baska-explorer`, `terminal-explorer`, and `texplorer`. It does not install OS packages or download executable code during setup. Install bash, fzf, tree, file, GNU tools, and bat/batcat separately.

```bash
python -m pip install baska-explorer
baska-explorer --doctor
baska-explorer
```

For Linux application isolation, prefer `pipx install baska-explorer`. Windows is unsupported.

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
