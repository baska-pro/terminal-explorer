#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════╗
# ║           TERMINAL EXPLORER ULTIMATE v3.0.0                ║
# ║     File manager interaktif berbasis fzf — Termux/Linux       ║
# ╚══════════════════════════════════════════════════════════╝

VERSION="3.0.0"
APP_NAME="Terminal Explorer Ultimate"
REPO="baska-pro/terminal-explorer"

# ── Konfigurasi ───────────────────────────────────────────────
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/terminal-explorer"
BOOKMARK_FILE="$CFG_DIR/bookmarks"
LEGACY_CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/termux-explorer"

mkdir -p "$CFG_DIR"
if [ ! -e "$BOOKMARK_FILE" ] && [ -f "$LEGACY_CFG_DIR/bookmarks" ]; then
    cp -- "$LEGACY_CFG_DIR/bookmarks" "$BOOKMARK_FILE" 2>/dev/null || true
fi
touch "$BOOKMARK_FILE" 2>/dev/null
chmod 600 "$BOOKMARK_FILE" 2>/dev/null || true

# ── State global ──────────────────────────────────────────────
CURRENT_DIR="$HOME"
SHOW_HIDDEN=0
SORT_MODE="name"
CB_FILE=""
CB_OP=""

# ── Warna ─────────────────────────────────────────────────────
R="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
C_RED="\033[1;31m"
C_GRN="\033[1;32m"
C_YLW="\033[1;33m"
C_BLU="\033[1;34m"
C_MAG="\033[1;35m"
C_CYN="\033[1;36m"

# =============================================================
# UTILITY
# =============================================================

msg_ok()   { echo -e "${C_GRN}${BOLD} ✔  $1${R}"; }
msg_err()  { echo -e "${C_RED}${BOLD} ✘  $1${R}"; }
msg_info() { echo -e "${C_CYN} ℹ  $1${R}"; }
msg_warn() { echo -e "${C_YLW} ⚠  $1${R}"; }

pause() { echo -ne "${DIM}  ↵ Enter...${R}"; read -r _; }

confirm() {
    echo -ne "${C_YLW}$1 (y/n): ${R}"
    IFS= read -rsn1 _yn; echo
    [[ "$_yn" == "y" || "$_yn" == "Y" ]]
}

cleanup_terminal() {
    stty sane 2>/dev/null || true
}
trap cleanup_terminal EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

is_termux() {
    [[ -n "${PREFIX:-}" && "$PREFIX" == *com.termux* ]] \
        || [[ -d /data/data/com.termux/files/usr ]] \
        || [[ -n "${TERMUX_VERSION:-}" ]]
}

is_linux() {
    [[ "$(uname -s 2>/dev/null)" == "Linux" ]]
}

platform_id() {
    if is_termux; then
        printf '%s\n' "termux"
        return
    fi
    if [ -r /etc/os-release ]; then
        (
            . /etc/os-release
            printf '%s\n' "${ID:-linux}"
        )
        return
    fi
    printf '%s\n' "linux"
}

platform_name() {
    if is_termux; then
        printf '%s\n' "Termux / Android"
        return
    fi
    if [ -r /etc/os-release ]; then
        (
            . /etc/os-release
            printf '%s\n' "${PRETTY_NAME:-${NAME:-Linux}}"
        )
        return
    fi
    printf '%s\n' "$(uname -s 2>/dev/null || echo Linux)"
}

package_manager() {
    local pm
    for pm in pkg apt-get dnf yum pacman zypper apk xbps-install; do
        if command -v "$pm" >/dev/null 2>&1; then
            printf '%s\n' "$pm"
            return 0
        fi
    done
    printf '%s\n' "unknown"
}

resolve_bat() {
    if command -v bat >/dev/null 2>&1; then
        printf '%s\n' "bat"
    elif command -v batcat >/dev/null 2>&1; then
        printf '%s\n' "batcat"
    else
        printf '%s\n' ""
    fi
}

BAT_CMD="$(resolve_bat)"
export TE_BAT="$BAT_CMD"

editor_cmd() {
    if [ -n "${EDITOR:-}" ] && command -v "${EDITOR%% *}" >/dev/null 2>&1; then
        printf '%s\n' "$EDITOR"
    elif command -v nano >/dev/null 2>&1; then
        printf '%s\n' "nano"
    elif command -v vim >/dev/null 2>&1; then
        printf '%s\n' "vim"
    elif command -v vi >/dev/null 2>&1; then
        printf '%s\n' "vi"
    else
        printf '%s\n' ""
    fi
}

open_editor() {
    local f="$1" ed
    ed="$(editor_cmd)"
    if [ -z "$ed" ]; then
        msg_err "Editor tidak ditemukan. Install nano/vim atau set \$EDITOR."
        return 127
    fi
    # EDITOR may contain arguments (for example: "vim -f").
    # shellcheck disable=SC2086
    $ed -- "$f"
}

clipboard_backend() {
    if command -v termux-clipboard-set >/dev/null 2>&1; then
        printf '%s\n' "termux"
    elif command -v wl-copy >/dev/null 2>&1; then
        printf '%s\n' "wayland"
    elif command -v xclip >/dev/null 2>&1; then
        printf '%s\n' "xclip"
    elif command -v xsel >/dev/null 2>&1; then
        printf '%s\n' "xsel"
    else
        printf '%s\n' "none"
    fi
}

copy_stream_to_system_clipboard() {
    case "$(clipboard_backend)" in
        termux) termux-clipboard-set ;;
        wayland) wl-copy ;;
        xclip) xclip -selection clipboard ;;
        xsel) xsel --clipboard --input ;;
        *)
            msg_warn "Clipboard sistem tidak tersedia."
            if is_termux; then
                echo "   Termux: pkg install termux-api + aplikasi Termux:API"
            else
                echo "   Linux Wayland: install wl-clipboard"
                echo "   Linux X11    : install xclip atau xsel"
            fi
            return 127 ;;
    esac
}

dependency_hint() {
    local pm
    pm="$(package_manager)"
    case "$pm" in
        pkg)     echo "Jalankan: pkg install fzf bat tree file findutils coreutils gawk grep sed" ;;
        apt-get) echo "Jalankan: sudo apt update && sudo apt install fzf bat tree file findutils coreutils gawk grep sed" ;;
        dnf)     echo "Jalankan: sudo dnf install fzf bat tree file findutils coreutils gawk grep sed" ;;
        yum)     echo "Jalankan: sudo yum install fzf bat tree file findutils coreutils gawk grep sed" ;;
        pacman)  echo "Jalankan: sudo pacman -S fzf bat tree file findutils coreutils gawk grep sed" ;;
        zypper)  echo "Jalankan: sudo zypper install fzf bat tree file findutils coreutils gawk grep sed" ;;
        apk)     echo "Jalankan: sudo apk add bash fzf bat tree file findutils coreutils gawk grep sed" ;;
        xbps-install) echo "Jalankan: sudo xbps-install -S fzf bat tree file findutils coreutils gawk grep sed" ;;
        *)       echo "Install dependency: bash fzf bat/batcat tree file findutils coreutils gawk grep sed" ;;
    esac
}

check_dependencies() {
    local missing=() cmd
    for cmd in fzf tree file find stat du awk sed grep sort cut wc df; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    BAT_CMD="$(resolve_bat)"
    export TE_BAT="$BAT_CMD"
    [ -n "$BAT_CMD" ] || missing+=("bat/batcat")

    if [ "${#missing[@]}" -eq 0 ]; then
        return 0
    fi

    msg_err "Dependency belum tersedia: ${missing[*]}"
    dependency_hint
    echo "   Atau jalankan installer repo: ./install.sh"
    return 1
}

