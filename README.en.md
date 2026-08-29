# Terminal Explorer

Interactive **Bash + fzf** file manager for **Termux and Linux**.

Current source remains version **3.0** while universal Linux support is tracked under **Unreleased**.

Supported environments include Termux, Debian/Ubuntu, Fedora/RHEL, Arch/Manjaro, openSUSE, Alpine, Void Linux, and generic Linux systems with the required commands installed.

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
