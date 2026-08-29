#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

bash -n explorer.sh
bash -n install.sh
bash -n uninstall.sh

grep -q 'VERSION="3.0"' explorer.sh
grep -q 'Terminal Explorer Ultimate v3.0' <<< "$(./explorer.sh --version)"
grep -q 'Usage:' <<< "$(./explorer.sh --help)"
grep -q 'Supported:' <<< "$(./explorer.sh --help)"
grep -q 'Required commands:' <<< "$(./explorer.sh --doctor)"
grep -q 'Package mgr:' <<< "$(./explorer.sh --doctor)"
grep -q 'Clipboard' <<< "$(./explorer.sh --doctor)"

# The universal source must not use the old Termux-only shebang or startup warning.
! grep -q '^#!/data/data/com.termux' explorer.sh
! grep -q 'Script ini dirancang untuk Termux' explorer.sh

# Generic Linux install locations must exist in installer logic.
grep -q '\.local/share' install.sh
grep -q '\.local/bin' install.sh
grep -q 'apt-get' install.sh
grep -q 'pacman' install.sh
grep -q 'apk' install.sh

echo "[OK] smoke tests passed"
