# Terminal Explorer

File manager interaktif berbasis **Bash + fzf** untuk **Termux dan Linux**.

> Status: v3.0 + perubahan **Unreleased** untuk dukungan Linux universal.

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

MIT
