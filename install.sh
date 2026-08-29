#!/usr/bin/env bash
set -euo pipefail

REPO="baska-pro/terminal-explorer"
RAW_URL="https://raw.githubusercontent.com/${REPO}/main/explorer.sh"
APP_DIR_NAME="terminal-explorer"
SOURCE=""
TEMP_SOURCE=""
PM=""
SUDO=()

cleanup() {
    [ -n "$TEMP_SOURCE" ] && rm -f -- "$TEMP_SOURCE" 2>/dev/null || true
}
trap cleanup EXIT

is_termux() {
    [[ -n "${PREFIX:-}" && "$PREFIX" == *com.termux* ]] \
        || [[ -d /data/data/com.termux/files/usr ]] \
        || [[ -n "${TERMUX_VERSION:-}" ]]
}

is_linux() {
    [[ "$(uname -s 2>/dev/null)" == "Linux" ]]
}

detect_pm() {
    local pm
    if is_termux && command -v pkg >/dev/null 2>&1; then
        echo pkg
        return
    fi
    for pm in apt-get dnf yum pacman zypper apk xbps-install; do
        command -v "$pm" >/dev/null 2>&1 && { echo "$pm"; return; }
    done
    echo unknown
}

setup_privilege() {
    if is_termux || [ "$(id -u)" -eq 0 ]; then
        SUDO=()
    elif command -v sudo >/dev/null 2>&1; then
        SUDO=(sudo)
    elif command -v doas >/dev/null 2>&1; then
        SUDO=(doas)
    else
        SUDO=()
    fi
}

install_dependencies() {
    [ "${TE_SKIP_DEPS:-0}" = "1" ] && {
        echo "[*] Dependency install dilewati (TE_SKIP_DEPS=1)."
        return 0
    }

    PM="$(detect_pm)"
    setup_privilege
    echo "[*] Platform package manager: $PM"

    if ! is_termux && [ "$(id -u)" -ne 0 ] && [ "${#SUDO[@]}" -eq 0 ]; then
        echo "[!] sudo/doas tidak tersedia. Dependency tidak dipasang otomatis."
        echo "    Install manual: bash fzf bat/batcat tree file findutils coreutils gawk grep sed"
        return 0
    fi

    case "$PM" in
        pkg)
            pkg install -y bash fzf bat tree file findutils coreutils gawk grep sed nano tar zip unzip gzip bzip2 xz-utils curl
            ;;
        apt-get)
            "${SUDO[@]}" apt-get update
            "${SUDO[@]}" apt-get install -y bash fzf bat tree file findutils coreutils gawk grep sed nano tar zip unzip gzip bzip2 xz-utils curl
            ;;
        dnf)
            "${SUDO[@]}" dnf install -y bash fzf bat tree file findutils coreutils gawk grep sed nano tar zip unzip gzip bzip2 xz curl
            ;;
        yum)
            "${SUDO[@]}" yum install -y bash fzf bat tree file findutils coreutils gawk grep sed nano tar zip unzip gzip bzip2 xz curl
            ;;
        pacman)
            "${SUDO[@]}" pacman -Sy --needed --noconfirm bash fzf bat tree file findutils coreutils gawk grep sed nano tar zip unzip gzip bzip2 xz curl
            ;;
        zypper)
            "${SUDO[@]}" zypper --non-interactive install bash fzf bat tree file findutils coreutils gawk grep sed nano tar zip unzip gzip bzip2 xz curl
            ;;
        apk)
            "${SUDO[@]}" apk add bash fzf bat tree file findutils coreutils gawk grep sed nano tar zip unzip gzip bzip2 xz curl
            ;;
        xbps-install)
            "${SUDO[@]}" xbps-install -Sy bash fzf bat tree file findutils coreutils gawk grep sed nano tar zip unzip gzip bzip2 xz curl
            ;;
        *)
            echo "[!] Package manager tidak dikenali. Dependency tidak dipasang otomatis."
            echo "    Install manual: bash fzf bat/batcat tree file findutils coreutils gawk grep sed"
            ;;
    esac
}

if ! is_termux && ! is_linux; then
    echo "[-] Installer mendukung Termux dan Linux." >&2
    exit 3
fi

if is_termux; then
    INSTALL_DIR="${PREFIX}/share/${APP_DIR_NAME}"
    BIN_DIR="${PREFIX}/bin"
else
    INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/${APP_DIR_NAME}"
    BIN_DIR="$HOME/.local/bin"
fi

install_dependencies

SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [ -n "${TERMINAL_EXPLORER_SOURCE:-}" ]; then
    [ -f "$TERMINAL_EXPLORER_SOURCE" ] || {
        echo "[-] TERMINAL_EXPLORER_SOURCE tidak ditemukan." >&2
        exit 1
    }
    SOURCE="$TERMINAL_EXPLORER_SOURCE"
elif [ -n "$SCRIPT_SOURCE" ] && [ -f "$SCRIPT_SOURCE" ]; then
    HERE="$(cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)"
    [ -f "$HERE/explorer.sh" ] && SOURCE="$HERE/explorer.sh"
fi

if [ -z "$SOURCE" ]; then
    TD="${TMPDIR:-}"
    if [ -z "$TD" ]; then
        if is_termux; then TD="${PREFIX}/tmp"; else TD="/tmp"; fi
    fi
    mkdir -p "$TD"
    TEMP_SOURCE="$(mktemp "$TD/terminal-explorer.XXXXXX.sh")"
    echo "[*] Mengunduh explorer.sh dari GitHub..."

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$RAW_URL" -o "$TEMP_SOURCE"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$TEMP_SOURCE" "$RAW_URL"
    else
        echo "[-] curl/wget tidak tersedia untuk mengunduh source." >&2
        exit 1
    fi
    SOURCE="$TEMP_SOURCE"
fi

bash -n "$SOURCE"

mkdir -p "$INSTALL_DIR" "$BIN_DIR"

TMP_INSTALL="$INSTALL_DIR/.explorer.sh.tmp.$$"
cp -- "$SOURCE" "$TMP_INSTALL"
chmod 755 "$TMP_INSTALL"
mv -f -- "$TMP_INSTALL" "$INSTALL_DIR/explorer.sh"

for command_name in terminal-explorer texplorer; do
    WRAP_TMP="$BIN_DIR/.${command_name}.tmp.$$"
    cat > "$WRAP_TMP" <<EOF
#!/usr/bin/env sh
exec "$INSTALL_DIR/explorer.sh" "\$@"
EOF
    chmod 755 "$WRAP_TMP"
    mv -f -- "$WRAP_TMP" "$BIN_DIR/$command_name"
done

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo "[!] $BIN_DIR belum ada di PATH."
        echo "    Tambahkan ke ~/.bashrc / ~/.zshrc:"
        echo "    export PATH=\"$BIN_DIR:\$PATH\""
        ;;
esac

echo "[+] Terminal Explorer terpasang."
echo "[+] Command: terminal-explorer"
echo "[+] Alias  : texplorer"
"$BIN_DIR/terminal-explorer" --version

if is_termux; then
    echo "[*] Clipboard Android opsional: pkg install termux-api + aplikasi Termux:API"
else
    echo "[*] Clipboard Linux opsional: wl-clipboard (Wayland) atau xclip/xsel (X11)"
fi
