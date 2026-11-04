# Publish baska-explorer on PyPI

The repository's root `explorer.sh` remains the canonical Bash application.
The wheel bundles an identical copy and offers the commands
`baska-explorer`, `terminal-explorer`, and `texplorer`.

## Publishing a new version

1. Review and merge the release PR only after GitHub CI succeeds.
2. Confirm the active PyPI Trusted Publisher still matches GitHub owner
   `baska-pro`, repository `terminal-explorer`, workflow `publish-pypi.yml`,
   and environment `pypi`.
3. Confirm GitHub Environment `pypi` requires a reviewer and allows only
   version tags. Confirm the version-tag ruleset prevents updates and deletion.
4. Tag the approved commit as `v3.1.0`.
5. Approve the environment deployment after verify/build jobs succeed.
6. Confirm all tag workflow jobs succeed and PyPI provides a wheel/sdist.
7. Smoke-test `pip install baska-explorer==3.1.0` from the actual PyPI
   index in isolated Linux and Windows environments.

An unpinned `pip install baska-explorer` installs the latest published version.

## Operational safety

The PyPI package does not run `install.sh`, does not modify `~/.local/bin`
or `$PREFIX/bin` outside normal pip script installation, does not download
executable code, and does not install OS dependencies. Users need Bash,
fzf, tree, file, GNU utilities, and bat/batcat. The explicit
`baska-explorer --setup` command can install missing OS packages with user
confirmation; `--setup --yes` is only for deliberate noninteractive use.
Windows and macOS use the native Python backend. Linux and Termux use the Bash backend.

The original `install.sh` is still usable. If both are installed,
run `command -v terminal-explorer` to identify which PATH entry is selected.

## Release maintenance

Keep `explorer.sh` and `src/baska_explorer/explorer.sh` byte-for-byte
identical. The unit test compares their SHA-256 values. Update together:
`VERSION`, `explorer.sh`, `src/baska_explorer/explorer.sh`,
`src/baska_explorer/__init__.py`, `pyproject.toml`, shell smoke tests,
README and changelog. PyPI versions cannot be replaced after upload.