need_cmd() {
    local cmd="$1" pkg_name="${2:-$1}"
    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi
    msg_err "Command '$cmd' belum tersedia (paket: $pkg_name)."
    dependency_hint
    return 1
}

temp_dir() {
    local d
    if [ -n "${TMPDIR:-}" ]; then
        d="$TMPDIR"
    elif is_termux && [ -n "${PREFIX:-}" ]; then
        d="$PREFIX/tmp"
    else
        d="/tmp"
    fi
    mkdir -p "$d" 2>/dev/null || return 1
    printf '%s\n' "$d"
}

make_temp_file() {
    local td
    td="$(temp_dir)" || return 1
    mktemp "$td/.terminal-explorer.XXXXXX"
}

canonical_path() {
    local p="$1"
    if command -v realpath >/dev/null 2>&1; then
        realpath -m -- "$p" 2>/dev/null && return 0
    fi
    readlink -f -- "$p" 2>/dev/null && return 0
    printf '%s\n' "$p"
}

is_protected_path() {
    local p home_real prefix_real
    p="$(canonical_path "$1")"
    home_real="$(canonical_path "$HOME")"

    case "$p" in
        "/"|"/bin"|"/boot"|"/dev"|"/etc"|"/lib"|"/lib64"|"/proc"|"/root"|"/run"|"/sbin"|"/sys"|"/usr"|"/var")
            return 0 ;;
    esac

    [ "$p" = "$home_real" ] && return 0

    if is_termux && [ -n "${PREFIX:-}" ]; then
        prefix_real="$(canonical_path "$PREFIX")"
        case "$p" in
            "$prefix_real"|"$prefix_real/bin"|"$prefix_real/etc"|"$prefix_real/lib"|"$prefix_real/share")
                return 0 ;;
        esac
    fi
    return 1
}

