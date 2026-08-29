# Contributing

1. Fork or branch from `main`.
2. Preserve existing navigation and file-operation behavior unless the change intentionally fixes a bug.
3. Keep Termux and Linux compatibility.
4. Run:

```bash
bash -n explorer.sh
bash -n install.sh
bash -n uninstall.sh
bash tests/smoke.sh
```

5. Test interactive `fzf` behavior on at least one real terminal when changing UI/navigation.
6. Do not commit tokens, personal paths, generated archives, or editor temporary files.
