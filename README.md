# Terminal Explorer

[![Release](https://img.shields.io/github/v/release/baska-pro/terminal-explorer?style=flat-square)](https://github.com/baska-pro/terminal-explorer/releases/latest)
[![CI](https://github.com/baska-pro/terminal-explorer/actions/workflows/ci.yml/badge.svg)](https://github.com/baska-pro/terminal-explorer/actions/workflows/ci.yml)
[![License: Baska-Pro Personal Use](https://img.shields.io/badge/License-Baska--Pro%20Personal%20Use%201.0-blue.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Termux%20%7C%20Linux-2ea44f?style=flat-square)](#platform)


File manager interaktif berbasis **Bash + fzf** untuk **Termux dan Linux**.

> Current release: **v3.0.0** — universal untuk Termux dan Linux.

## Platform

Didukung:

- Termux / Android
- Debian / Ubuntu
- Fedora / RHEL
- Arch Linux / Manjaro
- openSUSE
- Alpine Linux
- Void Linux
- Linux generic selama dependency tersedia

## Fitur

Fitur utama dari Termux Explorer tetap dipertahankan:

- navigasi folder interaktif dengan `fzf`;
- preview file/folder/symlink;
- buat file dan folder;
- edit file;
- jalankan script/file executable;
- info file/folder;
- chmod;
- copy, cut, paste, move, rename, delete;
- clipboard internal;
- copy isi file ke clipboard sistem;
- bookmark;
- pencarian nama dan isi file;
- sort berdasarkan nama, ukuran, tanggal;
- hidden files;
- kompres dan ekstrak archive;
- deteksi Git repository;
- perlindungan path penting;
- `--doctor`, `--help`, dan `--version`.

## Install cepat

### Termux / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/baska-pro/terminal-explorer/main/install.sh | bash
```

Installer mendeteksi package manager:

```text
pkg
apt
dnf / yum
pacman
zypper
apk
xbps
```

### Dari clone

```bash
git clone https://github.com/baska-pro/terminal-explorer.git
cd terminal-explorer
chmod +x install.sh
./install.sh
```

## Jalankan

```bash
terminal-explorer
```

Alias:

```bash
texplorer
```

Buka folder tertentu:

```bash
texplorer ~/projects
```

Diagnostik:

```bash
texplorer --doctor
```

## Clipboard

Backend dipilih otomatis:

| Environment | Backend |
|---|---|
| Termux | `termux-clipboard-set` |
| Linux Wayland | `wl-copy` |
| Linux X11 | `xclip` |
| Linux X11 alternatif | `xsel` |

Clipboard sistem bersifat opsional. Clipboard internal copy/cut/paste tetap berfungsi tanpa backend tersebut.

## `bat` di Debian/Ubuntu

Pada sebagian versi Debian/Ubuntu executable paket `bat` bernama `batcat`.

Terminal Explorer mendeteksi keduanya otomatis:

```text
bat
batcat
```

Tidak perlu membuat symlink manual.

## Install path

Termux:

```text
$PREFIX/share/terminal-explorer/explorer.sh
$PREFIX/bin/terminal-explorer
$PREFIX/bin/texplorer
```

Linux:

```text
~/.local/share/terminal-explorer/explorer.sh
~/.local/bin/terminal-explorer
~/.local/bin/texplorer
```

Config:

```text
~/.config/terminal-explorer/
```

Jika bookmark lama ditemukan di:

```text
~/.config/termux-explorer/bookmarks
```

bookmark akan disalin otomatis saat config baru belum ada.


## Release

Versi stabil saat ini:

```text
v3.0.0
```

Lihat [GitHub Releases](https://github.com/baska-pro/terminal-explorer/releases/latest) untuk source archive dan asset release.

## Uninstall

```bash
./uninstall.sh
```

Hapus juga config:

```bash
./uninstall.sh --purge
```

## Safety

Sebelum delete, rename overwrite, move overwrite, dan operasi destruktif lain, aplikasi meminta konfirmasi.

Path penting seperti `/`, `/etc`, `/usr`, `/var`, `$HOME`, dan root Termux dilindungi dari operasi delete melalui menu.

Baca [docs/SAFETY.md](docs/SAFETY.md).

## License

BASKA-PRO PERSONAL USE LICENSE
Version 1.0

Copyright (c) 2026 Lathif Baska
All Rights Reserved.