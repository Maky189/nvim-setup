#!/usr/bin/env bash
# Installs Neovim + this LazyVim config on any Linux distribution.
# Usage:  ./install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_SRC="$SCRIPT_DIR/nvim"
NVIM_DST="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

c_info()  { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
c_ok()    { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
c_warn()  { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
c_err()   { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; }

# ---------- detect package manager ----------
detect_pm() {
    if   command -v apt-get >/dev/null 2>&1; then echo "apt"
    elif command -v dnf     >/dev/null 2>&1; then echo "dnf"
    elif command -v pacman  >/dev/null 2>&1; then echo "pacman"
    elif command -v zypper  >/dev/null 2>&1; then echo "zypper"
    elif command -v apk     >/dev/null 2>&1; then echo "apk"
    else echo "unknown"
    fi
}

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi
fi

PM="$(detect_pm)"
c_info "Detected package manager: $PM"

# ---------- install dependencies ----------
install_deps() {
    # neovim, git, curl, unzip, build tools, ripgrep, fd, node (for LSPs), python, lua/luarocks (avante)
    case "$PM" in
        apt)
            $SUDO apt-get update -y
            $SUDO apt-get install -y neovim git curl wget unzip tar xz-utils \
                build-essential ripgrep fd-find python3 python3-pip \
                nodejs npm lua5.1 luarocks xclip xsel
            # fd is "fdfind" on Debian/Ubuntu — add symlink for fd
            if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
                mkdir -p "$HOME/.local/bin"
                ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
            fi
            ;;
        dnf)
            $SUDO dnf install -y neovim git curl wget unzip tar xz \
                @development-tools ripgrep fd-find python3 python3-pip \
                nodejs npm lua luarocks xclip xsel
            ;;
        pacman)
            $SUDO pacman -Sy --noconfirm --needed neovim git curl wget unzip tar xz \
                base-devel ripgrep fd python python-pip \
                nodejs npm lua luarocks xclip xsel
            ;;
        zypper)
            $SUDO zypper --non-interactive install neovim git curl wget unzip tar xz \
                -t pattern devel_basis ripgrep fd python3 python3-pip \
                nodejs npm lua luarocks xclip xsel
            ;;
        apk)
            $SUDO apk add --no-cache neovim git curl wget unzip tar xz \
                build-base ripgrep fd python3 py3-pip \
                nodejs npm lua5.1 luarocks xclip xsel
            ;;
        *)
            c_warn "Unknown package manager — install these manually: neovim git curl unzip build tools ripgrep fd nodejs npm python3 lua luarocks"
            ;;
    esac
}

c_info "Installing dependencies..."
install_deps
c_ok "Dependencies installed."

# ---------- check neovim version ----------
if command -v nvim >/dev/null 2>&1; then
    NVIM_VER="$(nvim --version | head -n1 | awk '{print $2}')"
    c_info "Neovim version: $NVIM_VER"
    # LazyVim requires >= 0.9 (0.10 recommended). Warn if older.
    MAJ="$(echo "$NVIM_VER" | sed 's/^v//' | cut -d. -f1)"
    MIN="$(echo "$NVIM_VER" | sed 's/^v//' | cut -d. -f2)"
    if [ "$MAJ" -eq 0 ] && [ "$MIN" -lt 9 ]; then
        c_warn "Neovim < 0.9 — LazyVim requires 0.9+. Consider installing the AppImage from https://github.com/neovim/neovim/releases"
    fi
else
    c_err "Neovim not installed and the package manager step did not provide it."
    exit 1
fi

# ---------- back up existing config ----------
backup() {
    local p="$1"
    if [ -e "$p" ] || [ -L "$p" ]; then
        local b="${p}.bak.$(date +%Y%m%d%H%M%S)"
        c_warn "Backing up $p -> $b"
        mv "$p" "$b"
    fi
}

c_info "Backing up any existing Neovim config / data / state..."
backup "$NVIM_DST"
backup "${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
backup "${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
backup "${XDG_CACHE_HOME:-$HOME/.cache}/nvim"

# ---------- deploy config ----------
c_info "Copying config to $NVIM_DST"
mkdir -p "$(dirname "$NVIM_DST")"
cp -r "$NVIM_SRC" "$NVIM_DST"
c_ok "Config copied."

# ---------- headless sync of plugins ----------
c_info "Running headless LazyVim sync (this may take a few minutes)..."
nvim --headless "+Lazy! restore" +qa || c_warn "Lazy restore had non-zero exit — continuing."
nvim --headless "+Lazy! sync"    +qa || c_warn "Lazy sync had non-zero exit — continuing."

# Mason tools (LSP/DAP/formatters) — best-effort
nvim --headless "+MasonUpdate" +qa 2>/dev/null || true

c_ok "Done! Launch with:  nvim"
