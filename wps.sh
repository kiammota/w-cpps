#!/bin/sh
# wps - paste file(s) or text from the Wayland clipboard
# Counterpart to wcp: reads text/uri-list and copies the referenced
# files to a destination, or falls back to plain text on stdout.
# Aimed at POSIX sh (with common Linux utilities).

set -eu

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<EOF
Usage: ${0##*/} [dir]
       ${0##*/} -l | --list

Paste files or text from the Wayland clipboard.

With no arguments:
  - If the clipboard holds file URIs (text/uri-list), the referenced
    files are copied into the current directory.
  - Otherwise, plain text content is printed to stdout.

  ${0##*/} DIR      Copy clipboard files into DIR instead of cwd.
  ${0##*/} -l        List the clipboard's file paths without copying.

Options:
  -h, --help    Show this help message

Examples:
  wps                  # paste files into cwd, or print text
  wps ~/Downloads       # paste files into ~/Downloads
  wps -l                # list what's in the clipboard
  wps > out.txt         # save clipboard text to a file
EOF
    exit 0
}

# Decode a percent-encoded file:// URI into a filesystem path
uri_to_path() {
    uri="$1"
    if command -v python3 >/dev/null 2>&1; then
        python3 -c '
import sys, urllib.parse
uri = sys.argv[1]
if uri.startswith("file://"):
    uri = uri[len("file://"):]
print(urllib.parse.unquote(uri))
' "$uri"
    else
        # Crude fallback: strips scheme, no percent-decoding
        printf '%s\n' "${uri#file://}"
    fi
}

# ---- arg parsing ----

list_only=0
dest="."

case "${1:-}" in
    -h|--help) usage ;;
    -l|--list) list_only=1 ;;
    "") ;;
    *) dest="$1" ;;
esac

# ---- checks ----

command -v wl-paste >/dev/null 2>&1 || die "wl-paste not found. Install the 'wl-clipboard' package."
[ -n "${WAYLAND_DISPLAY:-}" ] || die "Wayland environment not detected (WAYLAND_DISPLAY is empty)."

types=$(wl-paste --list-types 2>/dev/null || true)

# ---- main ----

if printf '%s\n' "$types" | grep -qx 'text/uri-list'; then
    [ "$list_only" -eq 1 ] || [ -d "$dest" ] || die "destination is not a directory: $dest"

    tmp=$(mktemp) || die "cannot create temp file"
    trap 'rm -f "$tmp"' EXIT

    wl-paste --type text/uri-list | tr -d '\r' > "$tmp"

    count=0
    # Redirecting from a file (not a pipe) keeps the loop in the
    # current shell, so $count survives after it ends.
    while IFS= read -r uri; do
        [ -n "$uri" ] || continue
        path=$(uri_to_path "$uri")

        if [ "$list_only" -eq 1 ]; then
            printf '%s\n' "$path"
            continue
        fi

        [ -e "$path" ] || { printf 'Warning: source not found: %s\n' "$path" >&2; continue; }
        cp -r -- "$path" "$dest/" && count=$((count + 1))
    done < "$tmp"

    [ "$list_only" -eq 1 ] || printf '%d file(s) pasted into %s\n' "$count" "$dest" >&2
else
    [ "$list_only" -eq 0 ] || die "no file list in clipboard"
    wl-paste --no-newline 2>/dev/null || wl-paste
fi
