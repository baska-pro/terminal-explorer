#!/usr/bin/env bash
set -euo pipefail

APP_DIR_NAME="terminal-explorer"
PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

is_termux() {
    [[ -n "${PREFIX:-}" && "$PREFIX" == *com.termux* ]] \
        || [[ -d /data/data/com.termux/files/usr ]] \
        || [[ -n "${TERMUX_VERSION:-}" ]]
}

if is_termux; then
    INSTALL_DIR="${PREFIX}/share/${APP_DIR_NAME}"
    BIN_DIR="${PREFIX}/bin"
else
    INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/${APP_DIR_NAME}"
    BIN_DIR="$HOME/.local/bin"
fi

CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/${APP_DIR_NAME}"

printf 'Hapus Terminal Explorer? [y/N]: '
read -r ans
case "$ans" in
    y|Y|yes|YES) ;;
    *) echo "Dibatalkan."; exit 0 ;;
esac

rm -f -- "$BIN_DIR/terminal-explorer" "$BIN_DIR/texplorer"
rm -rf -- "$INSTALL_DIR"

if [ "$PURGE" -eq 1 ]; then
    rm -rf -- "$CFG_DIR"
    echo "[+] Aplikasi dan konfigurasi dihapus."
else
    echo "[+] Aplikasi dihapus."
    echo "[*] Bookmark/config tetap di: $CFG_DIR"
    echo "    Gunakan ./uninstall.sh --purge untuk menghapus konfigurasi."
fi
