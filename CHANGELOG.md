# Changelog

## Unreleased

### Added

- Universal Termux + Linux runtime detection.
- Linux distribution/package-manager diagnostics.
- Installer support for `pkg`, `apt-get`, `dnf`, `yum`, `pacman`, `zypper`, `apk`, and `xbps-install`.
- Automatic `bat` / `batcat` compatibility.
- Clipboard backend detection for Termux, Wayland (`wl-copy`), and X11 (`xclip` / `xsel`).
- `$EDITOR` / nano / vim / vi editor fallback.
- User-local Linux installation under `~/.local`.
- Non-destructive bookmark migration from the old Termux Explorer config directory.
- Protection for important Linux system roots.

### Changed

- Project branding changed from Termux Explorer to Terminal Explorer because the application is no longer Termux-only.
- Temporary files now use `$TMPDIR`, Termux `$PREFIX/tmp`, or `/tmp` as appropriate.
- Dependency messages now match the detected package manager.
- `--doctor` now reports platform, package manager, preview command, and clipboard backend.

### Preserved

- Existing fzf navigation and preview workflow.
- File/folder action menus.
- Internal copy/cut/paste clipboard.
- Search, bookmarks, sorting, hidden-file toggle, chmod, compression/extraction, Git info, and safety confirmations.

## 3.0

Original Termux Explorer Ultimate v3.0 feature set.
