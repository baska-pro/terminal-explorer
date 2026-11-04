# Publish baska-explorer on PyPI

The repository's root `explorer.sh` remains the canonical Bash application.
The wheel bundles an identical copy and offers the commands
`baska-explorer`, `terminal-explorer`, and `texplorer`.

## Before publishing the first version

1. Review and merge the packaging PR only after GitHub CI succeeds.
2. Sign in to PyPI and set up a **pending Trusted Publisher** for a new
   project named `baska-explorer`:
   - GitHub owner: `baska-pro`
   - Repository: `terminal-explorer`
   - Workflow filename: `publish-pypi.yml`
   - Environment: `pypi`
3. Configure GitHub Environment `pypi`, restrict publication to version
   tags, and optionally require a reviewer.
4. Tag the approved commit as `v3.0.1` (do not reuse `v3.0.0`).
5. Confirm all tag workflow jobs succeed and PyPI provides a wheel/sdist.
6. Smoke-test `pip install baska-explorer==3.0.1` from the actual PyPI
   index in an isolated Linux/Termux environment.

A 404 from the public PyPI JSON API means the project was not registered at
the time of checking, **not** that the name is reserved for this account.
The first publication may still fail if the name is reserved or claimed.

## Operational safety

The PyPI package does not run `install.sh`, does not modify `~/.local/bin`
or `$PREFIX/bin` outside normal pip script installation, does not download
executable code, and does not install OS dependencies. Users need Bash,
fzf, tree, file, GNU utilities, and bat/batcat installed separately.
Windows is not supported.

The original `install.sh` is still usable. If both are installed,
run `command -v terminal-explorer` to identify which PATH entry is selected.

## Release maintenance

Keep `explorer.sh` and `src/baska_explorer/explorer.sh` byte-for-byte
identical. The unit test compares their SHA-256 values. Update together:
`VERSION`, `explorer.sh`, `src/baska_explorer/explorer.sh`,
`src/baska_explorer/__init__.py`, `pyproject.toml`, shell smoke tests,
README and changelog. PyPI versions cannot be replaced after upload.