validate_name() {
    local name="$1"
    case "$name" in
        ""|"."|".."|*/*|*$'\n'*|*$'\t'*)
            msg_err "Nama tidak valid. Gunakan satu nama tanpa '/' atau karakter kontrol."
            return 1 ;;
    esac
    return 0
}

safe_remove_path() {
    local target="$1"
    if is_protected_path "$target"; then
        msg_err "Path dilindungi dan tidak boleh dihapus: $target"
        return 1
    fi
    if [ -d "$target" ] && [ ! -L "$target" ]; then
        rm -rf -- "$target"
    else
        rm -f -- "$target"
    fi
}

copy_to_dir() {
    local src="$1" dest="$2" bn src_real dest_real target target_real
    [ -e "$src" ] || [ -L "$src" ] || { msg_err "Sumber tidak ditemukan"; return 1; }
    [ -d "$dest" ] || { msg_err "Folder tujuan tidak valid: $dest"; return 1; }

    src_real="$(canonical_path "$src")"
    dest_real="$(canonical_path "$dest")"
    bn="$(basename -- "$src")"
    target="$dest_real/$bn"
    target_real="$(canonical_path "$target")"

    if [ "$src_real" = "$target_real" ]; then
        msg_err "Sumber dan tujuan sama"
        return 1
    fi
    if [ -d "$src" ] && [[ "$dest_real" == "$src_real" || "$dest_real" == "$src_real/"* ]]; then
        msg_err "Folder tidak bisa dicopy ke dalam dirinya sendiri"
        return 1
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        confirm " Timpa '$bn' di $(basename -- "$dest_real")?" || return 1
        safe_remove_path "$target" || return 1
    fi

    cp -a -- "$src" "$dest_real/"
}

move_to_dir() {
    local src="$1" dest="$2" bn src_real dest_real target target_real
    [ -e "$src" ] || [ -L "$src" ] || { msg_err "Sumber tidak ditemukan"; return 1; }
    [ -d "$dest" ] || { msg_err "Folder tujuan tidak valid: $dest"; return 1; }

    src_real="$(canonical_path "$src")"
    dest_real="$(canonical_path "$dest")"
    bn="$(basename -- "$src")"
    target="$dest_real/$bn"
    target_real="$(canonical_path "$target")"

    if [ "$src_real" = "$target_real" ]; then
        msg_err "Sumber dan tujuan sama"
        return 1
    fi
    if [ -d "$src" ] && [[ "$dest_real" == "$src_real" || "$dest_real" == "$src_real/"* ]]; then
        msg_err "Folder tidak bisa dipindah ke dalam dirinya sendiri"
        return 1
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        confirm " Timpa '$bn' di $(basename -- "$dest_real")?" || return 1
        safe_remove_path "$target" || return 1
    fi

    mv -- "$src" "$dest_real/"
}

run_file() {
    local f="$1" first ext rc
    local -a interp=()

    if [ -x "$f" ]; then
        "$f"
        return $?
    fi

    IFS= read -r first < "$f" 2>/dev/null || first=""
    if [[ "$first" == '#!'* ]]; then
        read -r -a interp <<< "${first#\#!}"
        if [ "${#interp[@]}" -gt 0 ]; then
            "${interp[@]}" "$f"
            return $?
        fi
    fi

    ext="${f##*.}"
    ext="${ext,,}"
    case "$ext" in
        sh|bash) bash -- "$f" ;;
        py)      if command -v python3 >/dev/null; then python3 -- "$f"; else python -- "$f"; fi ;;
        js|mjs|cjs) need_cmd node nodejs || return 127; node -- "$f" ;;
        php)     need_cmd php php || return 127; php -- "$f" ;;
        rb)      need_cmd ruby ruby || return 127; ruby -- "$f" ;;
        *)       bash -- "$f" ;;
    esac
    rc=$?
    return "$rc"
}

show_doctor() {
    BAT_CMD="$(resolve_bat)"
    export TE_BAT="$BAT_CMD"

    echo "${APP_NAME} v${VERSION}"
    echo "Platform   : $(platform_name)"
    echo "Platform ID: $(platform_id)"
    echo "Package mgr: $(package_manager)"
    echo "Shell      : ${BASH_VERSION:-unknown}"
    echo "Home       : $HOME"
    echo "PREFIX     : ${PREFIX:-<unset>}"
    echo "TMPDIR     : ${TMPDIR:-<unset>}"
    echo "Config     : $CFG_DIR"
    echo "Termux     : $(is_termux && echo yes || echo no)"
    echo "bat command: ${BAT_CMD:-MISSING}"
    echo "Clipboard  : $(clipboard_backend)"
    echo ""
    echo "Required commands:"
    local cmd
    for cmd in fzf tree file find stat du awk sed grep sort cut wc df; do
        printf '  %-12s %s\n' "$cmd" "$(command -v "$cmd" 2>/dev/null || echo MISSING)"
    done
    printf '  %-12s %s\n' "bat/batcat" "${BAT_CMD:-MISSING}"
    echo ""
    echo "Optional commands:"
    for cmd in nano vim vi zip unzip tar gzip bzip2 xz git xxd xdg-open wl-copy xclip xsel termux-clipboard-set; do
        printf '  %-22s %s\n' "$cmd" "$(command -v "$cmd" 2>/dev/null || echo '-')"
    done
}

show_cli_help() {
    cat <<EOF
${APP_NAME} v${VERSION}

Usage:
  terminal-explorer [DIRECTORY]
  texplorer [DIRECTORY]
  terminal-explorer --doctor
  terminal-explorer --version
  terminal-explorer --help

Supported:
  - Termux / Android
  - Debian / Ubuntu
  - Fedora / RHEL
  - Arch / Manjaro
  - openSUSE
  - Alpine
  - Void Linux
  - Linux generic dengan dependency yang sesuai

Jika DIRECTORY diberikan, explorer langsung dibuka dari folder tersebut.
Untuk bantuan shortcut di dalam aplikasi, pilih [HELP].
EOF
}

# =============================================================
# TRANSISI FOLDER
# =============================================================

folder_transition() {
    local NAME; NAME="$(basename -- "$CURRENT_DIR")"
    [ -z "$NAME" ] && NAME="/"
    clear
    echo -e "${C_YLW}${BOLD}"
    echo "  ┌──────────────────────────────────┐"
    printf "  │  📂 %-32s│\n" "$NAME "
    echo "  └──────────────────────────────────┘"
    echo -e "${R}"
    sleep 0.07
}

# =============================================================
# LIST ITEMS (Menggunakan TAB sebagai pemisah tersembunyi)
# =============================================================

list_items() {
    echo -e "[BACK]\t⬅️  [BACK]"
    echo -e "[NEW FILE]\t📄+ [NEW FILE]"
    echo -e "[NEW FOLDER]\t📁+ [NEW FOLDER]"
    echo -e "[SEARCH]\t🔍  [SEARCH]"
    echo -e "[BOOKMARKS]\t🔖  [BOOKMARKS]"
    echo -e "[PASTE]\t📋  [PASTE]"
    echo -e "[HELP]\t❓  [HELP]"

    local HF=()
    [ "$SHOW_HIDDEN" -eq 0 ] && HF=("!" "-name" ".*")

    find "$CURRENT_DIR" -maxdepth 1 -mindepth 1 -type l \
        "${HF[@]}" -printf "%f\n" 2>/dev/null | sort \
        | while IFS= read -r f; do
            printf "%s\t\033[0;36m🔗 %s\033[0m\n" "$f" "$f"
          done

    find "$CURRENT_DIR" -maxdepth 1 -mindepth 1 -type d \
        "${HF[@]}" -printf "%f\n" 2>/dev/null | sort \
        | while IFS= read -r f; do
            CNT=$(find "$CURRENT_DIR/$f" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l)
            printf "%s\t\033[1;33m📁 \033[0m%-34s \033[2m[%s]\033[0m\n" "$f" "$f" "$CNT"
          done

    local FLIST
    case "$SORT_MODE" in
        size) FLIST=$(find "$CURRENT_DIR" -maxdepth 1 -mindepth 1 -type f \
                "${HF[@]}" -printf "%s\t%f\n" 2>/dev/null | sort -rn | cut -f2) ;;
        date) FLIST=$(find "$CURRENT_DIR" -maxdepth 1 -mindepth 1 -type f \
                "${HF[@]}" -printf "%T@\t%f\n" 2>/dev/null | sort -rn | cut -f2) ;;
        *)    FLIST=$(find "$CURRENT_DIR" -maxdepth 1 -mindepth 1 -type f \
                "${HF[@]}" -printf "%f\n" 2>/dev/null | sort) ;;
    esac
    printf '%s\n' "$FLIST" | while IFS= read -r f; do
        [ -z "$f" ] && continue
        SZ=$(du -sh "$CURRENT_DIR/$f" 2>/dev/null | cut -f1)
        printf "%s\t\033[1;34m📄 \033[0m%-34s \033[2m%s\033[0m\n" "$f" "$f" "$SZ"
    done
}

# =============================================================
# CHOOSE FOLDER
# =============================================================

choose_folder() {
    local PICK_DIR="${1:-$HOME}"
    local MAP CHOICE TARGET

    while true; do
        MAP=$(make_temp_file) || { msg_err "Gagal membuat file temporary"; sleep 1; return 1; }

        echo -e "⬅️  [BACK]\t__BACK__" >> "$MAP"
        find "$PICK_DIR" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" 2>/dev/null | sort | while IFS= read -r d; do
            printf "📁 %s\t%s/%s\n" "$d" "$PICK_DIR" "$d" >> "$MAP"
        done
        echo -e "✅  [PILIH INI]\t__SELECT__" >> "$MAP"

        CHOICE=$(fzf \
            --delimiter=$'\t' \
            --with-nth=1 \
            --height=100% \
            --layout=reverse \
            --border=rounded \
            --ansi \
            --pointer="▶" \
            --header=" 📂 $PICK_DIR" \
            --prompt=" Tujuan > " < "$MAP")

        [ -z "$CHOICE" ] && { rm -f "$MAP"; return 1; }

        TARGET=$(printf "%s" "$CHOICE" | awk -F'\t' '{print $2}')
        rm -f "$MAP"

        case "$TARGET" in
            __BACK__)
                [ "$PICK_DIR" != "/" ] && PICK_DIR="$(dirname "$PICK_DIR")" ;;
            __SELECT__)
                echo "$PICK_DIR"; return 0 ;;
            "")
                msg_err "Item tidak valid"; sleep 1 ;;
            *)
                [ -d "$TARGET" ] && PICK_DIR="$TARGET" ;;
        esac
    done
}

# =============================================================
# BOOKMARK
# =============================================================

bookmark_add() {
    local DIR="${1:-$CURRENT_DIR}"
    grep -qxF -- "$DIR" "$BOOKMARK_FILE" 2>/dev/null \
        && { msg_warn "Sudah ada di bookmark"; sleep 1; return; }
    printf '%s\n' "$DIR" >> "$BOOKMARK_FILE"
    msg_ok "Bookmark: $DIR"; sleep 1
}

bookmark_remove() {
    local DIR="${1:-$CURRENT_DIR}"
    grep -qxF -- "$DIR" "$BOOKMARK_FILE" 2>/dev/null \
        || { msg_warn "Tidak ada di bookmark"; sleep 1; return; }
    grep -vxF -- "$DIR" "$BOOKMARK_FILE" > "${BOOKMARK_FILE}.tmp"
    mv "${BOOKMARK_FILE}.tmp" "$BOOKMARK_FILE"
    msg_ok "Bookmark dihapus"; sleep 1
}

bookmarks_menu() {
    [ ! -s "$BOOKMARK_FILE" ] && { msg_warn "Belum ada bookmark"; sleep 1; return; }
    local PICK
    export TE_BOOKMARK_FILE="$BOOKMARK_FILE"
    PICK=$(cat "$BOOKMARK_FILE" | fzf \
        --height=60% --layout=reverse --border=rounded \
        --prompt=" 🔖 Bookmark > " \
        --header="Enter=Buka  Del=Hapus" \
        --bind='del:execute(grep -vxF -- {} "$TE_BOOKMARK_FILE" > "$TE_BOOKMARK_FILE.tmp" && mv "$TE_BOOKMARK_FILE.tmp" "$TE_BOOKMARK_FILE")+reload(cat "$TE_BOOKMARK_FILE")')
    [ -z "$PICK" ] && return
    [ -d "$PICK" ] && { CURRENT_DIR="$PICK"; folder_transition; }
}

# =============================================================
# SEARCH
# =============================================================

search_by_name() {
    stty sane
    echo -ne "${C_CYN} 🔍 Nama file (misal: *.sh): ${R}"
    read -r QUERY; [ -z "$QUERY" ] && return
    local RESULT
    RESULT=$(find "$CURRENT_DIR" -iname "*$QUERY*" 2>/dev/null | fzf \
        --height=80% --layout=reverse --border=rounded \
        --ansi --prompt=" 🔍 Hasil > " \
        --preview='[ -d "{}" ] \
            && tree -L 2 -C "{}" | head -30 \
            || "${TE_BAT:-bat}" --color=always --style=numbers "{}" 2>/dev/null || cat "{}"')
    [ -z "$RESULT" ] && return
    if   [ -d "$RESULT" ]; then CURRENT_DIR="$RESULT"; folder_transition
    elif [ -f "$RESULT" ]; then CURRENT_DIR="$(dirname "$RESULT")"; file_action "$RESULT"
    fi
}

search_by_content() {
    stty sane
    echo -ne "${C_CYN} 🔍 Kata kunci isi file: ${R}"
    read -r QUERY; [ -z "$QUERY" ] && return
    local RESULT
    export TE_SEARCH_QUERY="$QUERY"
    RESULT=$(grep -rIl -- "$QUERY" "$CURRENT_DIR" 2>/dev/null | fzf \
        --height=80% --layout=reverse --border=rounded \
        --ansi --prompt=" 🔍 Grep > " \
        --preview='grep -n --color=always -- "$TE_SEARCH_QUERY" {} 2>/dev/null | head -50')
    [ -n "$RESULT" ] && [ -f "$RESULT" ] && file_action "$RESULT"
}

# =============================================================
# CLIPBOARD INTERNAL (Ditingkatkan untuk mendukung paste ke folder spesifik)
# =============================================================

cb_copy() { CB_FILE="$1"; CB_OP="copy"; msg_ok "Copy: $(basename -- "$1")"; sleep 0.6; }
cb_cut()  { CB_FILE="$1"; CB_OP="cut";  msg_ok "Cut:  $(basename -- "$1")"; sleep 0.6; }

cb_paste() {
    local TGT_DIR="${1:-$CURRENT_DIR}"
    if [ -z "$CB_FILE" ]; then
        msg_warn "Clipboard kosong"; sleep 1; return
    fi
    if [ ! -e "$CB_FILE" ] && [ ! -L "$CB_FILE" ]; then
        msg_err "Sumber sudah tidak ada"; CB_FILE=""; CB_OP=""; sleep 1; return
    fi
    [ -d "$TGT_DIR" ] || { msg_err "Folder tujuan tidak valid"; sleep 1; return; }

    if [ "$CB_OP" = "copy" ]; then
        if copy_to_dir "$CB_FILE" "$TGT_DIR"; then
            msg_ok "Dicopy ke: $(basename -- "$TGT_DIR")"
        else
            msg_warn "Copy dibatalkan/gagal"
        fi
    elif [ "$CB_OP" = "cut" ]; then
        if move_to_dir "$CB_FILE" "$TGT_DIR"; then
            msg_ok "Dipindah ke: $(basename -- "$TGT_DIR")"
            CB_FILE=""; CB_OP=""
        else
            msg_warn "Pemindahan dibatalkan/gagal"
        fi
    else
        msg_err "State clipboard tidak valid"
        CB_FILE=""; CB_OP=""
    fi
    sleep 0.7
}


# =============================================================
# CHMOD MENU
# =============================================================

chmod_menu() {
    local FILE="$1"
    local CPERM; CPERM=$(stat -c "%a %A" "$FILE" 2>/dev/null)

    while true; do
        clear
        echo -e "${C_MAG}${BOLD} 🔐 CHMOD — $(basename "$FILE")${R}"
        echo -e "${DIM}    Saat ini: $CPERM${R}"
        echo
        echo "   1)  +x       tambah executable"
        echo "   2)  600      owner RW only"
        echo "   3)  644      owner RW, others R"
        echo "   4)  700      owner RWX only"
        echo "   5)  755      owner RWX, others RX"
        echo "   6)  777      semua RWX ⚠️"
        echo "   c)  Custom"
        echo "   b)  Back"
        echo
        echo -ne " Pilih: "; IFS= read -rsn1 C; echo

        local MODE=""
        case "$C" in
            1) MODE="+x" ;;
            2) MODE="600" ;;
            3) MODE="644" ;;
            4) MODE="700" ;;
            5) MODE="755" ;;
            6) confirm " chmod 777 berbahaya! Lanjut?" && MODE="777" ;;
            c)
                echo -ne " Mode: "; read -r MODE
                if [[ ! "$MODE" =~ ^([0-7]{3,4}|[ugoa]*[+=-][rwxXstugo,]+)$ ]]; then
                    msg_err "Mode chmod tidak valid"
                    MODE=""
                    sleep 1
                fi ;;
            b) return ;;
        esac
        if [ -n "$MODE" ]; then
            chmod -- "$MODE" "$FILE" \
                && { CPERM=$(stat -c "%a %A" "$FILE" 2>/dev/null); msg_ok "chmod $MODE → $CPERM"; sleep 0.8; break; } \
                || { msg_err "Gagal"; sleep 1; }
        fi
    done
}

# =============================================================
# FILE INFO & FOLDER INFO
# =============================================================

show_file_info() {
    local F="$1"; clear
    echo -e "${C_CYN}${BOLD} 📊 INFO FILE${R}"; echo
    echo -e "  ${C_BLU}Nama   :${R} $(basename "$F")"
    echo -e "  ${C_BLU}Path   :${R} $F"
    echo -e "  ${C_BLU}Ukuran :${R} $(du -sh "$F" 2>/dev/null | cut -f1)"
    echo -e "  ${C_BLU}Tipe   :${R} $(file -b "$F" 2>/dev/null)"
    echo -e "  ${C_BLU}Perm   :${R} $(stat -c '%A (%a)' "$F" 2>/dev/null)"
    echo -e "  ${C_BLU}Owner  :${R} $(stat -c '%U:%G' "$F" 2>/dev/null)"
    echo -e "  ${C_BLU}Diubah :${R} $(stat -c '%y' "$F" 2>/dev/null | cut -d'.' -f1)"
    echo -e "  ${C_BLU}Baris  :${R} $(wc -l < "$F" 2>/dev/null)"
    echo -e "  ${C_BLU}Kata   :${R} $(wc -w < "$F" 2>/dev/null)"
    echo; pause
}

show_folder_info() {
    local D="$1"; clear
    echo -e "${C_CYN}${BOLD} 📊 INFO FOLDER${R}"; echo
    echo -e "  ${C_YLW}Nama   :${R} $(basename "$D")"
    echo -e "  ${C_YLW}Path   :${R} $D"
    echo -e "  ${C_YLW}Ukuran :${R} $(du -sh "$D" 2>/dev/null | cut -f1)"
    echo -e "  ${C_YLW}Total  :${R} $(find "$D" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l) item"
    echo -e "  ${C_YLW}Folder :${R} $(find "$D" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)"
    echo -e "  ${C_YLW}File   :${R} $(find "$D" -maxdepth 1 -mindepth 1 -type f 2>/dev/null | wc -l)"
    echo -e "  ${C_YLW}Perm   :${R} $(stat -c '%A (%a)' "$D" 2>/dev/null)"
    echo -e "  ${C_YLW}Diubah :${R} $(stat -c '%y' "$D" 2>/dev/null | cut -d'.' -f1)"
    if command -v git >/dev/null && git -C "$D" rev-parse --git-dir >/dev/null 2>&1; then
        echo; echo -e "  ${C_GRN}Git Repo:${R}"
        echo -e "  ${C_GRN}Branch :${R} $(git -C "$D" branch --show-current 2>/dev/null)"
        echo -e "  ${C_GRN}Changes:${R} $(git -C "$D" status --short 2>/dev/null | wc -l) file"
    fi
    echo; pause
}

# =============================================================
# COMPRESS / EXTRACT
# =============================================================

is_archive() {
    case "${1,,}" in
        *.zip|*.tar.gz|*.tgz|*.tar.bz2|*.tar.xz|*.tar|*.gz|*.bz2) return 0 ;;
        *) return 1 ;;
    esac
}

archive_paths_safe() {
    local file="$1" entry clean
    case "${file,,}" in
        *.zip)
            need_cmd unzip unzip || return 1
            while IFS= read -r entry; do
                clean="${entry#./}"
                case "$clean" in
                    /*|..|../*|*/../*|[A-Za-z]:/*) return 1 ;;
                esac
            done < <(unzip -Z1 -- "$file" 2>/dev/null)
            ;;
        *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tar.xz)
            need_cmd tar tar || return 1
            while IFS= read -r entry; do
                clean="${entry#./}"
                case "$clean" in
                    /*|..|../*|*/../*|[A-Za-z]:/*) return 1 ;;
                esac
            done < <(tar -tf "$file" 2>/dev/null)
            ;;
    esac
    return 0
}

compress_item() {
    local TARGET="$1"
    local BN; BN="$(basename -- "$TARGET")"
    stty sane
    echo -e "${C_CYN} Format:${R}  1) zip   2) tar.gz   3) tar.bz2"
    echo -ne " Pilih: "; IFS= read -rsn1 FMT; echo
    echo -ne "${C_CYN} Nama output (kosong=$BN): ${R}"; read -r ON
    ON="${ON:-$BN}"
    validate_name "$ON" || { sleep 1; return; }

    local OUT OK=1 PARENT
    PARENT="$(dirname -- "$TARGET")"
    case "$FMT" in
        1)
            need_cmd zip zip || { sleep 1; return; }
            OUT="$CURRENT_DIR/${ON}.zip" ;;
        2)
            need_cmd tar tar || { sleep 1; return; }
            OUT="$CURRENT_DIR/${ON}.tar.gz" ;;
        3)
            need_cmd tar tar || { sleep 1; return; }
            need_cmd bzip2 bzip2 || { sleep 1; return; }
            OUT="$CURRENT_DIR/${ON}.tar.bz2" ;;
        *) return ;;
    esac

    if [ -e "$OUT" ]; then
        confirm " Timpa '$(basename -- "$OUT")'?" || return
        rm -f -- "$OUT" || { msg_err "Gagal menghapus output lama"; sleep 1; return; }
    fi

    case "$FMT" in
        1) (cd "$PARENT" && zip -qr "$OUT" "$BN") && OK=0 ;;
        2) tar -czf "$OUT" -C "$PARENT" "$BN" && OK=0 ;;
        3) tar -cjf "$OUT" -C "$PARENT" "$BN" && OK=0 ;;
    esac

    [ "$OK" -eq 0 ] && msg_ok "Dibuat: $(basename -- "$OUT")" \
        || { msg_err "Gagal kompres"; rm -f -- "$OUT"; }
    sleep 1
}

extract_archive() {
    local FILE="$1"
    stty sane
    echo -ne "${C_CYN} Ekstrak ke (kosong=di sini): ${R}"; read -r DEST
    if [ -z "$DEST" ]; then
        DEST="$CURRENT_DIR"
    elif [[ "$DEST" != /* ]]; then
        DEST="$CURRENT_DIR/$DEST"
    fi
    DEST="$(canonical_path "$DEST")"
    mkdir -p -- "$DEST" || { msg_err "Gagal membuat folder tujuan"; sleep 1; return; }

    case "${FILE,,}" in
        *.zip|*.tar.gz|*.tgz|*.tar.bz2|*.tar.xz|*.tar)
            if ! archive_paths_safe "$FILE"; then
                msg_err "Archive mengandung path tidak aman (absolute/../). Ekstraksi dibatalkan."
                sleep 1.5
                return
            fi ;;
    esac

    local RC=1 BASE OUTFILE
    case "${FILE,,}" in
        *.zip)
            need_cmd unzip unzip || { sleep 1; return; }
            unzip -o -- "$FILE" -d "$DEST"; RC=$? ;;
        *.tar.gz|*.tgz)
            need_cmd tar tar || { sleep 1; return; }
            tar -xzf "$FILE" -C "$DEST"; RC=$? ;;
        *.tar.bz2)
            need_cmd tar tar || { sleep 1; return; }
            need_cmd bzip2 bzip2 || { sleep 1; return; }
            tar -xjf "$FILE" -C "$DEST"; RC=$? ;;
        *.tar.xz)
            need_cmd tar tar || { sleep 1; return; }
            need_cmd xz xz-utils || { sleep 1; return; }
            tar -xJf "$FILE" -C "$DEST"; RC=$? ;;
        *.tar)
            need_cmd tar tar || { sleep 1; return; }
            tar -xf "$FILE" -C "$DEST"; RC=$? ;;
        *.gz)
            need_cmd gzip gzip || { sleep 1; return; }
            BASE="$(basename -- "$FILE" .gz)"; OUTFILE="$DEST/$BASE"
            if [ -e "$OUTFILE" ] && ! confirm " Timpa '$BASE'?"; then return; fi
            gzip -dc -- "$FILE" > "$OUTFILE"; RC=$? ;;
        *.bz2)
            need_cmd bzip2 bzip2 || { sleep 1; return; }
            BASE="$(basename -- "$FILE" .bz2)"; OUTFILE="$DEST/$BASE"
            if [ -e "$OUTFILE" ] && ! confirm " Timpa '$BASE'?"; then return; fi
            bzip2 -dc -- "$FILE" > "$OUTFILE"; RC=$? ;;
        *) msg_err "Format tidak didukung"; sleep 1; return ;;
    esac

    [ "$RC" -eq 0 ] && msg_ok "Diekstrak ke: $DEST" || msg_err "Gagal ekstrak"
    sleep 1
}


# =============================================================
# FILE ACTION MENU
# =============================================================

file_action() {
    local FILE="$1"
    [ ! -e "$FILE" ] && { msg_err "File tidak ditemukan"; sleep 1; return; }
    local FN; FN="$(basename "$FILE")"

    while true; do
        stty sane; clear
        echo -e "${C_BLU}${BOLD} 📄 $FN${R}"
        echo -e "${DIM}    $(stat -c '%A | %s bytes | %y' "$FILE" 2>/dev/null | cut -d'.' -f1)${R}"
        echo
        echo "   e)  Edit          (nano)"
        echo "   v)  Preview       (bat)"
        echo "   r)  Jalankan"
        echo "   i)  Info detail"
        echo "   p)  Permission    (chmod)"
        echo "   ─────────────────────────"
        echo "   y)  Copy ke clipboard"
        echo "   u)  Cut  ke clipboard"
        echo "   c)  Copy ke folder..."
        echo "   m)  Pindah ke folder..."
        echo "   n)  Rename"
        echo "   d)  Hapus"
        echo "   ─────────────────────────"
        echo "   x)  Copy isi → clipboard"
        echo "   h)  Kosongkan isi"
        echo "   z)  Kompres"
        is_archive "$FILE" && echo "   k)  Ekstrak"
        echo "   ─────────────────────────"
        echo "   b)  Back"
        echo
        echo -ne "${C_CYN} Action: ${R}"
        IFS= read -rsn1 ACT; echo

        case "$ACT" in
            e)
                need_cmd nano nano || { sleep 1; continue; }
                nano -- "$FILE" ;;
            v)
                "$BAT_CMD" --color=always --style=full "$FILE" 2>/dev/null \
                    || { file -b "$FILE" | grep -qi "text" && cat "$FILE" \
                         || msg_warn "File binary, gunakan hex viewer"; }
                echo; pause ;;
            r)
                clear
                echo -e "${C_GRN}${BOLD} ▶ Menjalankan: $FN${R}"
                echo " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                run_file "$FILE"
                local RUN_RC=$?
                echo " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                if [ "$RUN_RC" -eq 0 ]; then
                    echo -e "${C_GRN} Selesai (exit: $RUN_RC)${R}"
                else
                    echo -e "${C_RED} Selesai (exit: $RUN_RC)${R}"
                fi
                pause ;;
            i) show_file_info "$FILE" ;;
            p) chmod_menu "$FILE" ;;
            y) cb_copy "$FILE" ;;
            u) cb_cut  "$FILE" ;;
            c)
                local DEST; DEST=$(choose_folder) || continue
                copy_to_dir "$FILE" "$DEST" && msg_ok "Dicopy ke: $DEST" || msg_err "Gagal/dibatalkan"
                sleep 1 ;;
            m)
                local DEST; DEST=$(choose_folder) || continue
                move_to_dir "$FILE" "$DEST" && msg_ok "Dipindah" && sleep 0.8 && return \
                    || { msg_err "Gagal/dibatalkan"; sleep 1; } ;;
            n)
                stty sane
                echo -ne "${C_CYN} Nama baru: ${R}"; read -r NEW
                validate_name "$NEW" || { sleep 1; continue; }
                local NP; NP="$(dirname -- "$FILE")/$NEW"
                if [ -e "$NP" ] || [ -L "$NP" ]; then
                    confirm " Timpa '$NEW'?" || continue
                    safe_remove_path "$NP" || { sleep 1; continue; }
                fi
                mv -- "$FILE" "$NP" && msg_ok "Renamed → $NEW" && FILE="$NP" \
                    || msg_err "Gagal rename"
                sleep 0.8; return ;;
            d)
                confirm " Hapus '$FN'?" && safe_remove_path "$FILE" \
                    && msg_ok "Dihapus" && sleep 0.8 && return ;;
            x)
                if copy_stream_to_system_clipboard < "$FILE"; then
                    msg_ok "Isi disalin ke clipboard sistem"
                fi
                echo; pause ;;
            h)
                confirm " Kosongkan '$FN'?" && : > "$FILE" && msg_ok "Dikosongkan"
                sleep 0.8 ;;
            z) compress_item "$FILE" ;;
            k) is_archive "$FILE" && extract_archive "$FILE" ;;
            b) return ;;
        esac
    done
}

# =============================================================
# FOLDER ACTION MENU (Telah disejajarkan dengan opsi pada file)
# =============================================================

folder_action() {
    local DIR="$1"
    [ ! -d "$DIR" ] && { msg_err "Folder tidak ditemukan"; sleep 1; return; }
    local DN; DN="$(basename "$DIR")"

    while true; do
        stty sane; clear
        echo -e "${C_YLW}${BOLD} 📁 $DN${R}"
        echo -e "${DIM}    $DIR${R}"
        echo
        echo "   e)  Masuk / Buka folder"
        echo "   i)  Info detail"
        echo "   p)  Permission    (chmod)"
        echo "   ─────────────────────────"
        echo "   y)  Copy ke clipboard"
        echo "   u)  Cut  ke clipboard"
        echo "   v)  Paste ke dalam folder ini"
        echo "   c)  Copy ke folder..."
        echo "   m)  Pindah ke folder..."
        echo "   n)  Rename"
        echo "   d)  Hapus folder"
        echo "   ─────────────────────────"
        echo "   z)  Kompres folder"
        echo "   +)  Tambah ke bookmark"
        echo "   -)  Hapus dari bookmark"
        echo "   ─────────────────────────"
        echo "   b)  Back"
        echo
        echo -ne "${C_CYN} Action: ${R}"
        IFS= read -rsn1 ACT; echo

        case "$ACT" in
            e) 
                CURRENT_DIR="$DIR"
                folder_transition
                return ;;
            i) show_folder_info "$DIR" ;;
            p) chmod_menu "$DIR" ;;
            y) cb_copy "$DIR" ;;
            u) cb_cut  "$DIR" ;;
            v) cb_paste "$DIR" ;;
            c)
                local DEST; DEST=$(choose_folder) || continue
                copy_to_dir "$DIR" "$DEST" && msg_ok "Dicopy" || msg_err "Gagal/dibatalkan"
                sleep 1 ;;
            m)
                local DEST; DEST=$(choose_folder) || continue
                move_to_dir "$DIR" "$DEST" && msg_ok "Dipindah" && sleep 0.8 && return \
                    || { msg_err "Gagal/dibatalkan"; sleep 1; } ;;
            n)
                stty sane
                echo -ne "${C_CYN} Nama baru: ${R}"; read -r NEW
                validate_name "$NEW" || { sleep 1; continue; }
                local NP; NP="$(dirname -- "$DIR")/$NEW"
                if [ -e "$NP" ] || [ -L "$NP" ]; then
                    confirm " Timpa '$NEW'?" || continue
                    safe_remove_path "$NP" || { sleep 1; continue; }
                fi
                mv -- "$DIR" "$NP" && msg_ok "Renamed → $NEW" && DIR="$NP" \
                    || msg_err "Gagal"
                sleep 0.8; return ;;
            d)
                local CNT; CNT=$(find "$DIR" -mindepth 1 2>/dev/null | wc -l)
                confirm " Hapus '$DN' ($CNT item)?" \
                    && safe_remove_path "$DIR" && msg_ok "Dihapus" && sleep 0.8 && return ;;
            z) compress_item "$DIR" ;;
            +) bookmark_add "$DIR" ;;
            -) bookmark_remove "$DIR" ;;
            b) return ;;
        esac
    done
}

# =============================================================
# SORT MENU
# =============================================================

sort_menu() {
    stty sane; clear
    echo -e "${C_CYN}${BOLD} 📊 Sort & Tampilan${R}"; echo
    echo "  1) Nama A-Z    $([ "$SORT_MODE" = "name" ] && echo -e "${C_GRN}← aktif${R}")"
    echo "  2) Ukuran ↓    $([ "$SORT_MODE" = "size" ] && echo -e "${C_GRN}← aktif${R}")"
    echo "  3) Terbaru ↓   $([ "$SORT_MODE" = "date" ] && echo -e "${C_GRN}← aktif${R}")"
    echo
    echo "  h) Hidden: $([ "$SHOW_HIDDEN" -eq 1 ] \
        && echo -e "${C_GRN}TAMPIL${R}" || echo -e "${DIM}tersembunyi${R}")"
    echo
    echo -ne " Pilih: "; IFS= read -rsn1 S; echo
    case "$S" in
        1) SORT_MODE="name" ;;
        2) SORT_MODE="size" ;;
        3) SORT_MODE="date" ;;
        h) SHOW_HIDDEN=$(( 1 - SHOW_HIDDEN )) ;;
    esac
}

# =============================================================
# HELP
# =============================================================

show_help() {
    clear
    echo -e "${C_YLW}${BOLD} ❓ BANTUAN — Terminal Explorer v${VERSION}${R}"
    echo
    echo -e "${C_CYN} NAVIGASI${R}"
    echo "  Enter       masuk folder / aksi file"
    echo "  Alt+Enter   buka folder action menu"
    echo "  Esc         keluar"
    echo
    echo -e "${C_CYN} SHORTCUT FZF${R}"
    echo "  Ctrl+H      toggle hidden files"
    echo "  Ctrl+S      menu sort & tampilan"
    echo "  Ctrl+B      buka bookmark"
    echo "  Ctrl+F      cari nama file"
    echo "  Ctrl+G      grep isi file"
    echo "  Ctrl+A      bookmark folder ini"
    echo
    echo -e "${C_CYN} MENU LIST${R}"
    echo "  ⬅️  [BACK]       naik satu level"
    echo "  📄+ [NEW FILE]   buat file baru"
    echo "  📁+ [NEW FOLDER] buat folder baru"
    echo "  🔍  [SEARCH]     cari nama/konten"
    echo "  🔖  [BOOKMARKS]  kelola bookmark"
    echo "  📋  [PASTE]      paste clipboard"
    echo
    echo -e "${C_CYN} IKON${R}"
    echo "  📁 = Folder    📄 = File    🔗 = Symlink"
    echo
    echo -e "${C_CYN} FILE ACTIONS${R}"
    echo "  e=edit  v=preview  r=run    i=info  p=chmod"
    echo "  y=copy  u=cut      c=copy>  m=move> n=rename"
    echo "  d=hapus z=kompres  k=ekstrak x=clipboard"
    echo
    pause
}

# =============================================================
# CLI / STARTUP
# =============================================================

case "${1:-}" in
    -V|--version)
        echo "${APP_NAME} v${VERSION}"
        exit 0 ;;
    -h|--help)
        show_cli_help
        exit 0 ;;
    --doctor)
        show_doctor
        exit 0 ;;
    --*)
        msg_err "Opsi tidak dikenal: $1"
        echo "Gunakan --help"
        exit 2 ;;
esac

check_dependencies || exit 1
BAT_CMD="$(resolve_bat)"
export TE_BAT="$BAT_CMD"

if ! is_termux && ! is_linux; then
    msg_err "Platform ini belum didukung. Gunakan Termux atau Linux."
    exit 3
fi

if [ -n "${1:-}" ]; then
    if [ -d "$1" ]; then
        CURRENT_DIR="$(canonical_path "$1")"
    elif [ -f "$1" ]; then
        _START_FILE="$(canonical_path "$1")"
        CURRENT_DIR="$(dirname -- "$_START_FILE")"
        file_action "$_START_FILE"
    else
        msg_err "Path awal tidak ditemukan: $1"
        exit 2
    fi
fi

# =============================================================
# MAIN LOOP
# =============================================================

while true; do

    _lp=$(echo "$CURRENT_DIR" | sed "s|$HOME|~|")
    _cnt=$(find "$CURRENT_DIR" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l)
    _free=$(df -h "$CURRENT_DIR" 2>/dev/null | tail -1 | awk '{print $4}')
    _hid=$([ "$SHOW_HIDDEN" -eq 1 ] && echo "H:ON" || echo "h:off")
    _srt="s:${SORT_MODE}"
    _cb=$([ -n "$CB_FILE" ] && echo " | 📋$(basename "$CB_FILE")(${CB_OP})" || echo "")
    HDR1=" ${_lp}  [${_cnt}]  💾${_free}  ${_hid}  ${_srt}${_cb}"
    HDR2=" ^H=hidden  ^S=sort  ^B=bookmark  ^F=find  ^G=grep  ^A=+bm  Alt+↵=folder-menu"

    # Preview memakai environment variables agar path dengan spasi/quote tetap aman.
    export TE_CURRENT_DIR="$CURRENT_DIR"
    export TE_BOOKMARK_FILE="$BOOKMARK_FILE"
    export TE_CB_FILE="$CB_FILE"
    export TE_CB_OP="$CB_OP"

    # fzf hanya menampilkan kolom 2, sementara kolom 1 menyimpan nama asli item.
    RAW=$(list_items | fzf \
        --delimiter=$'\t' \
        --with-nth=2 \
        --height=100% \
        --layout=reverse \
        --border=rounded \
        --ansi \
        --pointer="▶" \
        --marker="✓" \
        --prompt=" ❯ " \
        --color="hl:bold:yellow,hl+:bold:yellow,header:cyan,pointer:green,marker:green,border:cyan,preview-border:gray" \
        --header="${HDR1}"$'\n'"${HDR2}" \
        --expect="alt-enter,ctrl-h,ctrl-s,ctrl-b,ctrl-f,ctrl-g,ctrl-a" \
        --preview-window="right:55%:border-rounded:wrap" \
        --preview='
RAW_NAME={1}
DIR="$TE_CURRENT_DIR"
FULL="$DIR/$RAW_NAME"
SEP="\033[2m─────────────────────────────────────────\033[0m"

# ─── Menu items ──────────────────────────────────────────────
case "$RAW_NAME" in
    "[BACK]")
        PARENT=$(dirname "$TE_CURRENT_DIR")
        echo -e "\033[1;33m ⬅  Naik ke:\033[0m"
        echo "    $PARENT"
        echo -e "$SEP"
        tree -L 1 --dirsfirst -C "$PARENT" 2>/dev/null | head -25
        exit ;;
    "[NEW FILE]")
        echo -e "\033[1;34m 📄 Buat File Baru\033[0m"
        echo "    Di: $TE_CURRENT_DIR"
        exit ;;
    "[NEW FOLDER]")
        echo -e "\033[1;34m 📁 Buat Folder Baru\033[0m"
        echo "    Di: $TE_CURRENT_DIR"
        exit ;;
    "[SEARCH]")
        echo -e "\033[1;36m 🔍 Pencarian\033[0m"
        echo "    Ctrl+F = cari nama file"
        echo "    Ctrl+G = cari isi file"
        exit ;;
    "[BOOKMARKS]")
        echo -e "\033[1;35m 🔖 Bookmarks\033[0m"
        echo -e "$SEP"
        BF="$TE_BOOKMARK_FILE"
        [ -s "$BF" ] && cat "$BF" || echo "    (belum ada bookmark)"
        exit ;;
    "[PASTE]")
        echo -e "\033[1;32m 📋 Clipboard Internal\033[0m"
        echo -e "$SEP"
        CB="$TE_CB_FILE"
        OP="$TE_CB_OP"
        if [ -n "$CB" ]; then
            echo "    Op   : $OP"
            echo "    File : $(basename "$CB")"
            echo "    Dari : $(dirname "$CB")"
        else
            echo "    Kosong — pilih file lalu y(copy)/u(cut)"
        fi
        exit ;;
    "[HELP]")
        echo -e "\033[1;33m ❓ Bantuan Cepat\033[0m"
        echo -e "$SEP"
        echo "    Enter     = masuk folder / aksi file"
        echo "    Alt+Enter = folder action menu"
        echo "    Ctrl+H    = toggle hidden"
        echo "    Ctrl+S    = sort menu"
        echo "    Ctrl+B    = bookmarks"
        echo "    Ctrl+F    = cari nama"
        echo "    Ctrl+G    = grep isi"
        echo "    Ctrl+A    = bookmark folder ini"
        exit ;;
esac

# ─── Symlink ─────────────────────────────────────────────────
if [ -L "$FULL" ]; then
    LTGT=$(readlink "$FULL")
    LREAL=$(readlink -f "$FULL" 2>/dev/null)
    echo -e "\033[0;36m╭─ 🔗 INFO SYMLINK\033[0m"
    echo -e "\033[0;36m│\033[0m  Nama   : $RAW_NAME"
    echo -e "\033[0;36m│\033[0m  Target : \033[2m$LTGT\033[0m"
    echo -e "\033[0;36m╰──────────────────────────\033[0m\n"
    if [ -f "$LREAL" ]; then
        "$BAT_CMD" --color=always --style=numbers "$LREAL" 2>/dev/null | head -40 \
            || cat "$LREAL" 2>/dev/null | head -40
    elif [ -d "$LREAL" ]; then
        tree -L 2 --dirsfirst -C "$LREAL" 2>/dev/null | head -30
    else
        echo -e "    \033[1;31mBroken link\033[0m"
    fi

# ─── Folder (Tampilan Detail Box & Tree) ─────────────────────
elif [ -d "$FULL" ]; then
    FSZ=$(du -sh "$FULL" 2>/dev/null | cut -f1)
    FTOT=$(find "$FULL" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l)
    FDT=$(stat -c "%y" "$FULL" 2>/dev/null | cut -d. -f1)

    echo -e "\033[1;33m╭─ 📁 INFO FOLDER\033[0m"
    printf "\033[1;33m│\033[0m \033[2m%-8s\033[0m %s\n" "Ukuran" "$FSZ"
    printf "\033[1;33m│\033[0m \033[2m%-8s\033[0m %s item\n" "Isi" "$FTOT"
    printf "\033[1;33m│\033[0m \033[2m%-8s\033[0m %s\n" "Diubah" "$FDT"
    if command -v git >/dev/null 2>&1 && git -C "$FULL" rev-parse --git-dir >/dev/null 2>&1; then
        GBR=$(git -C "$FULL" branch --show-current 2>/dev/null)
        echo -e "\033[1;33m│\033[0m \033[2m%-8s\033[0m \033[1;32m$GBR\033[0m" "Branch"
    fi
    echo -e "\033[1;33m╰────────────────────────\033[0m\n"

    echo -e "\033[1;34m$FULL\033[0m"
    tree -a -L 2 --dirsfirst -C --noreport "$FULL" 2>/dev/null | tail -n +2 | head -35

# ─── File ────────────────────────────────────────────────────
elif [ -f "$FULL" ]; then
    FSZ=$(du -sh "$FULL" 2>/dev/null | cut -f1)
    FDT=$(stat -c "%y" "$FULL" 2>/dev/null | cut -d. -f1)
    FTP=$(file -b "$FULL" 2>/dev/null)
    FLN=$(wc -l < "$FULL" 2>/dev/null)
    
    echo -e "\033[1;34m╭─ 📄 INFO FILE\033[0m"
    printf "\033[1;34m│\033[0m \033[2m%-8s\033[0m %s\n" "Ukuran"  "$FSZ"
    printf "\033[1;34m│\033[0m \033[2m%-8s\033[0m %s baris\n" "Isi" "$FLN"
    printf "\033[1;34m│\033[0m \033[2m%-8s\033[0m %s\n" "Tipe"    "$FTP"
    echo -e "\033[1;34m╰────────────────────────\033[0m\n"
    
    "$BAT_CMD" --color=always --style=numbers,changes,snip "$FULL" 2>/dev/null || {
        echo "$FTP" | grep -qi "text" \
            && cat "$FULL" \
            || { echo -e "    \033[2m[binary]\033[0m"
                 xxd "$FULL" 2>/dev/null | head -16; }
    }

# ─── Tidak ditemukan ─────────────────────────────────────────
else
    echo -e "\033[1;31m ⚠  Tidak ditemukan\033[0m"
    echo "    $FULL"
fi
')

    [ -z "$RAW" ] && { clear; echo -e "${C_YLW} Keluar dari Terminal Explorer v${VERSION}.${R}"; exit 0; }

    KEY=$(printf '%s\n' "$RAW" | head -1)
    SELECTED=$(printf '%s\n' "$RAW" | tail -1)
    [ -z "$SELECTED" ] && continue

    case "$KEY" in
        ctrl-h) SHOW_HIDDEN=$(( 1 - SHOW_HIDDEN )); continue ;;
        ctrl-s) sort_menu; continue ;;
        ctrl-b) bookmarks_menu; continue ;;
        ctrl-f) search_by_name; continue ;;
        ctrl-g) search_by_content; continue ;;
        ctrl-a) bookmark_add "$CURRENT_DIR"; continue ;;
    esac

    # ── EKSTRAKSI 100% AMAN ──
    # Mengambil persis dari kolom pertama yang sengaja disembunyikan fzf
    ITEM=$(printf "%s" "$SELECTED" | awk -F'\t' '{print $1}')
    FULL="$CURRENT_DIR/$ITEM"

    case "$ITEM" in
        "[BACK]")
            PARENT="$(dirname -- "$CURRENT_DIR")"
            [ "$PARENT" = "$CURRENT_DIR" ] && continue
            CURRENT_DIR="$PARENT"; folder_transition; continue ;;
        "[NEW FILE]")
            stty sane
            echo -ne "${C_CYN} 📄 Nama file baru: ${R}"; read -r _NM
            validate_name "$_NM" || { sleep 1; continue; }
            _T="$CURRENT_DIR/$_NM"
            [ -e "$_T" ] && { msg_err "Sudah ada!"; sleep 1; continue; }
            if touch -- "$_T"; then
                if need_cmd nano nano; then
                    nano -- "$_T"
                else
                    msg_warn "File dibuat tanpa membuka editor: $_NM"
                    sleep 1
                fi
            fi
            continue ;;
        "[NEW FOLDER]")
            stty sane
            echo -ne "${C_CYN} 📁 Nama folder baru: ${R}"; read -r _NM
            validate_name "$_NM" || { sleep 1; continue; }
            [ -e "$CURRENT_DIR/$_NM" ] && { msg_err "Sudah ada!"; sleep 1; continue; }
            mkdir -- "$CURRENT_DIR/$_NM" && msg_ok "Dibuat: $_NM"; sleep 0.6
            continue ;;
        "[SEARCH]")
            stty sane; clear
            echo -e "${C_CYN} Cari: 1) Nama file   2) Isi file${R}"
            echo -ne " Pilih: "; IFS= read -rsn1 _SC; echo
            case "$_SC" in 1) search_by_name ;; 2) search_by_content ;; esac
            continue ;;
        "[BOOKMARKS]") bookmarks_menu; continue ;;
        "[PASTE]")     cb_paste; continue ;;
        "[HELP]")      show_help; continue ;;
    esac

    if [ -z "$ITEM" ]; then
        msg_err "Gagal baca nama item"; sleep 1; continue
    fi
    if [ ! -e "$FULL" ] && [ ! -L "$FULL" ]; then
        msg_err "Tidak ditemukan: $ITEM"
        msg_info "Cek: $FULL"
        sleep 2; continue
    fi

    if [ -d "$FULL" ]; then
        if [ "$KEY" = "alt-enter" ]; then
            folder_action "$FULL"
        else
            CURRENT_DIR="$FULL"
            folder_transition
        fi
        continue
    fi

    file_action "$FULL"
done