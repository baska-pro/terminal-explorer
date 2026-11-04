# Changelog

## Unreleased

No unreleased changes yet.

## 3.0.2 - 2026-11-04

### Added
- Optional `baska-explorer --setup` to detect and install missing OS packages after explicit confirmation.
- `baska-explorer --setup --yes` for deliberate noninteractive setup.

### Changed
- Clarified that `pip install baska-explorer` installs the latest PyPI release without a version pin.
- Improved missing-dependency guidance for PyPI users.
- Kept shell scripts with Unix line endings in Windows checkouts so WSL and Linux can run them directly.

## 3.0.1 - 2026-11-04 (PyPI packaging candidate)

### Added
- Standalone PyPI distribution `baska-explorer` with a bundled copy of the Bash application.
- Safe Python launchers for `baska-explorer`, `terminal-explorer` and `texplorer`.
- Automated wheel and source-distribution builds, tests and release workflow.

### Compatibility
- Keep the original Bash installation method unchanged.
- `pip` does not install OS dependencies such as Bash, fzf, tree and bat/batcat.
- Windows remains unsupported.
- This is a packaging candidate; it is not published to PyPI until approved.


## 3.0.0 - 2026-08-29

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
