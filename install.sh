#!/bin/sh
# wcp - copy file(s) as file:// URIs to Wayland clipboard (text/uri-list)
# Optimized for pasting into browsers / file upload fields.
# Aimed at POSIX sh (with common Linux utilities).

set -eu

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<EOF
Usage: ${0##*/} <file1> [file2 ...]
       ${0##*/} < file          (or pipe content)

Copy files to the Wayland clipboard as file:// URIs (text/uri-list).
Compatible with browsers, file managers and most Wayland applications.

When used with a pipe/stdin, the content is copied as plain text.

Examples:
  wcp foto.jpg video.mp4
  wcp "arquivo com espaço.mp3"
  ls *.pdf | xargs wcp
  git diff | wcp
  cat README.md | wcp

Options:
  -h, --help    Show this help message
EOF
    exit 0
}

# Get absolute path (POSIX-friendly)
# Prefers realpath when available, falls back to portable method
abs_path() {
    file="$1"

    if command -v realpath >/dev/null 2>&1; then
        realpath -- "$file"
        return
    fi

    # Portable fallback (does not fully resolve all symlink levels)
    case "$file" in
        /*) printf '%s\n' "$file" ;;
        *)
            # Make absolute relative to current directory
            dir=$(CDPATH= cd -- "$(dirname -- "$file")" && pwd) || die "cannot resolve directory of: $file"
            base=$(basename -- "$file")
            printf '%s/%s\n' "$dir" "$base"
            ;;
    esac
}

# Convert absolute path → properly percent-encoded file:// URI
path_to_uri() {
    path="$1"
    if command -v python3 >/dev/null 2>&1; then
        python3 -c '
import sys, pathlib
p = pathlib.Path(sys.argv[1]).resolve()
print(p.as_uri())
' "$path"
    else
        # Fallback without percent-encoding (works for simple ASCII paths)
        printf 'file://%s\n' "$path"
    fi
}

# ---- main ----

# Piped / non-TTY input → forward to wl-copy (POSIX way to detect pipe)
if [ ! -t 0 ]; then
    exec wl-copy
fi

# Help
case "${1:-}" in
    -h|--help)
        usage
        ;;
esac

[ "$#" -ge 1 ] || usage

# Platform checks
[ "$(uname -s)" = "Linux" ] || die "wcp requires Linux."
[ -n "${WAYLAND_DISPLAY:-}" ] || die "Wayland environment not detected (WAYLAND_DISPLAY is empty)."
command -v wl-copy >/dev/null 2>&1 || {
    die "wl-copy not found. Install the 'wl-clipboard' package."
}

# Build the uri-list
uri_list=""
count=0

for file in "$@"; do
    [ -e "$file" ] || die "file does not exist: $file"

    abs=$(abs_path "$file") || die "cannot resolve path: $file"
    uri=$(path_to_uri "$abs")

    if [ -z "$uri_list" ]; then
        uri_list="$uri"
    else
        # RFC 2483 recommends \r\n
        uri_list="${uri_list}$(printf '\r\n')${uri}"
    fi
    count=$((count + 1))
done

printf '%s' "$uri_list" | wl-copy -t text/uri-list

printf '%d file(s) copied to clipboard as text/uri-list\n' "$count" >&2
