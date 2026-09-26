#!/bin/sh
# install.sh - installs wcp and wps (Wayland clipboard copy/paste tools)
# Works both from a cloned repo (uses local wcp.sh/wps.sh) and via
# `curl -fsSL .../install.sh | sh` (downloads the scripts on the fly).

set -eu

REPO_RAW_BASE="https://raw.githubusercontent.com/kiammota/wcp/main"

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

info() {
    printf '%s\n' "$*" >&2
}

# Locate a script: prefer a local copy sitting next to this installer,
# fall back to downloading it from the repo (curl-pipe install case).
fetch_script() {
    name="$1"       # e.g. wcp.sh
    dest="$2"       # temp path to write to

    script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) || script_dir=""

    if [ -n "$script_dir" ] && [ -f "$script_dir/$name" ]; then
        cp -- "$script_dir/$name" "$dest"
        return
    fi

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$REPO_RAW_BASE/$name" -o "$dest" || die "failed to download $name"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$REPO_RAW_BASE/$name" -O "$dest" || die "failed to download $name"
    else
        die "cannot locate $name locally and neither curl nor wget is available."
    fi
}

# ---- checks ----

[ "$(uname -s)" = "Linux" ] || die "wcp/wps require Linux."

if ! command -v wl-copy >/dev/null 2>&1 || ! command -v wl-paste >/dev/null 2>&1; then
    info "Warning: 'wl-clipboard' does not seem to be installed."
    info "wcp and wps will not work until you install it (e.g. apt install wl-clipboard)."
fi

# ---- choose install location ----

info "Where do you want to install wcp and wps?"
info "  1) Local  (~/.local/bin)"
info "  2) Global (/usr/local/bin, requires sudo)"
printf 'Choose [1/2]: ' >&2
read -r choice

case "$choice" in
    1)
        target_dir="$HOME/.local/bin"
        use_sudo=""
        ;;
    2)
        target_dir="/usr/local/bin"
        if [ "$(id -u)" -ne 0 ]; then
            command -v sudo >/dev/null 2>&1 || die "sudo not found; re-run as root for a global install."
            use_sudo="sudo"
        else
            use_sudo=""
        fi
        ;;
    *)
        die "invalid choice: $choice"
        ;;
esac

mkdir -p -- "$target_dir" 2>/dev/null || $use_sudo mkdir -p -- "$target_dir"

# ---- install both tools ----

tmp_dir=$(mktemp -d) || die "cannot create temp directory"
trap 'rm -rf "$tmp_dir"' EXIT

for name in wcp wps; do
    fetch_script "$name.sh" "$tmp_dir/$name"
    chmod +x "$tmp_dir/$name"
    $use_sudo cp -- "$tmp_dir/$name" "$target_dir/$name" || die "failed to install $name"
    info "Installed $name -> $target_dir/$name"
done

# ---- PATH check ----

case ":$PATH:" in
    *":$target_dir:"*) ;;
    *)
        info ""
        info "Note: $target_dir is not in your PATH."
        info "Add this to your shell rc file:"
        info "  export PATH=\"$target_dir:\$PATH\""
        ;;
esac

info ""
info "Done. Try: wcp file.txt   /   wps"
